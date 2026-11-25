# glassfort-installer

Installs Glassfort from the live medium. Specification:
[`docs/04-installer.md`](../../docs/04-installer.md); disk layout:
[`docs/02-system.md`](../../docs/02-system.md). Decision: D-12 in
[`docs/DECISIONS.md`](../../docs/DECISIONS.md) (own installer on top of
archinstall, no interim Calamares).

## Parts

| Part | File | Status |
|---|---|---|
| Backend (root) | `glassfort_install.py`, `/usr/bin/glassfort-install` | done |
| UI (QML/Kirigami, five screens) | – | next step |

## Backend

`glassfort-install` never asks questions; the UI collects everything first.

| Command | What it does |
|---|---|
| `glassfort-install disks` | Target disks as JSON (whole, writable disks; the live medium is left out; `big_enough` = at least 40 GiB) |
| `glassfort-install install` | Installs from a *plan* (JSON on stdin), reports progress as JSON lines |
| `glassfort-install config --disk-size N` | Prints the archinstall configuration for a plan (for checks; changes nothing) |

A plan:

```json
{
  "locale": "de_DE", "keyboard": "de-latin1", "timezone": "Europe/Berlin",
  "disk": "/dev/nvme0n1", "username": "jan", "full_name": "Jan",
  "password": "…", "encrypt": true, "disk_passphrase": null,
  "hostname": "glassfort", "look": "auto"
}
```

`disk_passphrase: null` unlocks the disk with the user password (docs/04,
screen 4). Every field is validated (user name, host name, locale and
keyboard patterns, an existing time zone, a whole-disk path); unknown fields
are rejected.

What `install` does:

1. **archinstall** with a generated configuration (passwords only in a
   separate credentials file, mode 0600, deleted afterwards): GPT with a
   4 GiB FAT32 ESP at `/boot` and LUKS2 → Btrfs (`compress=zstd:1,noatime`)
   with the subvolumes `@`, `@home`, `@var_log`, `@var_cache_pacman_pkg`,
   `@snapshots`, `@vm`; Limine on the removable path; `linux` and
   `linux-lts` with headers; NetworkManager; PipeWire; `glassfort-desktop`
   from the `[glassfort]` repository on the medium
   (`/srv/glassfort/repo/x86_64`, unsigned until the real key exists,
   D-26). No swap partition and no snapper setup here: zram, snapper and
   the Limine snapshot entries come from `glassfort-settings`
   (`glassfort-setup` runs when `glassfort-desktop` is installed).
2. **Finishing** (the installed system is opened and mounted again):
   `[glassfort]` above `[core]` with `glassfort-mirrorlist`, a copy of the
   repository at the mirror list's path (until it is hosted, D-33), the
   Wi-Fi connections of the live session, `chattr +C` on the VM subvolume,
   and light or dark look if the user did not pick "automatic".
3. **Recovery key**: `systemd-cryptenroll --recovery-key`; the UI shows it
   once (`{"event": "done", "recovery_key": …}`).

Progress events: `{"event": "progress", "stage": …, "percent": …}`,
`{"event": "error", "reason": "plan"|"install", "message": …}`,
`{"event": "done", …}`. archinstall's output goes to
`/var/log/glassfort-install.log`.

## Checks

```sh
ruff check . && ruff format --check . && pytest
```

The tests cover plan validation, the disk list and the generated
configuration; they run without root and touch no disks. The whole
installation is tested in a VM (`tests/vm/`).
