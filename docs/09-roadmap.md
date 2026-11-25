# 09 – Roadmap

Order of priority: first what everything is judged by (look and usability), then the unique selling point (unbreakable), then assistant and Windows Apps.

**v0.1 scope: Open.** Proposal: v0.1 = Phase 1 complete (installable on top of a plain Arch install).

## Phase 0 – Repository foundation

- Licences (`LICENSE`, `LICENSES/`), `TRADEMARKS.md`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`
- Repository layout from `01-architecture.md`, CI skeleton (lint + package build)
- **Done when:** CI builds an empty `glassfort-settings` package in a clean chroot.

## Phase 1 – Foundation on plain Arch

- `[glassfort]` repo + keyring
- `glassfort-settings`: Btrfs/snapper/snap-pac/limine-snapper-sync configuration, `linux-lts` fallback, firewalld, AppArmor, sysctl, zram, keyd (Copilot key)
- `glassfort-theme` + `glassfort-branding`: Global Theme, colours, Kvantum, GTK, kitty, fonts, wallpapers, Plymouth
- `glassfort-shell`: Start menu, taskbar/dock, control center
- Meta package `glassfort-desktop`
- **Done when:** on a fresh Arch install, `pacman -S glassfort-desktop` (after adding the repo) turns it into Glassfort, and a broken update can be rolled back from the boot menu.

## Phase 2 – Own ISO, Time Machine, update app

- archiso profile, ISO built in CI
- `glassfort-installer` (QML/Kirigami + archinstall), moved forward from Phase 4 (D-12: no interim Calamares)
- `glassfort-timemachine`
- `glassfort-update`
- Secure Boot with Limine validated on 3–4 firmware vendors
- **Done when:** a user can install from the ISO and recover from a broken update without a terminal.

## Phase 3 – Assistant (MVP)

- `glassfort-helper` (Rust) + polkit actions + audit log
- MCP server
- `glassfort-assistant` service + chat Plasmoid
- Tools: search/install packages, system update with snapshot, 10 settings
- **Done when:** "Install Steam" works end-to-end with confirmation, snapshot and undo; prompt-injection suite passes.

## Phase 4 – First boot

- `glassfort-firstboot`
- Installer polish: dual boot alongside an existing system, more languages
- **Done when:** a new user is guided from the first login to a set-up system (look, assistant, app packs) without a terminal.

## Phase 5 – Windows Apps

- `glassfort-windows`: hardware check, setup, app integration, tray, auto-pause
- Licensing documentation
- **Done when:** a user installs Word from Windows and opens it from the Start menu.

## Later

- Snap layouts popup (Windows 11 style)
- Own icon set
- Delayed/tested update channel (if ever needed)
