# SPDX-License-Identifier: GPL-3.0-or-later
"""Tests for the installer UI's data and parsing helpers."""

from __future__ import annotations

import re
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent))

import glassfort_install as gi
import installer_data as data


def test_languages_are_valid_plans(tmp_path: Path) -> None:
    keymaps = {k[0] for k in data.KEYBOARDS}
    for lang in data.LANGUAGES:
        assert gi.LOCALE_RE.match(lang.locale)
        assert gi.KEYBOARD_RE.match(lang.keyboard)
        assert lang.keyboard in keymaps, lang.locale
        assert Path("/usr/share/zoneinfo", lang.timezone).exists() or "/" in lang.timezone
    assert len({lang.locale for lang in data.LANGUAGES}) == len(data.LANGUAGES)


def test_keyboard_fallback() -> None:
    assert data.keyboard("de-latin1")[1] == "de"
    assert data.keyboard("nonexistent")[0] == "us"
    assert data.language("xx_XX").locale == "en_US"


@pytest.mark.parametrize(
    ("full", "user"),
    [
        ("Jan Klein", "jan"),
        ("  Jürgen Groß", "juergen"),
        ("José", "jose"),
        ("2Pac", "u2pac"),
        ("", ""),
        ("!!!", ""),
    ],
)
def test_username_from(full: str, user: str) -> None:
    assert data.username_from(full) == user
    if user:
        assert gi.USERNAME_RE.match(user)


def test_human_size() -> None:
    assert data.human_size(512 * 10**9) == "512.0 GB"
    assert data.human_size(2 * 10**12) == "2.0 TB"
    assert data.human_size(500) == "500 B"


def test_parse_wifi_list() -> None:
    out = "\n".join(
        [
            " :Home:54:WPA2",
            "*:Home:80:WPA2",
            " :Cafe\\: free:40:",
            " ::90:WPA2",
            " :Office:70:WPA2 802.1X",
            "garbage",
        ]
    )
    nets = data.parse_wifi_list(out)
    assert [n["ssid"] for n in nets] == ["Home", "Office", "Cafe: free"]
    assert nets[0]["active"] and nets[0]["signal"] == 80
    assert nets[2]["secure"] is False


def test_wired_connected() -> None:
    assert data.wired_connected("ethernet:connected\nwifi:disconnected\n")
    assert not data.wired_connected("ethernet:unavailable\nwifi:connected\n")
    assert not data.wired_connected("")


def test_german_catalogue(tmp_path: Path) -> None:
    import gettext
    import subprocess

    here = Path(__file__).resolve().parent
    mo = tmp_path / "de" / "LC_MESSAGES" / "glassfort-installer.mo"
    mo.parent.mkdir(parents=True)
    subprocess.run(
        ["msgfmt", "--check", "-o", str(mo), str(here / "glassfort-installer-de.po")], check=True
    )
    t = gettext.translation("glassfort-installer", tmp_path, languages=["de_DE"])
    assert t.gettext("Continue") == "Weiter"
    assert t.gettext("German") == "Deutsch"
    # Every string in the template is translated.
    pot = (here / "glassfort-installer.pot").read_text()
    for msgid in re.findall(r'^msgid "(.+)"$', pot, re.MULTILINE):
        text = msgid.replace('\\"', '"')
        assert t.gettext(text) != text, text
