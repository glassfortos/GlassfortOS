# Decisions

Status values:

- **Decided** – fixed; change only after asking the maintainer.
- **Proposed** – recommendation, not yet confirmed; ask before relying on it for something hard to undo.
- **Open** – still to be decided.

Claude Code adds new decisions as **Proposed**. Only the maintainer sets **Decided**.

| ID | Topic | Decision | Status | Date |
|---|---|---|---|---|
| D-01 | Base | Arch Linux, x86_64 | Decided | 2026-11-19 |
| D-02 | Desktop | KDE Plasma 6 (instead of Hyprland), heavily curated | Decided | 2026-11-19 |
| D-03 | Concept | Windows UX + macOS-inspired glass design | Decided | 2026-11-19 |
| D-04 | Terminal | kitty | Decided | 2026-11-19 |
| D-05 | Packages | pacman + Flatpak; AUR not enabled by default; AUR-only needs are packaged into `[glassfort]` | Decided | 2026-11-19 |
| D-06 | Snapshots | Btrfs + snapper + snap-pac + limine-snapper-sync | Decided | 2026-11-19 |
| D-07 | Bootloader | Limine; GRUB + grub-btrfs only as plan B | Decided | 2026-11-19 |
| D-08 | Secure Boot | sbctl + limine-enroll-config; hook always handles `limine_x64.efi` and `BOOTX64.EFI`; kernels not signed | Decided | 2026-11-19 |
| D-09 | Encryption | LUKS2 by default, optional TPM2 unlock | Decided | 2026-11-19 |
| D-10 | Firewall | firewalld with Windows-like network profiles | Decided | 2026-11-19 |
| D-11 | Default apps | Firefox, LibreOffice (Tabbed UI), Thunderbird | Decided | 2026-11-19 |
| D-12 | Installer | QML/Kirigami frontend + archinstall backend; Calamares as interim | Decided | 2026-11-19 |
| D-13 | Assistant | Chat operates the system via typed tools; "AI plans, system executes"; off by default | Decided | 2026-11-19 |
| D-14 | Assistant languages | Helper in Rust, assistant service in Python | Decided | 2026-11-19 |
| D-15 | Settings registry | TOML with schema in `/usr/share/glassfort/settings.d/`, package-owned only; backends kconfig/dbus/exec, never a shell | Decided | 2026-11-19 |
| D-16 | Windows Apps | Optional; Windows 11 Pro via dockur in Podman, FreeRDP RemoteApp; LTSC only with organisation licence; no ISO/keys shipped | Decided | 2026-11-19 |
| D-17 | Name | Glassfort – "Beautiful as glass. Strong as a fortress." | Decided | 2026-11-19 |
| D-18 | Product language | English (name, website, docs, UI, marketing) | Decided | 2026-11-19 |
| D-19 | Release model | Rolling directly on Arch repos; safety via snapshots, LTS fallback kernel, Arch news check; no held-back channel in v1 | Decided | 2026-11-22 |
| D-20 | Kernels | `linux` default + `linux-lts` fallback, both always installed with headers | Decided | 2026-11-22 |
| D-21 | Licences | Code GPL-3.0-or-later; docs/artwork CC BY-SA 4.0; name and logo excluded, governed by `TRADEMARKS.md` | Decided | 2026-11-22 |
| D-22 | Colour palette | Glacier Teal `#3DD6C6`, Fort Indigo `#4C4FE0`, Midnight `#0E1222`, Frost `#F5F7FA`, Steel `#8B93A7` | Decided | 2026-11-22 |
| D-23 | Fonts | Inter (UI, `inter-font`), JetBrains Mono (monospace, `ttf-jetbrains-mono`); both from the official Arch repositories | Decided | 2026-11-22 |
| D-24 | Logo | The maintainer's draft (glass fortress tower, three crenellations, teal → indigo) is the logo. It is redrawn as our own vector artwork and optimised for small sizes: fewer overlapping panes in the full-colour symbol, a flat variant for 16–32 px | Decided | 2026-11-24 |
| D-25 | Versioning | Dated ISO releases `YYYY.MM` | Proposed | 2026-11-22 |
| D-26 | Signing key | Offline on hardware token; CI builds unsigned, maintainer signs. Until the real key exists, VM tests use a throwaway key that never leaves the VM | Decided | 2026-11-22 |
| D-27 | Telemetry | None, or strictly opt-in | Proposed | 2026-11-22 |
| D-28 | Community channel | Forum, Matrix or Discord | Open | – |
| D-29 | v0.1 scope | Proposal: Phase 1 complete | Open | – |
| D-30 | Domains | `glassfort.org` primary, `glassfortos.com` redirect – not yet registered | Open | – |
| D-31 | Legal (Germany) | Impressum, privacy policy, side-activity check | Open | – |
| D-32 | `glassfort-settings` dependencies | Hard `depends` on everything its configuration needs: snapper, snap-pac, btrfs-progs, limine, limine-mkinitcpio-hook, limine-snapper-sync, linux-lts + headers, firewalld, apparmor, zram-generator, keyd | Decided | 2026-11-22 |
| D-33 | `[glassfort]` hosting (Phase 1) | Local only: built and tested via `file://` in VMs; public server decided later (see D-30) | Decided | 2026-11-22 |
| D-34 | `glassfort-theme` dependencies | Hard `depends` on inter-font, ttf-jetbrains-mono, kvantum, adw-gtk-theme; Plasma itself comes from `glassfort-desktop` | Decided | 2026-11-23 |
| D-35 | Wallpapers (interim) | Own abstract SVG placeholders in the palette (light + dark, no logo) until the final artwork exists (D-24) | Decided | 2026-11-23 |
| D-36 | Shell widgets | Start menu, taskbar/dock and control center are our own QML plasmoids from the start (no interim layout from stock Plasma widgets). Data comes from Plasma's QML models (kicker, task manager, system tray backends) | Decided | 2026-11-24 |
| D-37 | Plasma in `glassfort-desktop` | Curated list of Plasma packages instead of `plasma-meta` | Decided | 2026-11-24 |
| D-38 | Login manager | SDDM (with `sddm-kcm`); Glassfort login theme follows with `glassfort-branding` | Decided | 2026-11-24 |
| D-39 | Default apps in `glassfort-desktop` | Hard dependencies (installed with the meta package), not optdepends | Decided | 2026-11-24 |
| D-40 | LibreOffice | `libreoffice-fresh` | Decided | 2026-11-24 |
| D-41 | Boot splash | Plymouth with a Glassfort theme; `glassfort-desktop` depends on plymouth, `glassfort-setup` adds the initramfs hook and `quiet splash` | Decided | 2026-11-25 |
