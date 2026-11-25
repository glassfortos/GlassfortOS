# VM tests

## Phase 1: plain Arch → Glassfort → broken update → rollback

The done criterion of roadmap Phase 1
([`docs/09-roadmap.md`](../../docs/09-roadmap.md)), automated in QEMU/KVM
with OVMF (UEFI):

```sh
tests/vm/phase1                 # packages from the latest green CI run
tests/vm/phase1 --packages out/ # or locally built packages
```

1. **Stage 1 (install):** boots the official Arch ISO (checksum verified)
   with `script=`, which runs [`guest/install.sh`](guest/install.sh) in the
   VM. It installs plain Arch the way archinstall does with Btrfs and
   Limine (4 GiB ESP at `/boot`, the subvolumes from
   [`docs/02-system.md`](../../docs/02-system.md)), builds a local
   `[glassfort]` repository from the packages, signed with a throwaway key
   that only exists in the VM (`repo/vm-test-key`, D-26), and runs
   `pacman -S glassfort-desktop`. For the test only, SDDM logs the test user
   in automatically.
2. **Stage 2 (system):** [`guest/glassfort-vmtest`](guest/glassfort-vmtest)
   runs on every boot and reports `GFTEST` lines on the serial console:
   - first boot: checks services, Plasma, snapper, AppArmor, the repository,
     the boot splash setup (plymouth hook, `splash`, theme) and the Limine
     snapshot entries; the host takes screenshots of the boot (splash) and
     the desktop; then a
     normal update and a broken one (`pacman -Rdd systemd`: the next normal
     boot has no init), reboot;
   - the normal boot fails (no init) – the kernel command line is realistic
     (no serial console, `quiet splash`), so the driver notices it by the
     agent staying silent (or "no usable init" if visible), then [`vmdriver.py`](vmdriver.py)
     resets the VM and, like a user, boots the snapshot taken *before* the
     broken update from the Limine menu (the newest snapshot is the "post"
     snapshot of the broken update and is broken too). Keys are sent once
     the menu is on screen; in Limine, Up/Down wrap around and Right/Enter
     only open directories;
   - booted from the snapshot: restore it with `limine-snapper-restore`
     (its dialog is answered with `r` and the defaults), which reboots;
   - normal boot again: systemd is back, the desktop runs.

The host only downloads the ISO, serves files on `127.0.0.1:8642` and reads
the serial console; nothing is installed or changed on the host. Not
covered here: LUKS (the passphrase prompt cannot be automated in this
setup), Secure Boot and TPM (Phase 2).

First green run: 2026-11-25, 15 checks ok; with the boot splash 18 (about 25 minutes, most of it
downloads).

Results go to `~/.cache/glassfort-vm/results/<time>/`: `phase1.log`,
`checks.txt`, serial logs per boot and screenshots. The VM uses 3 GiB RAM
(`--memory`) and a 40 GiB sparse disk; the ISO and the VM's downloads
take about 4 GB.

Needs: qemu, edk2-ovmf, libarchive (bsdtar), libisoburn (xorriso), curl,
python, imagemagick, github-cli.

## Live ISO: boot and screenshots

```sh
tests/vm/live-iso               # ISO from the newest green CI run on main
tests/vm/live-iso --iso FILE    # or a local ISO
```

Boots the Glassfort ISO (UEFI, 4 GiB RAM, an empty 60 GiB sparse disk as
installer target) and takes screenshots for four minutes: boot menu, live
desktop, the installer starting by itself. Results go to
`~/.cache/glassfort-vm/results/live-<time>/`. The ISO download is about
2.5 GB and is kept in the cache (checksum verified).

First run: 2026-11-25 – the live session reaches the Glassfort desktop and
the installer opens on its first screen after about 40 seconds.
