# ISO

The archiso profile of the Glassfort live and installation medium
(Phase 2, [`docs/09-roadmap.md`](../docs/09-roadmap.md)), based on archiso's
`releng` profile (GPL-3.0-or-later). Built ISOs are never committed.

- **UEFI only** (Glassfort needs UEFI); the medium boots with systemd-boot,
  the installed system gets Limine.
- **Live session:** user `glassfort` (no password, sudo without password),
  logged in automatically by SDDM into the Glassfort desktop. The home
  directory is created from `/etc/skel` at boot (Glassfort defaults).
- **Packages** (`packages.x86_64`): `glassfort-desktop` and the tools the
  installer needs (archinstall, partitioning, LUKS, Limine). The Glassfort
  packages come from a local `[glassfort]` repository built in the same CI
  run (`pacman.conf`: `@GLASSFORT_REPO@`, unsigned until the real key
  exists, D-26).
- Snapshot services are masked in the live session (no Btrfs there).
- Boot entries: normal (`quiet`) and safe graphics (`nomodeset`).

## Build

CI builds the ISO for every push to `main` (job "Build ISO", artifact `iso`,
kept 3 days). Locally, as root in an archlinux container only:

```sh
scripts/build-iso <repo-root> <dir-with-packages> <output-dir>
```

The installer (`glassfort-installer`) follows in Phase 2.
