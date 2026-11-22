# Progress

This file is the single source of truth for "what is happening right now".
Claude Code updates it **before** changing any other file (see `CLAUDE.md` §2).

## Current task

- **Status:** in progress  <!-- idle | in progress | blocked -->
- **Task:** Phase 1 – foundation on plain Arch
- **Roadmap item:** Phase 1
- **Started:** 2026-11-22T22:25:00+01:00
- **Plan:**
  - [x] Decisions from maintainer: dependencies of glassfort-settings, repo hosting + signing key, palette/fonts
  - [x] third-party: limine-mkinitcpio-hook, limine-snapper-sync (review upstream + licence, package)
  - [ ] glassfort-settings: sysctl, zram, snapper root config, snap-pac, limine defaults, firewalld, AppArmor, keyd, pacman.conf
  - [ ] glassfort-keyring + glassfort-mirrorlist + repo/ scripts (build, sign, publish)
  - [ ] glassfort-theme + glassfort-branding
  - [ ] glassfort-shell (Start menu, taskbar/dock, control center)
  - [ ] meta package glassfort-desktop
  - [ ] VM test: plain Arch → pacman -S glassfort-desktop → break update → roll back from boot menu
- **Files expected to change:** components/*, repo/*, docs/DECISIONS.md, PROGRESS.md
- **Next step if interrupted:** Commit glassfort-settings content, then make CI build only changed packages
- **Blocked because:** –

## Unpushed commits

<!-- Hash + summary of commits that could not be pushed. Cleared after a successful push. -->
- none

## Log (newest first)

| Date | Commit | Summary |
|---|---|---|
| 2026-11-22 | – | Package limine-mkinitcpio-hook and limine-snapper-sync (reviewed, patched) |
| 2026-11-22 | – | Record maintainer decisions D-22, D-23, D-26, D-32, D-33 |
| 2026-11-22 | – | Phase 0 complete: CI builds glassfort-settings in a clean chroot (fixes for keyring, machine ID, systemd container) |
| 2026-11-22 | – | Add CI skeleton with lint and clean-chroot package build |
| 2026-11-22 | – | Add empty glassfort-settings package |
| 2026-11-22 | – | Add repository layout skeleton and link checker |
| 2026-11-22 | – | Add contributing guide, security policy and code of conduct |
| 2026-11-22 | – | Add licences and trademark policy |
| 2026-11-22 | – | Imported project specification into repository root |
| 2026-11-22 | – | Project specification created (`CLAUDE.md`, `PROGRESS.md`, `docs/`) |
