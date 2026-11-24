# Progress

This file is the single source of truth for "what is happening right now".
Claude Code updates it **before** changing any other file (see `CLAUDE.md` §2).

## Current task

- **Status:** in progress  <!-- idle | in progress | blocked -->
- **Task:** Phase 1 – foundation on plain Arch (now: glassfort-theme)
- **Roadmap item:** Phase 1
- **Started:** 2026-11-22T22:25:00+01:00 (sub-task started 2026-11-23T22:36:57+01:00)
- **Plan:**
  - [x] Decisions from maintainer: dependencies of glassfort-settings, repo hosting + signing key, palette/fonts
  - [x] third-party: limine-mkinitcpio-hook, limine-snapper-sync (review upstream + licence, package)
  - [x] glassfort-settings: sysctl, zram, snapper root config, snap-pac, limine defaults, firewalld, AppArmor, keyd, pacman.conf
  - [x] CI: third-party packages cached, so only own components are rebuilt (verified in run 45074478611)
  - [x] glassfort-mirrorlist (file:// server for Phase 1, D-33) + docs for adding [glassfort] to pacman.conf
  - [x] repo/publish: sign packages and build a local repo database (repo-add --sign)
  - [ ] glassfort-keyring – deferred by maintainer until the real key exists (D-26); VM tests use repo/vm-test-key
  - [x] glassfort-theme (VM check of the live look pending, see VM test)
    - [x] record decisions D-34 (theme dependencies), D-35 (placeholder wallpapers)
    - [x] package skeleton + colour schemes GlassfortLight/GlassfortDark + kitty themes
    - [x] Kvantum theme (generated from the colour schemes by generate)
    - [x] GTK theme Glassfort (adw-gtk3 + palette, generated) and default settings.ini
    - [x] wallpapers: vector recreation of the maintainer's draft, light + dark, no logo (PNG rendered at build time)
    - [x] Global Theme: org.glassfort.desktop + org.glassfort.dark.desktop, /etc/xdg defaults, auto light/dark
  - [ ] glassfort-branding (sub-task started 2026-11-24; maintainer decided: logo = their draft in images/, optimised + redrawn as vector):
    - [x] docs: D-24 Decided, docs/03 logo section
    - [x] logo SVGs: symbol (light/dark bg), app icon, flat monochrome (dark/white), lockups (wordmark as Inter Semibold outlines)
    - [x] package glassfort-branding (hicolor icon, /usr/share/glassfort/branding)
    - [ ] later: Plymouth, Limine splash, login/lock screen (with logo wallpapers)
  - [ ] glassfort-shell (sub-task started 2026-11-24; D-36: own QML plasmoids from the start):
    - [x] record D-36
    - [x] package skeleton + start menu plasmoid org.glassfort.startmenu (search, pinned grid, all apps, recent files, power menu, Super) + scripts/plasmoid-screenshot
    - [x] start menu: pin/unpin context menu (drag to reorder later)
    - [x] dock plasmoid org.glassfort.dock (jump lists + drag to reorder later):
      - [x] research org.kde.taskmanager TasksModel (jump list backend is applet-internal, not importable)
      - [x] dock: pinned + running icons, running indicator, click focuses/minimises/cycles, middle-click new instance
      - [x] context menu: new window, pin/unpin, close (jump lists later)
      - [x] hover window previews (live PipeWire thumbnails, click to switch, close button)
    - [ ] control center plasmoid org.glassfort.controlcenter (Wi-Fi, Bluetooth, volume, brightness, night light, dark mode, DND, screen recording)
    - [ ] panel layout (top bar + floating dock) in the global themes; Super opens the start menu
    - [ ] shortcut overlay (hold Super) – may move to a later step
  - [ ] meta package glassfort-desktop
  - [ ] VM test: plain Arch → pacman -S glassfort-desktop → break update → roll back from boot menu
- **Files expected to change:** components/glassfort-shell/*, docs/03-desktop-design.md, docs/DECISIONS.md, PROGRESS.md
- **Next step if interrupted:** Control center plasmoid org.glassfort.controlcenter (study plasma-workspace applets: networkmanagement is in plasma-nm, bluetooth in bluedevil, volume in plasma-pa, brightness/night light in powerdevil/plasma-workspace). images/*.jpg stay untracked (reference only).
- **Blocked because:** –

## Unpushed commits

<!-- Hash + summary of commits that could not be pushed. Cleared after a successful push. -->
- none

## Log (newest first)

| Date | Commit | Summary |
|---|---|---|
| 2026-11-24 | – | glassfort-shell: live window previews on dock hover |
| 2026-11-24 | – | glassfort-shell: dock plasmoid (pinned + running apps, Windows-like clicks, context menu) |
| 2026-11-24 | – | glassfort-shell: pin/unpin apps in the start menu, retry-safe seeding of pinned apps |
| 2026-11-24 | – | glassfort-shell: flat plasmoid sources (fixes namcap "File referenced in $startdir") |
| 2026-11-24 | – | glassfort-shell: start menu plasmoid; scripts/plasmoid-screenshot for headless widget screenshots |
| 2026-11-24 | – | Record maintainer decision D-36 (own shell widgets from the start) |
| 2026-11-24 | – | glassfort-theme: global themes Glassfort and Glassfort Dark with automatic light/dark switch |
| 2026-11-24 | – | glassfort-theme: desktop wallpaper (light + dark) after the maintainer's draft |
| 2026-11-24 | – | Add glassfort-branding: logo redrawn as vector (symbol, app icon, monochrome, lockups) |
| 2026-11-24 | – | Record maintainer decision D-24 (logo = maintainer's draft, optimised vector redraw) |
| 2026-11-24 | – | glassfort-theme: GTK theme Glassfort (adw-gtk3 with the palette) and default GTK settings |
| 2026-11-24 | – | glassfort-theme: move the theme generator to the package root |
| 2026-11-24 | – | glassfort-theme: Kvantum themes (light + dark) generated from the colour schemes |
| 2026-11-23 | – | glassfort-theme: Plasma colour schemes and kitty themes |
| 2026-11-23 | – | Record maintainer decisions D-34 (theme dependencies), D-35 (placeholder wallpapers); keyring deferred |
| 2026-11-23 | – | Add repo/publish and repo/vm-test-key (sign, local repo database, throwaway VM key) |
| 2026-11-23 | – | Add glassfort-mirrorlist (local file:// repository for Phase 1) |
| 2026-11-22 | – | glassfort-settings: system defaults and glassfort-setup |
| 2026-11-22 | – | Package limine-mkinitcpio-hook and limine-snapper-sync (reviewed, patched) |
| 2026-11-22 | – | Record maintainer decisions D-22, D-23, D-26, D-32, D-33 |
| 2026-11-22 | – | Phase 0 complete: CI builds glassfort-settings in a clean chroot (fixes for keyring, machine ID, systemd container) |
| 2026-11-22 | – | Add CI skeleton with lint and clean-chroot package build |
| 2026-11-22 | – | Add empty glassfort-settings package |
| 2026-11-22 | – | Add repository layout skeleton and link checker |
| 2026-11-22 | – | Add contributing guide, security policy and code of conduct |
| 2026-11-22 | – | Add licences and trademark policy |
| 2026-11-22 | – | Imported project specification into repository root |
| 2026-11-22 | – | Project specification created (`CLAUDE.md`, `PROGRESS.md`, `docs/`) |
