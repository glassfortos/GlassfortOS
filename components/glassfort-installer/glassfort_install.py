#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Glassfort installer backend.

Runs as root on the live medium. The installer UI (glassfort-installer)
collects a *plan* (language, keyboard, disk, user, look) and pipes it as
JSON into ``glassfort-install install``. This module

1. validates the plan,
2. turns it into an archinstall configuration (the layout from
   docs/02-system.md: 4 GiB ESP at /boot, LUKS2 -> Btrfs with Glassfort's
   subvolumes, Limine, linux + linux-lts, glassfort-desktop from the
   [glassfort] repository on the medium) and runs archinstall with it,
3. finishes the installed system: [glassfort] repository, the live
   session's Wi-Fi connections, light/dark look, no copy-on-write for the VM
   subvolume, and a LUKS recovery key that the UI shows once.

Progress goes to stdout as JSON lines (``{"event": ...}``) so the UI can
show it; archinstall's own output goes to the log file. We do not write
partitioning logic ourselves (D-12): archinstall does all of it.
"""

from __future__ import annotations

import argparse
import contextlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
from dataclasses import dataclass
from pathlib import Path

# --- Constants -------------------------------------------------------------------

ESP_MIB = 4096  # docs/02-system.md: snapshot entries need kernels on the ESP
MIN_DISK_GIB = 40
MOUNT_OPTIONS = ["compress=zstd:1", "noatime"]
SUBVOLUMES = [  # docs/02-system.md
    ("@", "/"),
    ("@home", "/home"),
    ("@var_log", "/var/log"),
    ("@var_cache_pacman_pkg", "/var/cache/pacman/pkg"),
    ("@snapshots", "/.snapshots"),
    ("@vm", "/var/lib/glassfort/vm"),
]
KERNELS = ["linux", "linux-lts"]
PACKAGES = ["glassfort-desktop", "linux-headers", "linux-lts-headers"]
# The [glassfort] repository baked into the medium (scripts/build-iso). The
# same path is the server in glassfort-mirrorlist, so the installed system
# gets a copy at the same place until the repository is hosted (D-33).
REPO_DIR = Path("/srv/glassfort/repo/x86_64")
LOOKS = {
    "auto": None,
    "light": "org.glassfort.desktop",
    "dark": "org.glassfort.dark.desktop",
}
TARGET = Path("/mnt/glassfort-target")
LOG = Path("/var/log/glassfort-install.log")

USERNAME_RE = re.compile(r"^[a-z_][a-z0-9_-]{0,31}$")
HOSTNAME_RE = re.compile(r"^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$")
LOCALE_RE = re.compile(r"^[a-z]{2,3}_[A-Z]{2}(@[a-z]+)?$")
KEYBOARD_RE = re.compile(r"^[a-z]{2,8}[0-9]?(_[A-Z]{2})?(-[a-z0-9]+)*$")
DISK_RE = re.compile(r"^/dev/(sd[a-z]+|vd[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+)$")


class PlanError(ValueError):
    """The plan from the UI is invalid."""


# --- Plan ------------------------------------------------------------------------


@dataclass(frozen=True)
class Plan:
    locale: str  # e.g. de_DE (UTF-8 is implied)
    keyboard: str  # console keymap, e.g. de-latin1 or us
    timezone: str  # e.g. Europe/Berlin
    disk: str  # e.g. /dev/nvme0n1 (erased completely)
    username: str
    full_name: str
    password: str
    encrypt: bool = True
    disk_passphrase: str | None = None  # None: same as the user password
    hostname: str = "glassfort"
    look: str = "auto"

    @property
    def passphrase(self) -> str:
        return self.disk_passphrase or self.password


def parse_plan(data: dict, zoneinfo: Path = Path("/usr/share/zoneinfo")) -> Plan:
    """Validate the UI's plan. Raises PlanError with a short reason."""
    known = set(Plan.__dataclass_fields__)
    unknown = set(data) - known
    if unknown:
        raise PlanError(f"unknown fields: {', '.join(sorted(unknown))}")
    try:
        plan = Plan(**data)
    except TypeError as err:
        raise PlanError(str(err)) from None

    if not LOCALE_RE.match(plan.locale):
        raise PlanError("invalid locale")
    if not KEYBOARD_RE.match(plan.keyboard):
        raise PlanError("invalid keyboard layout")
    tz = plan.timezone
    if ".." in tz or tz.startswith("/") or not (zoneinfo / tz).is_file():
        raise PlanError("unknown time zone")
    if not DISK_RE.match(plan.disk):
        raise PlanError("invalid disk")
    if not USERNAME_RE.match(plan.username) or plan.username == "root":
        raise PlanError("invalid user name")
    if any(c in plan.full_name for c in ":\n\r"):
        raise PlanError("invalid full name")
    if not plan.password:
        raise PlanError("empty password")
    if plan.disk_passphrase is not None and len(plan.disk_passphrase) < 8:
        raise PlanError("disk passphrase too short")
    if not HOSTNAME_RE.match(plan.hostname):
        raise PlanError("invalid host name")
    if plan.look not in LOOKS:
        raise PlanError("invalid look")
    return plan


# --- Disks -----------------------------------------------------------------------


def live_medium_disks() -> set[str]:
    """Disks holding the live medium (never offered as a target)."""
    out = set()
    for mnt in ("/run/archiso/bootmnt", "/run/archiso/img_dev"):
        src = subprocess.run(
            ["findmnt", "-no", "SOURCE", mnt], check=False, capture_output=True, text=True
        ).stdout.strip()
        if src:
            parent = subprocess.run(
                ["lsblk", "-no", "PKNAME", src], check=False, capture_output=True, text=True
            ).stdout.strip()
            out.add(f"/dev/{parent}" if parent else src)
    return out


def list_disks(lsblk_json: str | None = None, exclude: set[str] | None = None) -> list[dict]:
    """Disks the user may install to: whole, writable, big enough."""
    if lsblk_json is None:
        lsblk_json = subprocess.run(
            ["lsblk", "-J", "-b", "-d", "-o", "PATH,SIZE,MODEL,TYPE,TRAN,RM,RO,LOG-SEC"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout
    if exclude is None:
        exclude = live_medium_disks()
    disks = []
    for dev in json.loads(lsblk_json).get("blockdevices", []):
        path = dev.get("path") or ""
        if dev.get("type") != "disk" or dev.get("ro") or not DISK_RE.match(path):
            continue
        if path in exclude:
            continue
        size = int(dev.get("size") or 0)
        disks.append(
            {
                "path": path,
                "size": size,
                "model": (dev.get("model") or "").strip(),
                "transport": dev.get("tran") or "",
                "removable": bool(dev.get("rm")),
                "sector_size": int(dev.get("log-sec") or 512),
                "big_enough": size >= MIN_DISK_GIB * 1024**3,
            }
        )
    return disks


# --- archinstall configuration ---------------------------------------------------


def _size(value: int, unit: str, sector: int) -> dict:
    return {"sector_size": {"unit": "B", "value": sector}, "unit": unit, "value": value}


def partition_path(disk: str, number: int) -> str:
    """/dev/sda + 2 -> /dev/sda2, /dev/nvme0n1 + 2 -> /dev/nvme0n1p2."""
    return f"{disk}p{number}" if disk[-1].isdigit() else f"{disk}{number}"


def archinstall_config(plan: Plan, disk: dict, repo_url: str) -> tuple[dict, dict]:
    """Return archinstall's (config, credentials) for the plan."""
    sector = disk["sector_size"]
    total_mib = disk["size"] // (1024 * 1024)
    # 1 MiB alignment at the start, 1 MiB left for the backup GPT at the end.
    system_mib = total_mib - 1 - ESP_MIB - 1
    if system_mib < MIN_DISK_GIB * 1024 - ESP_MIB - 2:
        raise PlanError("disk too small")

    esp_id, sys_id = str(uuid.uuid4()), str(uuid.uuid4())
    partitions = [
        {
            "obj_id": esp_id,
            "status": "create",
            "type": "primary",
            "start": _size(1, "MiB", sector),
            "size": _size(ESP_MIB, "MiB", sector),
            "fs_type": "fat32",
            "mountpoint": "/boot",
            "mount_options": [],
            "flags": ["boot", "esp"],
            "btrfs": [],
            "dev_path": None,
        },
        {
            "obj_id": sys_id,
            "status": "create",
            "type": "primary",
            "start": _size(1 + ESP_MIB, "MiB", sector),
            "size": _size(system_mib, "MiB", sector),
            "fs_type": "btrfs",
            "mountpoint": None,
            "mount_options": MOUNT_OPTIONS,
            "flags": [],
            "btrfs": [{"name": n, "mountpoint": m} for n, m in SUBVOLUMES],
            "dev_path": None,
        },
    ]
    disk_config: dict = {
        "config_type": "default_layout",
        "device_modifications": [{"device": plan.disk, "wipe": True, "partitions": partitions}],
        # Snapper is set up by glassfort-setup (glassfort-settings), not here.
        "btrfs_options": {"snapshot_config": None},
    }
    if plan.encrypt:
        disk_config["disk_encryption"] = {
            "encryption_type": "luks",
            "partitions": [sys_id],
            "lvm_volumes": [],
        }

    config = {
        "archinstall-language": "English",
        "audio_config": {"audio": "pipewire"},
        # Limine with the removable path (EFI/BOOT/BOOTX64.EFI), as
        # glassfort-settings expects (docs/02-system.md, D-08).
        "bootloader_config": {"bootloader": "Limine", "uki": False, "removable": True},
        "disk_config": disk_config,
        "hostname": plan.hostname,
        "kernels": KERNELS,
        "locale_config": {
            "kb_layout": plan.keyboard,
            "sys_enc": "UTF-8",
            "sys_lang": f"{plan.locale}.UTF-8",
        },
        "mirror_config": {
            "custom_repositories": [
                {
                    "name": "glassfort",
                    "url": repo_url,
                    # Unsigned until the real key exists (D-26); the files
                    # come from the medium the user booted.
                    "sign_check": "Optional",
                    "sign_option": "TrustAll",
                }
            ],
        },
        "network_config": {"type": "nm"},
        "ntp": True,
        "packages": PACKAGES,
        "profile_config": None,
        # zram comes from glassfort-settings.
        "swap": {"enabled": False},
        "timezone": plan.timezone,
    }
    creds = {
        "users": [{"username": plan.username, "!password": plan.password, "sudo": True}],
    }
    if plan.encrypt:
        creds["encryption_password"] = plan.passphrase
    return config, creds


# --- Finishing the installed system ----------------------------------------------


def target_pacman_conf(text: str) -> str:
    """Replace archinstall's [glassfort] section (appended at the end, with the
    medium's file:// URL) by the permanent one above [core]."""
    text = re.sub(r"\n*\[glassfort\]\n(?:(?!\[)[^\n]*\n?)*", "\n\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text).rstrip() + "\n"
    section = "[glassfort]\nInclude = /etc/pacman.d/glassfort-mirrorlist\n\n"
    return re.sub(r"^\[core\]", section + "[core]", text, count=1, flags=re.MULTILINE)


def look_kdeglobals(look: str) -> str | None:
    package = LOOKS[look]
    if package is None:
        return None  # the system default switches by time of day
    return f"[KDE]\nLookAndFeelPackage={package}\nAutomaticLookAndFeel=false\n"


class Emitter:
    """Writes one JSON object per line to stdout (read by the UI)."""

    def __call__(self, event: str, **data) -> None:
        sys.stdout.write(json.dumps({"event": event, **data}) + "\n")
        sys.stdout.flush()


# Lines of archinstall's output that mark a stage (shown as progress).
STAGES = [
    ("Wiping partitions", "disk", 5),
    ("Creating partitions", "disk", 8),
    ("Starting installation", "base", 12),
    ("Installing packages", "base", 15),
    ("Installing Limine", "boot", 60),
    ("Installing additional packages", "desktop", 65),
    ("Setting timezone", "settings", 92),
    ("genfstab", "settings", 94),
]


def run_archinstall(config: dict, creds: dict, emit: Emitter, log) -> None:
    with tempfile.TemporaryDirectory(prefix="glassfort-install-") as tmp:
        os.chmod(tmp, 0o700)
        cfg, crd = Path(tmp, "config.json"), Path(tmp, "creds.json")
        cfg.write_text(json.dumps(config))
        fd = os.open(crd, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "w") as f:
            json.dump(creds, f)
        proc = subprocess.Popen(
            [
                "archinstall",
                "--config",
                str(cfg),
                "--creds",
                str(crd),
                "--mountpoint",
                str(TARGET),
                "--silent",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            errors="replace",
        )
        for line in proc.stdout or ():
            log.write(line)
            for marker, stage, percent in STAGES:
                if marker in line:
                    emit("progress", stage=stage, percent=percent)
        if proc.wait() != 0:
            raise RuntimeError(f"archinstall failed (exit {proc.returncode})")


@contextlib.contextmanager
def mounted_target(plan: Plan):
    """Open and mount the installed system again (archinstall unmounts it)."""
    system = partition_path(plan.disk, 2)
    mapper = None
    if plan.encrypt:
        mapper = "glassfort-finish"
        subprocess.run(
            ["cryptsetup", "open", "--key-file=-", system, mapper],
            input=plan.passphrase.encode(),
            check=True,
        )
        system = f"/dev/mapper/{mapper}"
    TARGET.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run(["mount", "-o", "subvol=@", system, str(TARGET)], check=True)
        for name, mnt in SUBVOLUMES[1:]:
            subprocess.run(
                ["mount", "-o", f"subvol={name}", system, str(TARGET) + mnt],
                check=True,
            )
        yield TARGET
    finally:
        subprocess.run(["umount", "-R", str(TARGET)], check=False)
        if mapper:
            subprocess.run(["cryptsetup", "close", mapper], check=False)


def finish(plan: Plan, emit: Emitter, root: Path) -> None:
    """Glassfort steps on the mounted, installed system."""
    conf = root / "etc/pacman.conf"
    conf.write_text(target_pacman_conf(conf.read_text()))
    # Local copy of the repository until it is hosted (D-33).
    dest = root / str(REPO_DIR).lstrip("/")
    shutil.copytree(REPO_DIR, dest, dirs_exist_ok=True)

    # Wi-Fi the user connected to in the installer.
    nm = Path("/etc/NetworkManager/system-connections")
    if nm.is_dir():
        nm_dest = root / "etc/NetworkManager/system-connections"
        nm_dest.mkdir(parents=True, exist_ok=True)
        for f in nm.glob("*.nmconnection"):
            shutil.copy2(f, nm_dest / f.name)
            os.chmod(nm_dest / f.name, 0o600)

    # Windows VM images: no copy-on-write (docs/02-system.md).
    subprocess.run(["chattr", "+C", str(root / "var/lib/glassfort/vm")], check=False)

    if text := look_kdeglobals(plan.look):
        home = root / "home" / plan.username
        cfg = home / ".config"
        cfg.mkdir(parents=True, exist_ok=True)
        (cfg / "kdeglobals").write_text(text)
        st = home.stat()
        for p in (cfg, cfg / "kdeglobals"):
            os.chown(p, st.st_uid, st.st_gid)
    emit("progress", stage="finish", percent=97)


def enroll_recovery_key(plan: Plan) -> str:
    """Add a LUKS recovery key (shown once by the UI, docs/02-system.md)."""
    with tempfile.NamedTemporaryFile("w", prefix="glassfort-key-") as key:
        os.chmod(key.name, 0o600)
        key.write(plan.passphrase)
        key.flush()
        out = subprocess.run(
            [
                "systemd-cryptenroll",
                f"--unlock-key-file={key.name}",
                "--recovery-key",
                partition_path(plan.disk, 2),
            ],
            capture_output=True,
            text=True,
            check=True,
        ).stdout
    match = re.search(r"([cbdefghijklnrtuv]{8}(?:-[cbdefghijklnrtuv]{8}){7})", out)
    if not match:
        raise RuntimeError("no recovery key in systemd-cryptenroll's output")
    return match.group(1)


def install(plan: Plan, emit: Emitter) -> None:
    disks = {d["path"]: d for d in list_disks()}
    disk = disks.get(plan.disk)
    if disk is None or not disk["big_enough"]:
        raise PlanError("disk not available")
    if not (REPO_DIR / "glassfort.db").exists():
        raise RuntimeError(f"no [glassfort] repository at {REPO_DIR}")
    config, creds = archinstall_config(plan, disk, f"file://{REPO_DIR}")
    emit("progress", stage="start", percent=1)
    with LOG.open("a") as log:
        run_archinstall(config, creds, emit, log)
    with mounted_target(plan) as root:
        finish(plan, emit, root)
    key = enroll_recovery_key(plan) if plan.encrypt else None
    emit("done", recovery_key=key)


# --- CLI -------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="glassfort-install", description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("disks", help="list target disks as JSON")
    p_cfg = sub.add_parser("config", help="print the archinstall config for a plan (stdin)")
    p_cfg.add_argument("--disk-size", type=int, required=True, help="bytes")
    sub.add_parser("install", help="install from a plan (JSON on stdin)")
    args = ap.parse_args(argv)
    emit = Emitter()

    if args.cmd == "disks":
        print(json.dumps(list_disks()))
        return 0
    try:
        plan = parse_plan(json.load(sys.stdin))
        if args.cmd == "config":
            disk = {"size": args.disk_size, "sector_size": 512}
            config, _ = archinstall_config(plan, disk, f"file://{REPO_DIR}")
            print(json.dumps(config, indent=2))
            return 0
        if os.geteuid() != 0:
            raise PlanError("must run as root")
        install(plan, emit)
        return 0
    except (PlanError, json.JSONDecodeError) as err:
        emit("error", reason="plan", message=str(err))
        return 2
    except (RuntimeError, OSError, subprocess.CalledProcessError) as err:
        emit("error", reason="install", message=str(err), log=str(LOG))
        return 1


if __name__ == "__main__":
    sys.exit(main())
