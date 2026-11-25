# SPDX-License-Identifier: GPL-3.0-or-later
"""Tests for the installer backend (no root, no disks touched)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import glassfort_install as gi

GIB = 1024**3


@pytest.fixture
def zoneinfo(tmp_path: Path) -> Path:
    (tmp_path / "Europe").mkdir()
    (tmp_path / "Europe" / "Berlin").write_text("TZif")
    (tmp_path / "UTC").write_text("TZif")
    return tmp_path


def plan_data(**over) -> dict:
    data = {
        "locale": "de_DE",
        "keyboard": "de-latin1",
        "timezone": "Europe/Berlin",
        "disk": "/dev/nvme0n1",
        "username": "jan",
        "full_name": "Jan",
        "password": "correct horse",
    }
    data.update(over)
    return data


def test_valid_plan(zoneinfo: Path) -> None:
    plan = gi.parse_plan(plan_data(), zoneinfo)
    assert plan.encrypt is True
    assert plan.passphrase == "correct horse"
    assert plan.look == "auto"


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("locale", "de_DE.UTF-8; rm -rf /"),
        ("keyboard", "de latin1"),
        ("timezone", "../../etc/passwd"),
        ("timezone", "Mars/Olympus"),
        ("disk", "/dev/sda1"),
        ("disk", "/dev/../sda"),
        ("username", "root"),
        ("username", "Jan"),
        ("username", "-x"),
        ("full_name", "a:b"),
        ("password", ""),
        ("disk_passphrase", "short"),
        ("hostname", "my_host"),
        ("look", "neon"),
    ],
)
def test_invalid_plan(zoneinfo: Path, field: str, value: str) -> None:
    with pytest.raises(gi.PlanError):
        gi.parse_plan(plan_data(**{field: value}), zoneinfo)


def test_unknown_field(zoneinfo: Path) -> None:
    with pytest.raises(gi.PlanError, match="unknown"):
        gi.parse_plan(plan_data(shell="/bin/sh"), zoneinfo)


def test_separate_disk_passphrase(zoneinfo: Path) -> None:
    plan = gi.parse_plan(plan_data(disk_passphrase="long enough"), zoneinfo)
    assert plan.passphrase == "long enough"


def test_partition_path() -> None:
    assert gi.partition_path("/dev/sda", 2) == "/dev/sda2"
    assert gi.partition_path("/dev/vda", 1) == "/dev/vda1"
    assert gi.partition_path("/dev/nvme0n1", 2) == "/dev/nvme0n1p2"
    assert gi.partition_path("/dev/mmcblk0", 2) == "/dev/mmcblk0p2"


def test_list_disks_filters() -> None:
    lsblk = {
        "blockdevices": [
            {
                "path": "/dev/nvme0n1",
                "size": 512 * GIB,
                "model": "Fast SSD ",
                "type": "disk",
                "tran": "nvme",
                "rm": False,
                "ro": False,
                "log-sec": 512,
            },
            {
                "path": "/dev/sda",
                "size": 16 * GIB,
                "model": "Stick",
                "type": "disk",
                "tran": "usb",
                "rm": True,
                "ro": False,
                "log-sec": 512,
            },
            {
                "path": "/dev/sdb",
                "size": 64 * GIB,
                "model": "Boot",
                "type": "disk",
                "tran": "usb",
                "rm": True,
                "ro": False,
                "log-sec": 512,
            },
            {"path": "/dev/sr0", "size": 2 * GIB, "type": "rom", "ro": True},
            {"path": "/dev/loop0", "size": 2 * GIB, "type": "loop"},
            {"path": "/dev/zram0", "size": 4 * GIB, "type": "disk"},
        ]
    }
    disks = gi.list_disks(json.dumps(lsblk), exclude={"/dev/sdb"})
    assert [d["path"] for d in disks] == ["/dev/nvme0n1", "/dev/sda"]
    assert disks[0]["model"] == "Fast SSD"
    assert disks[0]["big_enough"] and not disks[1]["big_enough"]


def config_for(zoneinfo: Path, **over) -> tuple[dict, dict]:
    plan = gi.parse_plan(plan_data(**over), zoneinfo)
    disk = {"size": 100 * GIB, "sector_size": 512}
    return gi.archinstall_config(plan, disk, "file:///srv/glassfort/repo/x86_64")


def test_config_layout(zoneinfo: Path) -> None:
    config, creds = config_for(zoneinfo)
    disk = config["disk_config"]
    (mod,) = disk["device_modifications"]
    assert mod["device"] == "/dev/nvme0n1" and mod["wipe"] is True
    esp, system = mod["partitions"]
    assert esp["size"]["value"] == 4096 and esp["mountpoint"] == "/boot"
    assert esp["fs_type"] == "fat32" and "esp" in esp["flags"]
    assert system["start"]["value"] == 4097
    assert system["start"]["value"] + system["size"]["value"] < 100 * 1024
    assert system["fs_type"] == "btrfs"
    assert {(v["name"], v["mountpoint"]) for v in system["btrfs"]} == set(gi.SUBVOLUMES)
    assert system["mount_options"] == ["compress=zstd:1", "noatime"]
    assert disk["disk_encryption"]["partitions"] == [system["obj_id"]]
    assert disk["btrfs_options"] == {"snapshot_config": None}

    assert config["bootloader_config"] == {"bootloader": "Limine", "uki": False, "removable": True}
    assert config["kernels"] == ["linux", "linux-lts"]
    assert "glassfort-desktop" in config["packages"]
    assert config["swap"] == {"enabled": False}
    assert config["locale_config"]["sys_lang"] == "de_DE.UTF-8"
    (repo,) = config["mirror_config"]["custom_repositories"]
    assert repo["name"] == "glassfort" and repo["url"].startswith("file:///")

    # Secrets only in the credentials, never in the config.
    dumped = json.dumps(config)
    assert "correct horse" not in dumped
    assert creds["users"][0] == {"username": "jan", "!password": "correct horse", "sudo": True}
    assert creds["encryption_password"] == "correct horse"


def test_config_without_encryption(zoneinfo: Path) -> None:
    config, creds = config_for(zoneinfo, encrypt=False)
    assert "disk_encryption" not in config["disk_config"]
    assert "encryption_password" not in creds


def test_config_disk_too_small(zoneinfo: Path) -> None:
    plan = gi.parse_plan(plan_data(), zoneinfo)
    with pytest.raises(gi.PlanError, match="too small"):
        gi.archinstall_config(plan, {"size": 30 * GIB, "sector_size": 512}, "file:///x")


PACMAN_CONF = """[options]
HoldPkg = pacman glibc

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist


[glassfort]
SigLevel = Optional TrustAll
Server = file:///srv/glassfort/repo/x86_64
"""


def test_target_pacman_conf() -> None:
    out = gi.target_pacman_conf(PACMAN_CONF)
    assert "file://" not in out and "TrustAll" not in out
    assert out.count("[glassfort]") == 1
    assert out.index("[glassfort]") < out.index("[core]")
    assert "[glassfort]\nInclude = /etc/pacman.d/glassfort-mirrorlist\n\n[core]" in out
    assert out.rstrip().endswith("Include = /etc/pacman.d/mirrorlist")
    # Idempotent.
    assert gi.target_pacman_conf(out) == out


def test_look() -> None:
    assert gi.look_kdeglobals("auto") is None
    assert "org.glassfort.dark.desktop" in gi.look_kdeglobals("dark")
    assert "AutomaticLookAndFeel=false" in gi.look_kdeglobals("light")


def test_cli_config(zoneinfo: Path, monkeypatch, capsys) -> None:
    import io

    monkeypatch.setattr(sys, "stdin", io.StringIO(json.dumps(plan_data(timezone="UTC"))))
    monkeypatch.setattr(gi, "parse_plan", lambda d: gi.Plan(**d))
    assert gi.main(["config", "--disk-size", str(64 * GIB)]) == 0
    out = json.loads(capsys.readouterr().out)
    assert out["hostname"] == "glassfort"


def test_cli_bad_plan(monkeypatch, capsys) -> None:
    import io

    monkeypatch.setattr(sys, "stdin", io.StringIO('{"locale": "x"}'))
    assert gi.main(["install"]) == 2
    event = json.loads(capsys.readouterr().out)
    assert event["event"] == "error" and event["reason"] == "plan"
