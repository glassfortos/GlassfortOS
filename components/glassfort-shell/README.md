# glassfort-shell

Glassfort's own Plasma widgets (D-36 in
[`docs/DECISIONS.md`](../../docs/DECISIONS.md)), specified in
[`docs/03-desktop-design.md`](../../docs/03-desktop-design.md#glassfort-widgets-glassfort-shell).

| Plasmoid | Status |
|---|---|
| `org.glassfort.startmenu` – start menu | first version |
| `org.glassfort.dock` – taskbar/dock | planned |
| `org.glassfort.controlcenter` – control center | planned |

Installed to `/usr/share/plasma/plasmoids/`. The panel layout that places
them (slim top bar, floating dock) comes with the global themes.

makepkg takes local sources only as flat files, so the files sit flat in
this folder: `<plasmoid>-metadata.json`, `<plasmoid>-main.xml` and
`<plasmoid>-main.qml` become `metadata.json`, `contents/config/main.xml`
and `contents/ui/main.qml`; the other QML files have unique type names
(`StartMenuPopup.qml`, …) and go to `contents/ui/` unchanged.

## Start menu

- Opens with `Super`: the plasmoid provides `org.kde.plasma.launchermenu`,
  so plasmashell's launcher shortcut opens it, exactly like Kickoff.
- Search field on top. Typing anywhere in the menu goes there. Results
  come from KRunner (apps, files, settings, calculator and so on); `Enter`
  starts the first result, arrow keys move through the list.
- Home page: a grid of pinned apps (6 columns) and recent files.
- "All apps": every installed app, alphabetical, with letter sections.
- Footer: user name and avatar, power menu (lock, log out, sleep,
  restart, shut down; configurable with `powerActions`).
- `Esc` clears the search, leaves "All apps", then closes the menu.

Data comes from Plasma's Kicker models (`org.kde.plasma.private.kicker`
in plasma-workspace), the same ones Kickoff uses: root model (pinned
apps, all apps), runner model (search), recent usage model (recent
files) and system model (power). It is a private Plasma API, so check
the start menu after every Plasma upgrade.

Pinned apps are stored per user by KActivities, like Kickoff's. Right-click
an app (in the grid, All apps or search results) to pin or unpin it. The
`favorites` setting seeds the grid on first use; if KActivities is not
ready yet on a user's very first login, the seeding is retried at the
next start instead of being marked as done.

Planned: drag to reorder, app actions (jump lists) in the context menu,
and the assistant prompt in the search field (Phase 3,
`glassfort-assistant`).

## Checking

```sh
qmllint -I /usr/lib/qt6/qml *.qml
makepkg -d -f            # assembles pkg/glassfort-shell/usr/share/plasma/plasmoids/
../../scripts/plasmoid-screenshot out.png \
    pkg/glassfort-shell/usr/share/plasma/plasmoids/org.glassfort.startmenu -f planar -s 760x900
```

`scripts/plasmoid-screenshot` runs the plasmoid in an invisible KWin with
empty config and data dirs, so it neither shows windows nor touches your
Plasma data. In such a fresh environment the pinned apps stay empty,
because KActivities creates its database only after the first start.

qmllint reports three warnings in `startmenu-main.qml` about the Kicker models'
dynamic types (`initForClient`, `portOldFavorites`,
`systemFavoritesModel`). Kickoff uses the same calls.
