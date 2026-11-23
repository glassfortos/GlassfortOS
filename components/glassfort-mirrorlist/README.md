# glassfort-mirrorlist

Server list for the `[glassfort]` package repository, installed to
`/etc/pacman.d/glassfort-mirrorlist`. Specification:
[`docs/01-architecture.md`](../../docs/01-architecture.md).

## Phase 1: local repository

`[glassfort]` is not hosted publicly yet (D-33 in
[`docs/DECISIONS.md`](../../docs/DECISIONS.md)). The only server is
`file:///srv/glassfort/repo/$arch`, the default output directory of
[`repo/publish`](../../repo/).

## Adding the repository

`/etc/pacman.conf` belongs to pacman, so this package does not edit it.
Add the repository **above** `[core]` (the installer will do this later):

```ini
[glassfort]
Include = /etc/pacman.d/glassfort-mirrorlist
```

Arch's default `SigLevel = Required DatabaseOptional` applies: packages
must be signed by a key in pacman's keyring (`glassfort-keyring`, or in VM
tests the throwaway key, see [`repo/README.md`](../../repo/README.md)).

## Build

```sh
cd components/glassfort-mirrorlist
extra-x86_64-build      # clean chroot (devtools)
```
