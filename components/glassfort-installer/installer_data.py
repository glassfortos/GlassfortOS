# SPDX-License-Identifier: GPL-3.0-or-later
"""Data and parsing for the installer UI (no Qt; tested on its own)."""

from __future__ import annotations

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class Language:
    locale: str  # glibc locale without encoding
    name: str  # in its own language
    keyboard: str  # console keymap
    xkb: str  # xkb layout (live session, Wayland)
    xkb_variant: str
    timezone: str


# Curated list (docs/04: screen 1). The keyboard and time zone are only
# defaults; the user can change both.
LANGUAGES = [
    Language("en_US", "English (US)", "us", "us", "", "America/New_York"),
    Language("en_GB", "English (UK)", "uk", "gb", "", "Europe/London"),
    Language("de_DE", "Deutsch", "de-latin1", "de", "", "Europe/Berlin"),
    Language("de_AT", "Deutsch (Österreich)", "de-latin1", "at", "", "Europe/Vienna"),
    Language("de_CH", "Deutsch (Schweiz)", "de_CH-latin1", "ch", "", "Europe/Zurich"),
    Language("fr_FR", "Français", "fr-latin1", "fr", "", "Europe/Paris"),
    Language("es_ES", "Español", "es", "es", "", "Europe/Madrid"),
    Language("it_IT", "Italiano", "it", "it", "", "Europe/Rome"),
    Language("nl_NL", "Nederlands", "us", "us", "", "Europe/Amsterdam"),
    Language("pl_PL", "Polski", "pl2", "pl", "", "Europe/Warsaw"),
    Language("pt_BR", "Português (Brasil)", "br-abnt2", "br", "", "America/Sao_Paulo"),
    Language("pt_PT", "Português", "pt-latin1", "pt", "", "Europe/Lisbon"),
    Language("sv_SE", "Svenska", "sv-latin1", "se", "", "Europe/Stockholm"),
    Language("tr_TR", "Türkçe", "trq", "tr", "", "Europe/Istanbul"),
]

# Keyboard layouts offered on screen 1: (console keymap, xkb layout, xkb
# variant, label).
KEYBOARDS = [
    ("us", "us", "", "English (US)"),
    ("uk", "gb", "", "English (UK)"),
    ("de-latin1", "de", "", "German"),
    ("de-latin1-nodeadkeys", "de", "nodeadkeys", "German (no dead keys)"),
    ("at", "at", "", "German (Austria)"),
    ("de_CH-latin1", "ch", "", "German (Switzerland)"),
    ("fr-latin1", "fr", "", "French"),
    ("fr_CH-latin1", "ch", "fr", "French (Switzerland)"),
    ("es", "es", "", "Spanish"),
    ("it", "it", "", "Italian"),
    ("pl2", "pl", "", "Polish"),
    ("br-abnt2", "br", "", "Portuguese (Brazil)"),
    ("pt-latin1", "pt", "", "Portuguese"),
    ("sv-latin1", "se", "", "Swedish"),
    ("trq", "tr", "", "Turkish"),
    ("dvorak", "us", "dvorak", "English (Dvorak)"),
]


def language(locale: str) -> Language:
    for lang in LANGUAGES:
        if lang.locale == locale:
            return lang
    return LANGUAGES[0]


def keyboard(keymap: str) -> tuple[str, str, str, str]:
    for kb in KEYBOARDS:
        if kb[0] == keymap:
            return kb
    return KEYBOARDS[0]


def username_from(full_name: str) -> str:
    """Suggest a user name: first word, lower case, ASCII only."""
    table = str.maketrans({"ä": "ae", "ö": "oe", "ü": "ue", "ß": "ss", "é": "e", "è": "e"})
    first = full_name.strip().split(" ")[0].lower().translate(table) if full_name.strip() else ""
    name = re.sub(r"[^a-z0-9_-]", "", first)
    if name and not re.match(r"[a-z_]", name[0]):
        name = "u" + name
    return name[:32]


def human_size(size: int) -> str:
    units = ["B", "KB", "MB", "GB", "TB"]
    value = float(size)
    for unit in units:
        if value < 1000 or unit == units[-1]:
            return f"{value:.0f} {unit}" if unit in ("B", "KB") else f"{value:.1f} {unit}"
        value /= 1000
    return f"{size} B"


def _split_nmcli(line: str) -> list[str]:
    """Split one line of `nmcli -t` output (':' separated, '\\:' escaped)."""
    fields, cur, esc = [], "", False
    for ch in line:
        if esc:
            cur += ch
            esc = False
        elif ch == "\\":
            esc = True
        elif ch == ":":
            fields.append(cur)
            cur = ""
        else:
            cur += ch
    fields.append(cur)
    return fields


def parse_wifi_list(output: str) -> list[dict]:
    """Parse `nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list`.

    One entry per SSID (the strongest), hidden networks left out, sorted by
    signal.
    """
    best: dict[str, dict] = {}
    for line in output.splitlines():
        if not line.strip():
            continue
        parts = _split_nmcli(line)
        if len(parts) < 4:
            continue
        in_use, ssid, signal, security = parts[:4]
        if not ssid:
            continue
        try:
            strength = int(signal)
        except ValueError:
            strength = 0
        entry = {
            "ssid": ssid,
            "signal": strength,
            "secure": security not in ("", "--"),
            "active": in_use.strip() == "*",
        }
        old = best.get(ssid)
        if old is None or strength > old["signal"] or entry["active"]:
            entry["active"] = entry["active"] or bool(old and old["active"])
            best[ssid] = entry
    return sorted(best.values(), key=lambda e: (-e["active"], -e["signal"], e["ssid"]))


def wired_connected(output: str) -> bool:
    """`nmcli -t -f TYPE,STATE device`: is an Ethernet device connected?"""
    for line in output.splitlines():
        parts = _split_nmcli(line)
        if len(parts) >= 2 and parts[0] == "ethernet" and parts[1] == "connected":
            return True
    return False
