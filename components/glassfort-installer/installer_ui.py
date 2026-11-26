# SPDX-License-Identifier: GPL-3.0-or-later
"""Glassfort installer UI: PySide6 bridge between the QML pages and the
system (NetworkManager, the live session's keyboard, the backend).

The UI runs as the live user. Only the backend (glassfort-install) runs as
root: it is started with sudo, which the live session allows without a
password (iso/airootfs/etc/sudoers.d/10-live). The plan goes to the
backend on stdin, never on the command line.
"""

from __future__ import annotations

import gettext
import json
import os
import subprocess
import sys
from pathlib import Path

from PySide6.QtCore import Property, QObject, QProcess, QTranslator, QUrl, Signal, Slot
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

import installer_data as data

DOMAIN = "glassfort-installer"
QML_DIR = Path(os.environ.get("GLASSFORT_INSTALLER_QML", "/usr/share/glassfort-installer/qml"))
BACKEND = os.environ.get("GLASSFORT_INSTALL_BACKEND", "/usr/bin/glassfort-install")

_translation = {"current": gettext.translation(DOMAIN, fallback=True)}


def _(text: str) -> str:
    return _translation["current"].gettext(text)


def _run(args: list[str], timeout: int = 20) -> str:
    try:
        return subprocess.run(
            args, capture_output=True, text=True, timeout=timeout, check=False
        ).stdout
    except (OSError, subprocess.TimeoutExpired):
        return ""


class GettextTranslator(QTranslator):
    """Serves QML's qsTr() from gettext (domain glassfort-installer), so the
    whole installer has one translation catalogue and a language change
    retranslates the running UI (QQmlEngine.retranslate)."""

    def translate(self, context, source_text, disambiguation=None, n=-1):
        # Always return text: an empty Python string reaches Qt as an empty,
        # non-null QString, which Qt takes as the translation (blank labels).
        # gettext already falls back to the source text.
        return _(source_text)


class Installer(QObject):
    languageChanged = Signal()
    disksChanged = Signal()
    wifiChanged = Signal()
    networkChanged = Signal()
    progress = Signal(str, int)  # stage, percent
    finished = Signal(str)  # recovery key ("" without encryption)
    failed = Signal(str)  # message

    def __init__(self) -> None:
        super().__init__()
        self._disks: list[dict] = []
        self._wifi: list[dict] = []
        self._online = False
        self._wired = False
        self._proc: QProcess | None = None
        self._buf = b""
        self._error = ""

    # --- Language and keyboard -------------------------------------------------

    @Property("QVariantList", constant=True)
    def languages(self) -> list[dict]:
        return [
            {
                "locale": lang.locale,
                "name": lang.name,
                "keyboard": lang.keyboard,
                "timezone": lang.timezone,
            }
            for lang in data.LANGUAGES
        ]

    @Property("QVariantList", notify=languageChanged)
    def keyboards(self) -> list[dict]:
        return [{"keymap": k[0], "name": _(k[3])} for k in data.KEYBOARDS]

    @Property("QVariantList", constant=True)
    def timezones(self) -> list[str]:
        out = _run(["timedatectl", "list-timezones"]).split()
        return out or ["UTC"]

    @Slot(str)
    def setLanguage(self, locale: str) -> None:
        """Switch the UI language for strings looked up from now on."""
        os.environ["LANGUAGE"] = locale
        _translation["current"] = gettext.translation(DOMAIN, languages=[locale], fallback=True)
        self.languageChanged.emit()

    @Slot(str)
    def setKeyboard(self, keymap: str) -> None:
        """Use the chosen layout in the live session right away, so passwords
        are typed with the layout the installed system will have."""
        _keymap, layout, variant, _name = data.keyboard(keymap)
        # KWin watches kxkbrc with KConfigWatcher: the change must be written
        # with a notification (--notify), a plain file write is not seen.
        # Detached, so the UI does not wait for it.
        script = "; ".join(
            f"kwriteconfig6 --file kxkbrc --group Layout --key {key} --notify '{value}'"
            for key, value in (("Use", "true"), ("LayoutList", layout), ("VariantList", variant))
        )
        QProcess.startDetached("sh", ["-c", script])

    # --- Network ---------------------------------------------------------------

    @Property(bool, notify=networkChanged)
    def online(self) -> bool:
        return self._online

    @Property(bool, notify=networkChanged)
    def wired(self) -> bool:
        return self._wired

    @Property("QVariantList", notify=wifiChanged)
    def wifiNetworks(self) -> list[dict]:
        return self._wifi

    @Slot()
    def refreshNetwork(self) -> None:
        self._wired = data.wired_connected(_run(["nmcli", "-t", "-f", "TYPE,STATE", "device"]))
        # Without "check": a recheck needs a polkit permission the live user
        # does not have ("Not authorized"); NetworkManager rechecks by itself
        # and the page polls every 10 seconds.
        self._online = _run(["nmcli", "networking", "connectivity"]).strip() == "full"
        self.networkChanged.emit()

    @Slot()
    def scanWifi(self) -> None:
        out = _run(
            [
                "nmcli",
                "-t",
                "-f",
                "IN-USE,SSID,SIGNAL,SECURITY",
                "device",
                "wifi",
                "list",
                "--rescan",
                "yes",
            ]
        )
        self._wifi = data.parse_wifi_list(out)
        self.wifiChanged.emit()
        self.refreshNetwork()

    @Slot(str, str, result=str)
    def connectWifi(self, ssid: str, password: str) -> str:
        """Connect; returns "" on success or nmcli's message."""
        args = ["nmcli", "--wait", "30", "device", "wifi", "connect", ssid]
        if password:
            args += ["password", password]
        try:
            res = subprocess.run(args, capture_output=True, text=True, timeout=40, check=False)
        except (OSError, subprocess.TimeoutExpired) as err:
            return str(err)
        self.scanWifi()
        return "" if res.returncode == 0 else (res.stderr.strip() or res.stdout.strip())

    # --- Disks -----------------------------------------------------------------

    @Property("QVariantList", notify=disksChanged)
    def disks(self) -> list[dict]:
        return self._disks

    @Slot()
    def refreshDisks(self) -> None:
        out = _run(["sudo", "-n", BACKEND, "disks"])
        try:
            disks = json.loads(out)
        except json.JSONDecodeError:
            disks = []
        for d in disks:
            d["label"] = d["model"] or d["path"]
            d["sizeText"] = data.human_size(d["size"])
        self._disks = disks
        self.disksChanged.emit()

    # --- User ------------------------------------------------------------------

    @Slot(str, result=str)
    def suggestUsername(self, full_name: str) -> str:
        return data.username_from(full_name)

    # --- Installation ----------------------------------------------------------

    @Slot("QVariantMap")
    def install(self, plan: dict) -> None:
        if self._proc is not None:
            return
        self._proc = QProcess(self)
        self._proc.setProgram("sudo")
        self._proc.setArguments(["-n", BACKEND, "install"])
        self._proc.readyReadStandardOutput.connect(self._read)
        self._proc.finished.connect(self._done)
        self._proc.start()
        self._proc.write(json.dumps(plan).encode())
        self._proc.closeWriteChannel()

    def _read(self) -> None:
        if self._proc is None:
            return
        self._buf += bytes(self._proc.readAllStandardOutput())
        *lines, self._buf = self._buf.split(b"\n")
        for raw in lines:
            try:
                ev = json.loads(raw)
            except json.JSONDecodeError:
                continue
            if ev.get("event") == "progress":
                self.progress.emit(ev.get("stage", ""), int(ev.get("percent", 0)))
            elif ev.get("event") == "done":
                self.finished.emit(ev.get("recovery_key") or "")
            elif ev.get("event") == "error":
                self._error = ev.get("message", "")

    def _done(self, code: int, _status) -> None:
        if code != 0:
            self.failed.emit(self._error or _("The installation stopped unexpectedly."))
        self._proc = None

    @Slot()
    def reboot(self) -> None:
        _run(["systemctl", "reboot"])


def main() -> int:
    QGuiApplication.setApplicationName("glassfort-installer")
    QGuiApplication.setApplicationDisplayName(_("Install Glassfort"))
    QGuiApplication.setDesktopFileName("org.glassfort.installer")
    app = QGuiApplication(sys.argv)
    app.setWindowIcon(QIcon.fromTheme("glassfort"))
    engine = QQmlApplicationEngine()
    translator = GettextTranslator(app)
    app.installTranslator(translator)
    installer = Installer()
    installer.languageChanged.connect(engine.retranslate)
    engine.rootContext().setContextProperty("installer", installer)
    engine.load(QUrl.fromLocalFile(str(QML_DIR / "Main.qml")))
    if not engine.rootObjects():
        return 1
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
