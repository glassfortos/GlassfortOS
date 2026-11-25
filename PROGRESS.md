# Progress

This file is the single source of truth for "what is happening right now".
Claude Code updates it **before** changing any other file (see `CLAUDE.md` §2).

## Current task

- **Status:** in progress  <!-- idle | in progress | blocked -->
- **Task:** Phase 2 – own ISO, installer, Time Machine, update app
- **Roadmap item:** Phase 2
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
    - [x] control center plasmoid org.glassfort.controlcenter (Wi-Fi, Bluetooth, volume, brightness, night light, dark mode, DND, screen recording)
    - [x] panel layout (top bar + floating dock) in the global themes; verified with scripts/session-screenshot
    - [ ] shortcut overlay (hold Super) – may move to a later step
  - [x] meta package glassfort-desktop (keyring dependency added once D-26 key exists):
    - [x] decisions D-37 (curated Plasma), D-38 (SDDM), D-39 (apps as hard deps), D-40 (libreoffice-fresh)
    - [x] glassfort-setup applies every 50-glassfort*.preset (settings commit)
    - [x] glassfort-desktop PKGBUILD + 50-glassfort-desktop.preset (sddm, NetworkManager, bluetooth, power-profiles-daemon)
  - [x] VM test: plain Arch → pacman -S glassfort-desktop → break update → roll back from boot menu (tests/vm/phase1 PASSED 2026-11-25):
    - [x] check host tools (qemu, OVMF, KVM ok; no swtpm – not needed for Phase 1); maintainer approved a 3 GB VM
    - [x] automated plain Arch install in QEMU/OVMF (Btrfs layout per docs/02, Limine) – tests/vm/phase1 (uncommitted)
    - [x] local [glassfort] repo from CI packages, signed with repo/vm-test-key
    - [x] pacman -S glassfort-desktop + glassfort-setup, boot into Plasma – run 6: all first-boot checks ok incl. AppArmor
    - [x] break an update, roll back from the Limine snapshot menu – run 8 PASSED (15/15 checks)
- **Files expected to change:** tests/vm/*, docs/07-testing.md, PROGRESS.md
- **Next step if interrupted:** Push the ISO-install fixes, wait for CI (new ISO), then automate the install test. images/*.jpg stay untracked (reference only).
- **Blocked because:** –

### Follow-ups (sub-task started 2026-11-25, maintainer: open items first)
  - [x] qmllint in CI (scripts/check-qml, CI job qml in an Arch container, allowlist)
  - [x] wallpaper dithering against banding (zero-mean grain filter)
  - [x] SDDM login theme (glassfort-branding: theme 'glassfort' reusing Breeze's QML, dark wallpaper, lockup as logo)
  - [x] lock screen wallpaper (glassfort-theme: /etc/xdg/kscreenlockerrc)
  - [x] Plymouth (D-41) + Glassfort KSplash; VM test 18/18 with realistic cmdline, boot fully branded
  - [x] dock jump lists (Kicker app model, looked up per app on menu open)

### GitHub page (sub-task started 2026-11-25)
  - [x] README: status after Phase 1, features, screenshot
  - [x] About: description, topics (gh repo edit); social preview image only via web UI

### Move to the glassfortos organisation (2026-11-25)
  - [x] maintainer created org glassfortos and transferred the repo; git remote updated
  - [x] replace the project URL in PKGBUILDs, metadata, docs (checksums)

### Phase 2 (started 2026-11-25)
  - [x] D-12: no interim Calamares; own installer moves into Phase 2 (docs/04, docs/09, docs/01)
  - [x] iso/: archiso profile (releng-based): live session with the Glassfort desktop, local [glassfort] repo (installer autostart follows with the installer)
  - [x] ISO build: script + CI job (privileged archlinux container), boot test in QEMU (tests/vm/live-iso)
  - [x] glassfort-installer backend: glassfort-install (plan JSON -> archinstall config, run, post-install: repo, Wi-Fi, look, recovery key) + pytest
  - [x] glassfort-installer frontend: PySide6 + Kirigami QML, 5 screens (docs/04)
  - [x] ISO: bake [glassfort] repo into /srv/glassfort/repo, installer autostart
  - [x] VM test: install from the ISO (first install 2026-11-25; fixes committed; boots to the desktop)
  - [ ] Automate the ISO install test end to end (UI clicks are flaky in QEMU) + rollback on the installed system
  - [ ] Follow-ups: Limine menu label (TARGET_OS_NAME=Glassfort committed, verify in next install), tray network icon missing on installed desktop (check), UI translations (de)
