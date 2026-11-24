# glassfort-settings

All Glassfort system defaults: snapshots, boot menu, kernel hardening,
firewall, AppArmor, zram and the Copilot key. Specification:
[`docs/02-system.md`](../../docs/02-system.md). Dependencies: D-32 in
[`docs/DECISIONS.md`](../../docs/DECISIONS.md).

## Requirements (Phase 1)

An Arch Linux install with **UEFI**, a **Btrfs** root and **Limine** as
bootloader – for example archinstall with the default Btrfs subvolume layout
and the Limine bootloader. On other setups the package still installs, but
`glassfort-setup` skips the steps it cannot do and says why. It never
partitions, formats or replaces a bootloader.

## Files

| File | Installed to | Purpose |
|---|---|---|
| `90-glassfort-hardening.conf` | `/usr/lib/sysctl.d/` | Hardened sysctl values, each one documented in the file |
| `91-glassfort-zram.conf` | `/usr/lib/sysctl.d/` | VM tuning for swap on zram |
| `zram-generator.conf` | `/usr/lib/systemd/` | zram swap: half of RAM, max. 8 GiB, zstd |
| `glassfort-root` | `/usr/share/snapper/config-templates/` | Snapper template for `/`: no timeline, about 20 pre/post pairs, 10 pinned |
| `50-glassfort.conf` | `/etc/limine-entry-tool.d/` | Limine: BLAKE2B verification, entry order, keep `BOOTX64.EFI` in sync (D-08) |
| `glassfort-public.xml`, `glassfort-private.xml` | `/usr/lib/firewalld/zones/` | "Public network" (default, nothing incoming) and "Private network" (discovery, KDE Connect, sharing) |
| `glassfort.conf` | `/etc/keyd/` | Copilot key (`Meta+Shift+F23`) → `Meta+A` (assistant) |
| `50-glassfort.preset` | `/usr/lib/systemd/system-preset/` | Services enabled by Glassfort |
| `glassfort-setup` | `/usr/bin/` | Applies the defaults that cannot be plain files (see below) |

## glassfort-setup

Runs automatically after install and upgrade; safe to run again
(`sudo glassfort-setup`). `glassfort-setup --check` only shows what it would
change. Steps:

1. **Snapper:** create the `root` config from the `glassfort-root` template.
   With a separate `@snapshots` subvolume at `/.snapshots` it uses the
   standard unmount → create-config → remount procedure.
2. **Kernel command line:** add `lsm=landlock,lockdown,yama,integrity,apparmor,bpf`
   to the command line that limine-entry-tool uses (`/etc/default/limine`,
   else `/etc/kernel/cmdline`, else a new `/etc/kernel/cmdline` derived from
   the running system – never from a snapshot).
3. **initramfs:** add `btrfs-overlayfs` (or `sd-btrfs-overlayfs` for
   systemd-based initramfs) after `filesystems`, so read-only snapshots boot.
4. **Firewall:** set `glassfort-public` as default zone.
5. **Services:** enable the units listed in every
   `/usr/lib/systemd/system-preset/50-glassfort*.preset` (this package's and,
   for example, glassfort-desktop's). A unit that cannot be enabled (such as
   SDDM while another login manager is active) gives a warning.
6. **Boot menu:** run `limine-update` if anything changed.

## Why some defaults live elsewhere

- `/etc/limine-snapper-sync.conf` has no drop-in directory, so Glassfort's
  snapshot boot-menu defaults are set in the carried
  [`limine-snapper-sync`](../third-party/limine-snapper-sync/) package.
- `/etc/pacman.conf` belongs to pacman. Adding `[glassfort]` before `[core]`
  is part of the repository setup (`glassfort-mirrorlist`, later the
  installer). Arch's default `SigLevel = Required DatabaseOptional` already
  matches the spec.

## Build

```sh
cd components/glassfort-settings
extra-x86_64-build      # clean chroot (devtools)
```
