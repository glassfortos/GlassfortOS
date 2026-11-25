# ISO

The archiso profile of the Glassfort live and installation medium
(Phase 2, [`docs/09-roadmap.md`](../docs/09-roadmap.md)), based on archiso's
`releng` profile (GPL-3.0-or-later). Built ISOs are never committed.

- **UEFI only** (Glassfort needs UEFI); the medium boots with systemd-boot,
  the installed system gets Limine.
- **Live session:** user `glassfort` (no password, sudo without password),
  logged in automatically by SDDM into the Glassfort desktop. The home
  directory is created from `/etc/skel` at boot (Glassfort defaults).
- **Packages** (`packages.x86_64`): the dependencies of `glassfort-desktop`
  **without** `glassfort-settings` (`@GLASSFORT_DESKTOP@`, filled in by
  `scripts/build-iso` from the built package): the live system has no
  Btrfs, ESP or Limine, and glassfort-settings' Limine and snapper hooks
  fail there. Plus `glassfort-installer` and the tools it needs
  (archinstall, partitioning, LUKS, Limine). The Glassfort packages come
  from a local `[glassfort]` repository built in the same CI run
  (`pacman.conf`: `@GLASSFORT_REPO@`, unsigned until the real key exists,
  D-26).
- **Installer:** starts automatically in the live session
  (`/etc/xdg/autostart`). The `[glassfort]` repository is copied onto the
  medium (`/srv/glassfort/repo/x86_64`); installed systems get the full
  `glassfort-desktop` from there.
- Boot entries: normal (`quiet`) and safe graphics (`nomodeset`).
- Build-time pacman hooks (`airootfs/etc/pacman.d/hooks`, removed from
  the medium after the build, as in releng): enable the HTTPS mirrors with
  Arch's geo mirror first (archinstall syncs before it applies its own
  mirror settings) and generate the locales of the installer's languages
  (otherwise Qt falls back to "C").

## Build

CI builds the ISO for every push to `main` (job "Build ISO", artifact `iso`,
kept 3 days). Locally, as root in an archlinux container only:

```sh
scripts/build-iso <repo-root> <dir-with-packages> <output-dir>
```

The installer (`glassfort-installer`) follows in Phase 2.
