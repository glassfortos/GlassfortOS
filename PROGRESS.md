# Progress

This file is the single source of truth for "what is happening right now".
Claude Code updates it **before** changing any other file (see `CLAUDE.md` §2).

## Current task

- **Status:** in progress  <!-- idle | in progress | blocked -->
- **Task:** Phase 1 – foundation on plain Arch (now: glassfort-mirrorlist + repo/ scripts)
- **Roadmap item:** Phase 1
- **Started:** 2026-11-22T22:25:00+01:00 (sub-task started 2026-11-23T22:28:56+01:00)
- **Plan:**
  - [x] Decisions from maintainer: dependencies of glassfort-settings, repo hosting + signing key, palette/fonts
  - [x] third-party: limine-mkinitcpio-hook, limine-snapper-sync (review upstream + licence, package)
  - [x] glassfort-settings: sysctl, zram, snapper root config, snap-pac, limine defaults, firewalld, AppArmor, keyd, pacman.conf
  - [x] CI: third-party packages cached, so only own components are rebuilt (verified in run 45074478611)
  - [x] glassfort-mirrorlist (file:// server for Phase 1, D-33) + docs for adding [glassfort] to pacman.conf
  - [x] repo/publish: sign packages and build a local repo database (repo-add --sign)
  - [ ] glassfort-keyring (needs maintainer decision: real key not yet created, D-26)
  - [ ] glassfort-theme + glassfort-branding
  - [ ] glassfort-shell (Start menu, taskbar/dock, control center)
  - [ ] meta package glassfort-desktop
  - [ ] VM test: plain Arch → pacman -S glassfort-desktop → break update → roll back from boot menu
- **Files expected to change:** components/glassfort-mirrorlist/*, repo/*, docs/01-architecture.md, components/glassfort-settings/README.md, PROGRESS.md
- **Next step if interrupted:** Ask maintainer how to handle glassfort-keyring before the real key exists (D-26)
- **Blocked because:** –

## Unpushed commits

<!-- Hash + summary of commits that could not be pushed. Cleared after a successful push. -->
- none

## Log (newest first)

| Date | Commit | Summary |
|---|---|---|
| 2026-11-23 | – | Add repo/publish and repo/vm-test-key (sign, local repo database, throwaway VM key) |
| 2026-11-23 | – | Add glassfort-mirrorlist (local file:// repository for Phase 1) |
| 2026-11-22 | – | glassfort-settings: system defaults and glassfort-setup |
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
