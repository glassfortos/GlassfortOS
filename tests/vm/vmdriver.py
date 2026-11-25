#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Drive one QEMU boot of the Phase 1 VM test.

Reads the serial console from a UNIX socket, writes it to a log, reacts to
"GFTEST" lines from the guest agent and talks to the QEMU monitor
(screenshots, key presses). Used by tests/vm/phase1; stdlib only.

Exit status: 0 when the expected final marker was seen, 1 on a "FAIL"
marker or timeout.
"""

from __future__ import annotations

import argparse
import re
import socket
import subprocess
import sys
import time
from pathlib import Path


class Monitor:
    """Minimal QEMU human monitor client over a UNIX socket."""

    def __init__(self, path: Path) -> None:
        self.path = path

    def cmd(self, line: str) -> str:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(str(self.path))
            s.settimeout(5)
            self._read_prompt(s)
            s.sendall(line.encode() + b"\n")
            return self._read_prompt(s)

    @staticmethod
    def _read_prompt(s: socket.socket) -> str:
        buf = b""
        while not buf.endswith(b"(qemu) "):
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
        return buf.decode(errors="replace")

    def screenshot(self, png: Path) -> None:
        ppm = png.with_suffix(".ppm")
        self.cmd(f"screendump {ppm}")
        time.sleep(1)
        subprocess.run(["magick", str(ppm), str(png)], check=False)
        ppm.unlink(missing_ok=True)

    def key(self, name: str) -> None:
        self.cmd(f"sendkey {name}")

    def brightness(self, tmp: Path) -> float:
        """Mean brightness of the screen (0 = black)."""
        ppm = tmp.with_suffix(".ppm")
        self.cmd(f"screendump {ppm}")
        time.sleep(0.3)
        out = subprocess.run(
            ["magick", str(ppm), "-format", "%[fx:mean]", "info:"],
            capture_output=True,
            text=True,
            check=False,
        ).stdout
        ppm.unlink(missing_ok=True)
        try:
            return float(out)
        except ValueError:
            return 0.0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--serial", type=Path, required=True)
    ap.add_argument("--monitor", type=Path, required=True)
    ap.add_argument("--log", type=Path, required=True)
    ap.add_argument(
        "--shots", type=Path, required=True, help="directory for screenshots"
    )
    ap.add_argument(
        "--until", required=True, help="GFTEST marker that ends this boot successfully"
    )
    ap.add_argument("--timeout", type=int, default=1800)
    ap.add_argument(
        "--snapshot-menu",
        action="store_true",
        help="after the broken update, boot its pre snapshot from the Limine menu",
    )
    args = ap.parse_args()

    mon = Monitor(args.monitor)
    for _ in range(100):
        if args.serial.exists():
            break
        time.sleep(0.1)
    ser = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    ser.connect(str(args.serial))
    ser.settimeout(1)

    deadline = time.monotonic() + args.timeout
    pending = ""
    shot_no = 0
    broken_seen = False
    splash_shot = False
    # The broken boot prints nothing on the serial console (no console=ttyS0,
    # quiet splash); the agent's silence after the reboot is the signal.
    broken_deadline = None
    boot_count = 0
    with args.log.open("a", encoding="utf-8", errors="replace") as log:

        def shot(name: str) -> None:
            nonlocal shot_no
            shot_no += 1
            png = args.shots / f"{shot_no:02d}-{name}.png"
            mon.screenshot(png)
            print(f"[driver] screenshot {png}", flush=True)

        def pick_snapshot() -> None:
            """Like a user, boot the snapshot taken before the broken update.

            The Limine menu (common/menu.c): Up/Down move and wrap around,
            Right/Enter only open or close a directory. Glassfort's entry is
            a directory with linux, linux-lts and "Snapshots"; "Snapshots"
            holds one directory per snapshot, newest first. The newest is
            the "post" snapshot of the broken update (broken as well), the
            second its "pre" snapshot. Keys are sent only once the menu is
            on screen (the serial console does not show it reliably).
            """
            for _ in range(240):
                if mon.brightness(args.shots / "probe.png") > 0.002:
                    break
                time.sleep(0.25)
            steps = [
                ("up", "stop the countdown, select the Arch Linux directory"),
                ("up", "wrap around to Snapshots"),
                ("right", "open Snapshots"),
                ("down", "newest snapshot (post, broken)"),
                ("down", "snapshot before the broken update (pre)"),
                ("right", "open it"),
                ("down", "its linux kernel"),
            ]
            print(
                "[driver] Limine menu: booting the snapshot taken before the broken update",
                flush=True,
            )
            for k, why in steps:
                mon.key(k)
                time.sleep(1)
                print(f"[driver]   {k}: {why}", flush=True)
                if k == "up" and why.startswith("wrap"):
                    shot("limine-menu")
            shot("limine-snapshot")
            mon.key("ret")

        while time.monotonic() < deadline:
            if (
                args.snapshot_menu
                and not broken_seen
                and broken_deadline
                and time.monotonic() > broken_deadline
            ):
                broken_seen = True
                print(
                    "[driver] no agent after the broken update; treating the boot as broken, resetting",
                    flush=True,
                )
                shot("broken-boot")
                mon.cmd("system_reset")
                pick_snapshot()
            try:
                data = ser.recv(65536)
            except TimeoutError:
                continue
            except OSError:
                break
            if not data:
                break
            text = data.decode(errors="replace")
            log.write(text)
            log.flush()
            pending += text
            lines = pending.split("\n")
            pending = lines.pop()
            # Limine prints its menu without newlines at the end; look at the
            # unfinished line too.
            for line in [*lines, pending]:
                clean = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", line)
                if "GFTEST" in clean and line is not pending:
                    msg = clean[clean.index("GFTEST") :].strip()
                    print(f"[guest] {msg}", flush=True)
                    if "FAIL install" in msg or "FAIL agent" in msg:
                        return 1
                    if msg.endswith("boot1 ready"):
                        shot("desktop")
                    if msg.endswith("rebooting into the broken system"):
                        broken_deadline = time.monotonic() + 240
                    if args.until in msg:
                        time.sleep(3)
                        shot("final")
                        return 0
                if (
                    args.snapshot_menu
                    and not broken_seen
                    and re.search(
                        r"Kernel panic|No working init found|Attempted to kill init|Failed to switch root|You are in emergency mode|Failed to execute /init|contains no usable init",
                        clean,
                    )
                ):
                    # The broken update did its job: the normal boot fails.
                    broken_seen = True
                    print(
                        "[driver] normal boot is broken as intended; resetting",
                        flush=True,
                    )
                    time.sleep(3)
                    shot("broken-boot")
                    mon.cmd("system_reset")
                    pick_snapshot()
                if not splash_shot and "BdsDxe: starting" in clean:
                    # First boot of this run: catch the boot splash after
                    # Limine's 5 s countdown, early and a bit later.
                    splash_shot = True
                    for t in (12, 16, 20, 24):
                        time.sleep(4 if t > 12 else 12)
                        shot(f"boot-{t}s")
                if "Linux version" in clean and line is not pending:
                    boot_count += 1
                    print(f"[driver] kernel boot #{boot_count}", flush=True)
        print(f"[driver] timeout waiting for '{args.until}'", flush=True)
        shot("timeout")
        return 1


if __name__ == "__main__":
    sys.exit(main())
