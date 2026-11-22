# 06 – Windows Apps (optional module)

Windows 11 runs invisibly in a VM; individual Windows programs appear as normal windows on the Glassfort desktop. The module is **optional** because it needs significant resources.

**We never ship a Windows ISO or product key.** The ISO is downloaded directly from Microsoft during setup; the user brings their own licence. Everything is documented.

## Edition

- Default: **Windows 11 Pro** (dockur version `11`), debloated through our own unattended answer file.
- Windows 11 LTSC only for organisations with a matching volume/IoT licence: private users cannot buy LTSC, and the freely downloadable LTSC image is a 90-day evaluation that cannot be activated with a key.
- Never Tiny10/Tiny11 or other modified images.
- Windows 10 Home/Pro is out of support since 2025-10-14 and is not offered.

## Stack

| Part | Choice | Why |
|---|---|---|
| VM base | dockur/windows | Automatic download and unattended installation |
| Container runtime | Podman | Membership in the docker group is effectively root |
| App windows | FreeRDP + RemoteApp | Individual windows, like WinApps/WinBoat |
| UI | Own System Settings module + tray icon (QML/Kirigami) | Lighter than Electron, matches our look |

## User flow

1. System Settings → *Windows Apps* → hardware check
2. Optional licence key
3. Installation with progress bar; honest duration (30–60 minutes)
4. Choose apps → they appear in the Start menu with their icons

## Hardware check

| Check | Recommended | Possible | Not offered |
|---|---|---|---|
| Virtualisation (`/dev/kvm`) | present | – | missing → hint: enable VT-x/AMD-V in firmware |
| RAM | ≥ 16 GB | 8–16 GB | < 8 GB |
| CPU cores | ≥ 6 | 4 | < 4 |
| Free disk space | ≥ 80 GB | 64 GB | < 64 GB |

VM size adapts to the hardware (dockur default without tuning: 2 cores, 4 GB RAM).

## Integration

- Auto-pause after 5 minutes without an open Windows app (frees CPU); full shutdown after a longer idle time (frees RAM).
- Tray icon: status (running / paused / off), RAM usage, *Open Windows desktop*.
- Dolphin context menu: *Open with → Word (Windows)*.
- Assistant: *"Install Office in Windows"* via winget inside the VM, with the same permission levels.

## Security

- Share only `~/Windows` with the VM, never the whole home directory (protects Linux files from Windows ransomware). More folders only on explicit request.
- RDP bound to `127.0.0.1` only.
- Replace dockur's default credentials: random password generated at setup, stored in KDE Wallet.
- Windows Defender and Windows Update stay on.

## Storage

- VM images in subvolume `@vm` (`/var/lib/glassfort/vm`), excluded from snapper, copy-on-write disabled (`chattr +C`).
- Separate VM snapshot before Windows feature updates, independent of system snapshots.

## Licensing documentation (rules)

- Short FAQ in the setup plus a docs page with "not legal advice" and links to Microsoft's licensing pages.
- State clearly: Windows needs a valid licence; Glassfort ships neither ISO nor key.
- Legal paths: buy a Windows 11 Pro key; use an existing transferable retail licence; organisations use their volume licence (then LTSC is possible).
- OEM keys (sticker or firmware) are tied to the original device – do not promise they work; point to Microsoft's terms.
- Without activation Windows runs with restrictions (watermark, personalisation locked) – mention neutrally, never recommend.
- **Hard rule:** no links to activation tools or KMS tricks in docs, forum or assistant.

## Limitations (communicate honestly)

- No GPU acceleration over RDP: good for Office, Adobe and business software; not for games, anti-cheat or heavy 3D.
- Scaling and multi-monitor with RemoteApp need dedicated test time.
