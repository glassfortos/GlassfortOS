#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Control a running test VM: screenshots, keys, mouse, commands.

Talks to QEMU's human monitor (screendump, sendkey), QMP (mouse) and to the QEMU
guest agent (guest-exec) over UNIX sockets in a VM directory, as started by
a manual or scripted test VM (QEMU with -qmp, -monitor and a guest agent
channel, machine option vmport=off so the USB tablet gets the pointer
events). Used for the installer tests; stdlib only.

    vmctl.py DIR shot NAME            screenshot to DIR/NAME.png
    vmctl.py DIR key KEY...           e.g. tab, ret, shift-tab, ctrl-a
    vmctl.py DIR type TEXT            type ASCII text
    vmctl.py DIR click X Y            left click at screen pixel X,Y
    vmctl.py DIR exec CMD...          run a command in the guest (root)
"""

from __future__ import annotations

import base64
import json
import socket
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from vmdriver import Monitor

SCREEN = (1280, 800)  # virtio-vga default mode of the live session

KEYS = {
    " ": "spc",
    "-": "minus",
    "_": "shift-minus",
    ".": "dot",
    ",": "comma",
    "@": "shift-2",
    "!": "shift-1",
    ":": "shift-semicolon",
    "/": "slash",
}


def qga(path: Path, cmd: str, args: dict | None = None, timeout: float = 30) -> dict:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(str(path))
        s.settimeout(timeout)
        # Resynchronise, then send the command.
        s.sendall(json.dumps({"execute": "guest-sync", "arguments": {"id": 4711}}).encode())
        buf = b""
        while b"4711" not in buf:
            buf += s.recv(65536)
        s.sendall(json.dumps({"execute": cmd, "arguments": args or {}}).encode())
        buf = b""
        while True:
            buf += s.recv(65536)
            try:
                return json.loads(buf.decode().strip().splitlines()[-1])
            except (json.JSONDecodeError, IndexError):
                continue


def qmp(path: Path, cmd: str, args: dict | None = None) -> dict:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(str(path))
        s.settimeout(10)
        f = s.makefile("rw")
        f.readline()  # greeting
        for c, a in (("qmp_capabilities", {}), (cmd, args or {})):
            f.write(json.dumps({"execute": c, "arguments": a}) + "\n")
            f.flush()
            while True:
                reply = json.loads(f.readline())
                if "return" in reply or "error" in reply:
                    break
        return reply


def guest_exec(path: Path, argv: list[str], timeout: float = 600) -> tuple[int, str]:
    pid = qga(path, "guest-exec", {"path": argv[0], "arg": argv[1:], "capture-output": True})[
        "return"
    ]["pid"]
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        st = qga(path, "guest-exec-status", {"pid": pid})["return"]
        if st.get("exited"):
            out = base64.b64decode(st.get("out-data", "")).decode(errors="replace")
            err = base64.b64decode(st.get("err-data", "")).decode(errors="replace")
            return st.get("exitcode", -1), out + err
        time.sleep(1)
    return -1, "timeout"


def main() -> int:
    vm = Path(sys.argv[1])
    cmd, args = sys.argv[2], sys.argv[3:]
    mon = Monitor(vm / "monitor.sock")
    if cmd == "shot":
        mon.screenshot(vm / f"{args[0]}.png")
        print(vm / f"{args[0]}.png")
    elif cmd == "key":
        for k in args:
            mon.key(k)
            time.sleep(0.15)
    elif cmd == "type":
        for ch in " ".join(args):
            k = KEYS.get(ch)
            if k is None:
                k = f"shift-{ch.lower()}" if ch.isupper() else ch
            mon.key(k)
            time.sleep(0.05)
    elif cmd == "click":
        x, y = int(args[0]), int(args[1])
        # usb-tablet: absolute coordinates 0..32767 (the monitor's mouse_move
        # is relative only, so this goes through QMP).
        # Two moves (the second one pixel off and back): the first motion
        # after a pause is sometimes dropped, and Qt needs a hover event at
        # the target before the press.
        for dx in (1, 0):
            ax, ay = (x + dx) * 32767 // SCREEN[0], y * 32767 // SCREEN[1]
            move = [
                {"type": "abs", "data": {"axis": "x", "value": ax}},
                {"type": "abs", "data": {"axis": "y", "value": ay}},
            ]
            qmp(vm / "qmp.sock", "input-send-event", {"events": move})
            time.sleep(0.25)
        for down in (True, False):
            btn = {"type": "btn", "data": {"down": down, "button": "left"}}
            qmp(vm / "qmp.sock", "input-send-event", {"events": [btn]})
            time.sleep(0.2)
        # A motion after the release: without it the release sometimes only
        # reaches the application with the next input event.
        qmp(vm / "qmp.sock", "input-send-event", {"events": move})
    elif cmd == "exec":
        code, out = guest_exec(vm / "qga.sock", args)
        print(out, end="")
        return code
    else:
        print(__doc__, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
