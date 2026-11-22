# 02 – System: filesystem, snapshots, boot, security, drivers, updates

## Partitioning (installer default)

| Partition | Size | Type | Notes |
|---|---|---|---|
| ESP | 4 GiB | FAT32, mounted at `/boot` | Large because Limine snapshot entries need kernels/initramfs on the ESP |
| System | rest | LUKS2 → Btrfs | Full-disk encryption by default |

Swap: zram (no swap partition). Hibernation is not supported in v1.

## Btrfs subvolumes

| Subvolume | Mount point | Snapshotted | Notes |
|---|---|---|---|
| `@` | `/` | yes | System |
| `@home` | `/home` | separate config, manual/timeline only | User data |
| `@var_log` | `/var/log` | no | Logs survive rollbacks |
| `@var_cache_pacman_pkg` | `/var/cache/pacman/pkg` | no | Package cache |
| `@snapshots` | `/.snapshots` | – | Snapper storage |
| `@vm` | `/var/lib/glassfort/vm` | no | Windows VM images; `chattr +C` (no copy-on-write) |

Mount options: `compress=zstd:1,noatime`.

## Snapshots

- **snapper** with a `root` config for `@`.
- **snap-pac** creates a pre/post snapshot pair for every pacman transaction.
- Timeline snapshots for `@` are off; cleanup by number (keep the last ~20 pre/post pairs, plus important ones).
- **limine-snapper-sync** adds snapshots to the boot menu automatically.
  - Limit boot entries (`MAX_SNAPSHOT_ENTRIES`, start with 8) and keep ESP usage well below its limit (`LIMIT_USAGE_PERCENT`).
  - Pinning: "known good" states are marked with `snapper modify --important=yes <id>`. Snapper keeps them separately from normal cleanup (`NUMBER_LIMIT_IMPORTANT`). limine-snapper-sync (1.33) has no option to keep pinned snapshots in the boot menu beyond `MAX_SNAPSHOT_ENTRIES`; the Time Machine can always restore them.
- Boot menu labels are human-readable, e.g. `Before update · 2026-11-19 14:30`.
- After booting into a snapshot, a banner says: *"You are running an earlier state. Restore it permanently?"* → restore via the Time Machine.
- Limitation to communicate honestly: snapshots repair a broken system; they do not undo data that has left the machine.

### Time Machine (System Settings module)

- Timeline of snapshots (date, description, which update, pinned or not)
- Actions: *Restore this state* (with confirmation), *Pin*, *Show changes* (package diff between snapshots)
- Talks to snapper's D-Bus service; restore actions go through the helper and polkit.

## Boot: Limine

- Limine with `limine-mkinitcpio-hook` and `limine-snapper-sync` (both AUR-only → carried in `components/third-party/`; verify upstream and licence when packaging).
- Entries: default kernel, LTS fallback, snapshots (see `01-architecture.md`).
- Plan B if Limine fails the Secure Boot tests: GRUB + grub-btrfs.

### Secure Boot with Limine

1. `sbctl create-keys`, then `sbctl enroll-keys --microsoft` (Microsoft keys kept for firmware option ROMs and dual-boot).
2. In `/etc/default/limine`: `ENABLE_ENROLL_LIMINE_CONFIG=yes`.
3. `limine-enroll-config` embeds the config checksum into the Limine EFI binary and signs it via sbctl; then `limine-update`.
4. **Do not sign kernels.** Limine verifies kernels and initramfs via BLAKE2B hashes in `limine.conf`.
5. Assets referenced from `limine.conf` (e.g. the splash image) need a hash too: `wallpaper: boot():/glassfort-splash.png#<b2sum>`.
6. **Known pitfall:** firmware that boots the fallback path `EFI/BOOT/BOOTX64.EFI` instead of `limine_x64.efi` panics with "no config checksum enrolled". Our hook must always copy, enroll and sign **both** binaries after every config change.
7. Recovery: if Limine panics because of a checksum mismatch, disable Secure Boot in firmware, run `limine-enroll-config && limine-update`, re-enable.

The installer offers Secure Boot setup only when the firmware is in setup mode; otherwise it shows a short guide.

## Encryption

- LUKS2 for the system partition by default (Argon2id).
- Optional TPM2 unlock via `systemd-cryptenroll --tpm2-device=auto` (PCR 7), always keeping the passphrase as fallback. The recovery key is shown once during installation.

## Hardening

| Measure | Implementation |
|---|---|
| Firewall | **firewalld**; incoming connections blocked by default. Zones per network via NetworkManager: on first connection, ask *"Private network (home/work)"* or *"Public network"* like Windows. Its D-Bus API is used by the assistant helper. |
| Mandatory access control | AppArmor enabled (kernel parameter `lsm=landlock,lockdown,yama,integrity,apparmor,bpf`) |
| Kernel | Hardened sysctl defaults (e.g. `kernel.kptr_restrict=2`, `kernel.dmesg_restrict=1`, `kernel.unprivileged_bpf_disabled=1`, `net.ipv4.conf.all.rp_filter=1`); document every value in `glassfort-settings` |
| Apps | Flatpak + Flatseal for sandboxed apps |
| Packages | Only signed packages (`SigLevel = Required DatabaseOptional`); AUR not enabled |
| Secrets | KDE Wallet unlocked at login via PAM |

## Graphics drivers

- Intel/AMD: Mesa (default).
- NVIDIA Turing and newer: `nvidia-open` (Arch default since driver 590).
- NVIDIA Pascal (GTX 10xx) and older: the 590 driver dropped support; use `nvidia-580xx-dkms`, carried in `[glassfort]` because it is AUR-only.
- The installer detects the GPU generation (PCI IDs) and installs the right driver. Hybrid laptops get PRIME render offload configured.

## Update flow (update app)

1. Fetch Arch news; if a news item since the last update mentions manual intervention, show it in plain language and require confirmation.
2. Check free space on the ESP and the system partition.
3. Create a pinned-candidate snapshot (snap-pac creates the pre snapshot automatically; the update app adds a description).
4. Run `pacman -Syu` (never `-Sy` alone).
5. Summarise in plain English: number of packages, notable ones (kernel, Plasma, Mesa), whether a restart is recommended.
6. On next boot: if the session started successfully, mark the post snapshot as "known good" (pin it and unpin older ones beyond the limit).
7. If something is wrong: *"Go back to the state from 14:30?"* → Time Machine restore.

Flatpak updates run separately (Discover handles Flatpaks only; Discover must not manage system packages).
