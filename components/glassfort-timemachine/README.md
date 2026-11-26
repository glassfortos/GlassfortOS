# glassfort-timemachine – Restore Points

The **Restore Points** module in System Settings (System Administration):
the timeline of snapper snapshots of `/`, with keep (pin) and restore
(docs/02, D-44). In the UI it is never called "Time Machine" (D-45).

- **Timeline:** snapshots from snapper's D-Bus service (`ListSnapshots` of
  the `root` config), newest first, grouped by day. snap-pac's pacman
  command lines become titles like "Before: System update" or "After:
  Installing firefox".
- **Keep:** sets snapper's userdata `important=yes`, which the root config
  keeps separately from normal cleanup (`NUMBER_LIMIT_IMPORTANT`). Members of
  `wheel` may do this without a password (`ALLOW_GROUPS` in
  `glassfort-settings`).
- **Restore:** `RestoreSnapshot` on `glassfort-helper` (polkit asks for the
  admin password), then "Restart now / Later". Only snapshots that still
  have boot entries can be restored (limine-snapper-sync); others report
  the error.
- **Notification:** `glassfort-restore-notify` (autostart, Plasma only) tells
  the user after booting a snapshot and opens this module; it replaces
  limine-snapper-sync's notifier, which opened a terminal.
- **Banner:** when the system was booted from a snapshot in the boot menu
  (`rootflags=…subvol=/@snapshots/<n>/snapshot`), a banner offers to restore
  that state.

Open: package diff between snapshots ("Show changes"), German translation
of the UI, restoring pinned snapshots without boot entries.

## Build and test

```sh
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr && cmake --build build
ctest --test-dir build        # titles, kernel command line, model
```

The C++ part has no CMake `ui/` folder on purpose: makepkg takes local
sources from the PKGBUILD folder only, so `CMakeLists.txt` does by hand
what `kcmutils_add_qml_kcm` does.
