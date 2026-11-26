# 00 – Overview

## One sentence

Glassfort is an Arch-based Linux distribution with Windows-style usability, a macOS-inspired glass design, security by default and bootable snapshots that make it practically unbreakable. Windows apps can run seamlessly through an optional VM.

**Slogan:** *Beautiful as glass. Strong as a fortress.*

## Mission statement

Windows UX with the much-loved design language of macOS. Open source, secure by default and unbreakable. Still depending on Microsoft software is no reason not to switch: the apps you need run seamlessly alongside.

## Target users

1. **Windows switchers** who want a familiar workflow (taskbar, Start menu, Windows shortcuts) and a polished look, without tinkering.
2. **People who value a beautiful, stable system** and never want to repair a broken update.

Not the primary target: users who want to configure everything themselves (they have Arch) or a keyboard-only tiling workflow.

## The six promises

| Promise | Meaning |
|---|---|
| **Familiar** | Works like Windows: taskbar, Start menu, snap layouts, the same shortcuts |
| **Beautiful** | Consistent glass design inspired by macOS; one accent colour across everything |
| **Unbreakable** | Every system change creates a bootable snapshot; a fallback kernel is always installed |
| **Secure** | Full-disk encryption, Secure Boot, firewall and AppArmor out of the box |
| **No excuses** | Windows apps run optionally in a VM, as normal windows |
| **Open** | Open source; no bundled proprietary images or keys |

## Positioning

| Distro | Focus | Interaction |
|---|---|---|
| Omarchy | Arch + Hyprland for developers | Keyboard-driven, tiling |
| CachyOS | Performance, KDE by default | Plasma defaults |
| **Glassfort** | Curated Plasma, snapshots, AI assistant, Windows apps | Windows UX, floating windows, macOS-like look |

## Design principles

1. **Secure by default.** Safe settings ship enabled; unsafe options need an explicit choice.
2. **Never leave the user with a broken system.** Snapshot before change, fallback kernel, one-click rollback.
3. **Curated, not endless.** Fewer, better options. Hide what most users never need.
4. **Familiar first.** When in doubt, behave like Windows; look like macOS.
5. **Local first, opt-in AI.** The assistant is off by default; local models are preferred.
6. **Arch stays Arch.** Use upstream Arch packages directly; add our own packages on top instead of forking.

## Glossary

| Term | Meaning |
|---|---|
| `[glassfort]` | Our signed pacman repository with all Glassfort packages |
| Restore Points | Snapshot timeline and restore module in System Settings (package `glassfort-timemachine`; not called "Time Machine" in the UI, an Apple trademark, D-45) |
| Update app | Glassfort's system update tool (news check → snapshot → upgrade) |
| Assistant | Optional AI chat that can operate the system through typed tools |
| Helper | Root-privileged service without AI that validates and executes assistant actions |
| Settings registry | TOML files describing every setting the assistant may change |
| Windows Apps | Optional module running Windows 11 in a VM with apps as native windows |
