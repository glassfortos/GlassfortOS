# 01 – Architecture

## Stack

| Layer | Choice | Notes |
|---|---|---|
| Base | Arch Linux, x86_64 | Official Arch repositories used directly |
| Desktop | KDE Plasma 6 (Wayland, KWin) | Heavily curated, own theme and widgets |
| Packages | pacman + Flatpak (Flathub) | AUR not enabled by default |
| Own repository | `[glassfort]`, GPG-signed | All Glassfort packages, plus packages we must carry |
| Terminal | kitty | Follows the accent colour |
| Filesystem | Btrfs with subvolumes | See `02-system.md` |
| Bootloader | Limine + limine-snapper-sync | GRUB + grub-btrfs only as plan B |
| Kernels | `linux` (default) + `linux-lts` (fallback) | Both always installed |
| Installer | QML/Kirigami frontend + archinstall backend | – (no interim installer, D-12) |
| ISO | archiso | Built in CI |

## Repository layout

```
glassfort/
├── CLAUDE.md                  # how Claude Code works here
├── PROGRESS.md                # current task + log
├── README.md
├── LICENSE                    # GPL-3.0-or-later (code)
├── LICENSES/CC-BY-SA-4.0.txt  # documentation and artwork (except name/logo)
├── TRADEMARKS.md              # usage rules for the Glassfort name and logo
├── CONTRIBUTING.md
├── SECURITY.md
├── CODE_OF_CONDUCT.md
├── docs/                      # specification (this folder)
├── components/                # one folder per package: source + PKGBUILD
│   ├── glassfort-settings/    # system defaults (snapper, limine, sysctl, firewalld, pacman.conf)
│   ├── glassfort-theme/       # global theme, colours, Kvantum, icons, cursors, sounds, wallpapers
│   ├── glassfort-branding/    # logos, Plymouth theme, login and lock screen
│   ├── glassfort-shell/       # Plasmoids: Start menu, taskbar/dock, control center
│   ├── glassfort-timemachine/ # System Settings module for snapshots
│   ├── glassfort-update/      # update app
│   ├── glassfort-helper/      # Rust: privileged helper (D-Bus system service)
│   ├── glassfort-assistant/   # Python: AI service, MCP server; QML chat Plasmoid
│   ├── glassfort-windows/     # Windows apps module (System Settings + tray)
│   ├── glassfort-installer/   # installer (UI + backend on archinstall)
│   ├── glassfort-firstboot/   # first-boot experience (extends Plasma Setup)
│   ├── glassfort-keyring/     # repository signing keys (public)
│   ├── glassfort-mirrorlist/  # mirrors for [glassfort]
│   └── third-party/           # packages we carry because they are AUR-only
│       ├── limine-snapper-sync/
│       ├── limine-mkinitcpio-hook/
│       └── nvidia-580xx-dkms/  # legacy driver for Pascal (GTX 10xx) and older
├── iso/                       # archiso profile
├── repo/                      # scripts: build, sign, publish [glassfort]
├── scripts/                   # dev tools (validate-registry, vm-test, …)
├── tests/                     # unit tests, VM tests, openQA
└── .github/workflows/         # CI
```

Each component folder contains its source, a `PKGBUILD`, a short `README.md` and its tests.

## Packages and responsibilities

| Package | Responsibility | Language |
|---|---|---|
| `glassfort-settings` | All system defaults: snapper configs, limine config, sysctl, firewalld zones, AppArmor, pacman.conf (repo order), zram, keyd config for the Copilot key | Config + shell |
| `glassfort-theme` | Global Theme, Plasma style, colour schemes (GlassfortLight/GlassfortDark), Kvantum theme, GTK (adw-gtk3) settings, kitty theme, wallpapers | Config, QML, SVG |
| `glassfort-branding` | Logos, Plymouth, login screen, lock screen | SVG, QML |
| `glassfort-shell` | Start menu, taskbar/dock, control center Plasmoids | QML, C++ where needed |
| `glassfort-timemachine` | Snapshot timeline, restore, pin | QML (KCM), C++ |
| `glassfort-update` | Update flow (see `02-system.md`) | QML + Rust or Python |
| `glassfort-helper` | Privileged helper: validated actions, snapshots, audit log | Rust |
| `glassfort-assistant` | AI service, MCP server, chat Plasmoid | Python + QML |
| `glassfort-windows` | VM lifecycle, app integration, hardware check | QML + Python |
| `glassfort-installer` | Installer UI and backend (`glassfort-install`, D-42) | QML/Kirigami + Python (archinstall) |
| `glassfort-firstboot` | First-boot screens | QML |
| `glassfort-keyring` | Public signing keys | – |
| `glassfort-mirrorlist` | Server list for `[glassfort]` (Phase 1: local `file://` repo, D-33) | Config |
| meta `glassfort-desktop` | Pulls in Plasma, default apps and all Glassfort packages | – |

## Release model (Decided)

- **Rolling release directly on Arch.** Glassfort uses the official Arch repositories as they are; Arch updates are not held back or re-tested.
- **Safety comes from the system, not from delays:**
  - snapshot before every pacman transaction (snap-pac),
  - `linux-lts` always installed as fallback kernel,
  - update app checks Arch news for manual interventions before upgrading,
  - one-click rollback from the Time Machine or the boot menu.
- `[glassfort]` is listed **before** `[core]` in `pacman.conf`. It may only contain packages that do not exist in the official Arch repositories, except for overrides explicitly documented in `docs/DECISIONS.md`.
- Partial upgrades are forbidden everywhere: installing a package always happens on a fully upgraded system (`pacman -Syu <pkg>` or no sync at all).
- A delayed or tested channel may be reconsidered later (see `DECISIONS.md`); it is not part of v1.

## Kernels (Decided)

- `linux` is the default boot entry, `linux-lts` the fallback entry. Both, plus their headers (for DKMS), are always installed.
- The installer installs both; the update app refuses to remove the last working fallback.
- The boot menu shows: `Glassfort`, `Glassfort (LTS kernel – fallback)`, then the snapshot entries.

## Build and publishing pipeline

1. CI builds every changed package in a clean chroot (`extra-x86_64-build`) and runs its tests.
2. Packages are signed with the repository key. The key stays offline on a hardware token; CI produces unsigned packages, the maintainer signs and publishes them with `repo/publish` (D-26).
3. `repo/publish` signs the packages and runs `repo-add --sign` on the repository directory. Phase 1: the repository is local only and used through `file://` (D-33); uploading to the primary server and triggering mirror sync follow once a server exists. VM tests sign with a throwaway key created inside the VM (`repo/vm-test-key`, D-26).
4. The ISO is built with archiso from `iso/` in CI.
5. ISO hosting: **not** GitHub Releases (2 GiB per-file limit). Use SourceForge and/or our own mirror.

## Inter-process communication

- System services expose **D-Bus** interfaces (`org.glassfort.*`).
- Privileged actions always go through polkit (`org.glassfort.helper.*` actions).
- No component talks to another through ad-hoc files or sockets.
