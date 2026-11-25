# 04 – Installer and first boot

## Live ISO

- Boots straight into the Glassfort desktop (Wayland), installer opens automatically – similar to the macOS setup assistant.
- Orca screen reader available from the first screen (`Super+Alt+S`); keyboard navigation everywhere.

## Installer (`glassfort-installer`)

- **Frontend:** own QML/Kirigami UI in Glassfort's look.
- **Backend:** `glassfort-install` drives archinstall with a generated configuration (D-42). We do not write our own partitioning logic.
- **No interim installer** (D-12): Calamares is only in the AUR; the own installer is built in Phase 2 together with the ISO.

### Screens (at most 5)

1. **Language and keyboard**
2. **Wi-Fi** (skipped when wired)
3. **Disk:** default *"Erase disk, encrypted"* in one click → layout from `02-system.md`. Advanced: choose disk, dual-boot alongside existing system (later).
4. **User:** name, password; option *"Use this password to unlock the disk"* vs separate disk passphrase. Show the recovery key once.
5. **Look:** light/dark/automatic, accent preview

Then: progress screen with short slides about the six promises; restart.

### What the installer always sets up

- Btrfs subvolumes, snapper, snap-pac, limine-snapper-sync
- `linux` + `linux-lts` (+ headers), Limine entries for both
- Correct GPU driver (see `02-system.md`)
- `[glassfort]` repository and keyring
- firewalld, AppArmor, zram, hardened sysctl
- Secure Boot enrollment if the firmware is in setup mode

## First boot (`glassfort-firstboot`, extends Plasma Setup)

1. Account (if not created in the installer)
2. Look (light/dark/automatic)
3. **Assistant:** Off (default) / Local model / Own provider – with one sentence on privacy
4. **Snapshots** explained in one sentence: *"Every change can be undone – even if your system won't start."*
5. **App packs:** Browser choice, Office, Gaming
6. **Windows Apps** (only offered if the hardware check is green or yellow, see `06-windows-apps.md`)

Login screen (SDDM, D-38), lock screen and Plymouth use the Glassfort design.
