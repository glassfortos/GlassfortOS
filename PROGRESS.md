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
- **Next step if interrupted:** CI 45884008454 (34962c3) green. The Phase 2 VM run started 20:49 was killed by Claude Code because the host ran low on memory (7.1 GiB host, 4 GiB VM); not restarted, waiting for the maintainer. Rerun: tests/vm/phase2 --keep (or --memory 3072), expect 0 failed checks. Then glassfort-update, Secure Boot validation. images/*.jpg stay untracked.
- **Blocked because:** –

### GitHub issues and discussions (sub-task started 2026-11-26T21:20:00+01:00, maintainer request)
  - Open (maintainer, later): GitHub Wiki stays enabled for now; options discussed: turn it off, or use a Discussions category "Hardware reports" instead
  - [x] issue forms: bug report, feature request; config.yml (no blank issues, links: Q&A discussions, private security report, website)
  - [x] discussion category forms (Q&A, Ideas); enable Discussions (gh api); labels triage + area labels
  - [x] D-46 (Proposed): GitHub Discussions as the support channel for now (docs/08 "Support channel" was Open); CONTRIBUTING, README links
  - [x] check private vulnerability reporting is enabled (SECURITY.md relies on it)

### Restore Points / glassfort-timemachine (sub-task started 2026-11-26T16:10:00+01:00, roadmap Phase 2)
  - [x] research (2026-11-26): snapper root config already has ALLOW_GROUPS="wheel" (list/pin via snapper D-Bus without root); `limine-snapper-sync --restore` can restore any snapshot in its manifest, also from the normal system, but only interactively (stdin prompts) -> needs a small non-interactive patch (`--restore <id> --yes`); no Rust/cmake/ECM on this host. Was: research: snapper D-Bus permissions, limine-snapper-restore (non-interactive?), helper/polkit per docs/02, tooling here (Rust, KF6 dev)
  - [x] maintainer decided 2026-11-26: minimal glassfort-helper now (Rust, D-Bus + polkit, snapshot actions only) -> D-44; maintainer installs rust, cmake, extra-cmake-modules on the host
  - [ ] commit 1 docs: D-44, docs/02 (helper scope for Phase 2), docs/09 (helper partly in Phase 2)
  - [x] commit 2 third-party/limine-snapper-sync: patch for non-interactive `--restore <id>` (no prompts), reviewed
  - [x] commit 3 glassfort-helper: Rust system service org.glassfort.Helper1, RestoreSnapshot(id) with polkit (auth_admin_keep), journal audit log, D-Bus activation, unit tests
  - [x] commit 4 glassfort-timemachine: KCM (C++/QML): timeline from snapper D-Bus, pin/unpin, restore via helper
  - [x] commit 5 banner after booting a snapshot ("You are running an earlier state. Restore it permanently?") opening the Time Machine; replaces upstream's terminal notifier
  - [x] commit 6 glassfort-desktop depends on helper + timemachine; VM test restores through the helper instead of limine-snapper-restore
  - Files: components/glassfort-timemachine/ (new), maybe components/glassfort-helper/, docs/02, docs/DECISIONS.md

### Website (sub-task started 2026-11-26T15:40:00+01:00, parallel to the phase2 VM run)
  - [x] PROGRESS note; D-43 (Proposed): static site in website/, GitHub Pages via Actions, no trackers, no external requests, self-hosted Inter (OFL)
  - [x] website/: hero with logo + animated glass shapes, vision, six promises, features, screenshots, download (from website/release.json; "coming soon" until an ISO is published), docs link, footer
  - [x] Pages workflow (.github/workflows/pages.yml), CLAUDE.md scope `website`, docs/01 layout, docs/08 hosting
  - [x] check locally (headless Chromium screenshots, link check), commit, push
  - [x] enable GitHub Pages (Actions source), maintainer approved 2026-11-26: live at https://glassfortos.github.io/GlassfortOS/
  - Open: Impressum/privacy page (docs/08, legal; maintainer's data needed)

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
  - [x] ISO install test + rollback on the installed system: tests/vm/phase2 PASSED 2026-11-26 (21/21; UI clicks still manual, backend driven with the UI's plan)
  - [ ] Follow-ups: Limine menu label "Glassfort" verified (phase2 check), tray network icon missing on installed desktop (check), UI translations (de): done, verified live in the ISO VM 2026-11-26 (language switch retranslates the running UI); new: language switch blocks the UI ~10 s (setKeyboard/kwriteconfig synchronous?), step dots look odd when the Wi-Fi page is skipped
