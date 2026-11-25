#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Phase 1 VM test, stage 1: runs on the Arch ISO inside the test VM (started
# by tests/vm/phase1 through archiso's script= parameter) and ERASES /dev/vda.
# Never run it anywhere else; it refuses to run outside a VM.
#
# 1. Plain Arch like archinstall would set it up: UEFI, 4 GiB ESP at /boot,
#    Btrfs root with the subvolumes from docs/02-system.md, Limine.
#    (No LUKS: the passphrase prompt at boot cannot be automated here.)
# 2. Local [glassfort] repository: packages from the host, signed inside the
#    VM with the throwaway key (repo/vm-test-key, D-26).
# 3. pacman -S glassfort-desktop, the vmtest agent for the next boots,
#    SDDM autologin for the test user. Then power off.
#
# Progress lines start with "GFTEST" on the serial console.

set -euo pipefail

host=${GLASSFORT_HOST:-http://10.0.2.2:8642}
disk=/dev/vda
user=glassfort

say() { printf 'GFTEST %s\n' "$*" | tee /dev/ttyS0; }
fail() {
    say "FAIL install: $*"
    sleep 2
    poweroff
    exit 1
}
trap 'fail "line $LINENO: $BASH_COMMAND"' ERR

systemd-detect-virt --quiet --vm || {
    echo "Refusing to run outside a virtual machine." >&2
    exit 1
}
[[ -b $disk ]] || fail "$disk not found"

say "stage1 start"

# --- Network and keyring ------------------------------------------------------
for _ in $(seq 60); do
    curl -fsS "$host/ok" >/dev/null 2>&1 && break
    sleep 2
done
curl -fsS "$host/ok" >/dev/null || fail "host HTTP server not reachable"
timedatectl set-ntp true || true
# The ISO initialises its keyring at boot; wait for it.
systemctl is-active --quiet pacman-init.service || systemctl start pacman-init.service

# Several mirrors, so one stalling mirror does not break the test (pacstrap
# copies this list into the installed system).
cat >/etc/pacman.d/mirrorlist <<'EOF'
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://ftp.fau.de/archlinux/$repo/os/$arch
Server = https://mirror.netcologne.de/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://fastly.mirror.pkgbuild.com/$repo/os/$arch
EOF

# Retry a command up to three times (downloads can stall); already
# downloaded packages stay in pacman's cache between attempts.
retry() {
    local n
    for n in 1 2 3; do
        "$@" && return 0
        say "attempt $n failed: $*"
        sleep 10
    done
    return 1
}

# --- Disk -------------------------------------------------------------------------
say "partitioning $disk"
sgdisk --zap-all "$disk"
sgdisk -n1:0:+4G -t1:ef00 -c1:ESP -n2:0:0 -t2:8304 -c2:system "$disk"
partprobe "$disk"
sleep 2
mkfs.fat -F 32 -n ESP "${disk}1"
mkfs.btrfs -f -L glassfort "${disk}2"

mount "${disk}2" /mnt
for sv in @ @home @var_log @var_cache_pacman_pkg @snapshots; do
    btrfs subvolume create "/mnt/$sv"
done
umount /mnt
opts=compress=zstd,noatime
mount -o "$opts,subvol=@" "${disk}2" /mnt
mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg,.snapshots}
mount -o "$opts,subvol=@home" "${disk}2" /mnt/home
mount -o "$opts,subvol=@var_log" "${disk}2" /mnt/var/log
mount -o "$opts,subvol=@var_cache_pacman_pkg" "${disk}2" /mnt/var/cache/pacman/pkg
mount -o "$opts,subvol=@snapshots" "${disk}2" /mnt/.snapshots
mount -o fmask=0077,dmask=0077 "${disk}1" /mnt/boot

# --- Plain Arch ---------------------------------------------------------------------
say "pacstrap"
retry pacstrap -K /mnt base linux linux-firmware btrfs-progs limine sudo nano
genfstab -U /mnt >>/mnt/etc/fstab

arch-chroot /mnt /bin/bash -e <<EOF
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 >/etc/locale.conf
echo KEYMAP=de-latin1 >/etc/vconsole.conf
echo glassfort-vm >/etc/hostname
useradd -m -G wheel -s /bin/bash $user
echo "$user:$user" | chpasswd
echo "root:root" | chpasswd
echo '%wheel ALL=(ALL:ALL) ALL' >/etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel
EOF

# Limine the way archinstall installs it: removable-path EFI binary and a
# limine.conf with one entry for the installed kernel.
say "limine"
mkdir -p /mnt/boot/EFI/BOOT
cp /mnt/usr/share/limine/BOOTX64.EFI /mnt/boot/EFI/BOOT/BOOTX64.EFI
root_uuid=$(blkid -s UUID -o value "${disk}2")
cat >/mnt/boot/limine.conf <<EOF
timeout: 5
serial: yes

/Arch Linux (linux)
    protocol: linux
    path: boot():/vmlinuz-linux
    cmdline: root=UUID=$root_uuid rw rootflags=subvol=@ console=tty0 console=ttyS0,115200
    module_path: boot():/initramfs-linux.img
EOF

# --- Local [glassfort] repository ----------------------------------------------------
say "glassfort repository"
mkdir -p /mnt/root/glassfort/pkgs /mnt/root/glassfort/repo
curl -fsS "$host/pkgs/index" -o /tmp/pkg-index
while read -r f; do
    [[ -n $f ]] && curl -fsS "$host/pkgs/$f" -o "/mnt/root/glassfort/pkgs/$f"
done </tmp/pkg-index
for f in publish vm-test-key; do
    curl -fsS "$host/repo/$f" -o "/mnt/root/glassfort/repo/$f"
    chmod +x "/mnt/root/glassfort/repo/$f"
done
curl -fsS "$host/guest/glassfort-vmtest" -o /mnt/usr/local/bin/glassfort-vmtest
chmod +x /mnt/usr/local/bin/glassfort-vmtest
curl -fsS "$host/guest/glassfort-vmtest.service" -o /mnt/etc/systemd/system/glassfort-vmtest.service

arch-chroot /mnt /bin/bash -e <<'EOF' 2>&1 | tee /dev/ttyS0
cd /root/glassfort
repo/vm-test-key
GNUPGHOME=/var/lib/glassfort/vm-test-gnupg repo/publish pkgs/*.pkg.tar.zst
pacman -U --noconfirm /srv/glassfort/repo/x86_64/glassfort-mirrorlist-*.pkg.tar.zst
# [glassfort] above [core], as glassfort-mirrorlist's README says.
sed -i 's/^\[core\]/[glassfort]\nInclude = \/etc\/pacman.d\/glassfort-mirrorlist\n\n[core]/' /etc/pacman.conf
pacman -Syu --noconfirm
EOF

# --- Glassfort ------------------------------------------------------------------------
say "pacman -S glassfort-desktop"
# Full output also goes to the serial console, so a failure is visible in
# the host's log.
install_desktop() {
    arch-chroot /mnt pacman -S --noconfirm glassfort-desktop 2>&1 | tee -a /mnt/root/glassfort/install.log >/dev/ttyS0
}
retry install_desktop
# glassfort-setup ran from the package's install script inside the chroot;
# run it again to log its full report.
arch-chroot /mnt glassfort-setup 2>&1 | tee -a /mnt/root/glassfort/install.log >/dev/ttyS0

# Test only: log the test user in automatically, run the agent on every boot.
mkdir -p /mnt/etc/sddm.conf.d
cat >/mnt/etc/sddm.conf.d/zz-vmtest-autologin.conf <<EOF
[Autologin]
User=$user
Session=plasma
EOF
arch-chroot /mnt systemctl enable glassfort-vmtest.service

say "stage1 done"
sync
umount -R /mnt
poweroff
