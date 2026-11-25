# 07 – Testing

Test where distros typically break (NVIDIA, scaling, Secure Boot), automatically in VMs and manually on real hardware.

## Automated (CI)

| Level | What |
|---|---|
| Unit tests | Rust helper (`cargo test`), Python assistant (`pytest`), registry schema validation |
| Lint | shellcheck, namcap, clippy, ruff, qmllint (`scripts/check-qml` in an Arch container with the Plasma QML modules; known causes from Plasma types qmllint cannot know are allowlisted as patterns in `scripts/qmllint-allowed.txt`) |
| Package builds | Every changed package in a clean chroot |
| Install tests | ISO installed in QEMU/KVM with OVMF (UEFI) + swtpm (TPM 2.0); later with openQA |
| Rollback tests | In a VM: break the system on purpose (e.g. remove a critical package), boot a snapshot, restore, verify. Phase 1 version: `tests/vm/phase1` (plain Arch → `pacman -S glassfort-desktop` → broken update → snapshot from the Limine menu → restore), run locally for now |
| Secure Boot tests | OVMF with enrolled custom keys: Limine boots, checksum enrollment works, fallback path `BOOTX64.EFI` works |
| Assistant security | Prompt-injection test suite; fuzzing of the helper D-Bus interface |

## Local checks

| Check | How |
|---|---|
| Plasmoid screenshots | `scripts/plasmoid-screenshot OUT.png PLASMOID_DIR`: runs the widget in an invisible KWin (`kwin_wayland --virtual`) on a private D-Bus session with empty config and data dirs and takes a screenshot. Needs a Plasma host (kwin, plasma-sdk, spectacle). |
| Session screenshot | `scripts/session-screenshot OUT.png`: builds the desktop components with makepkg into a temporary root and screenshots a complete Plasma session (invisible KWin + plasmashell, empty config) that uses them. Shows global theme, panel layout and widgets as on a new user's first login. |

## Real hardware matrix

| Device | Tests |
|---|---|
| Laptop with Intel/AMD graphics, HiDPI 125–150 % | Default case, battery, suspend, fingerprint |
| Laptop with additional NVIDIA RTX | Hybrid graphics (PRIME offload), `nvidia-open` |
| Desktop with AMD graphics | Mesa reference, gaming |
| Desktop with NVIDIA RTX | NVIDIA on Wayland |
| Old NVIDIA GTX 10xx | Legacy driver path (`nvidia-580xx-dkms`), GPU detection |
| Two monitors: 4K at 150 % + 1080p at 100 %, different refresh rates | Fractional scaling, Windows Apps windows |
| 3–4 firmware vendors (Lenovo, Dell, Acer/Insyde, ASUS/MSI) | Secure Boot with Limine |
| Low-end PC: 8 GB RAM, 4 cores | Minimum requirements, Windows Apps check "possible" |

## Release checklist (per ISO)

- [ ] All CI checks green
- [ ] Install test (UEFI, Secure Boot on/off, TPM unlock on/off)
- [ ] Rollback test from boot menu and Time Machine
- [ ] LTS fallback boots
- [ ] Thunderbird / Microsoft 365 status checked (see `03-desktop-design.md`)
- [ ] Checksums and signatures published
