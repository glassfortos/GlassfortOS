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

Pinned apps are stored per user by KActivities, like Kickoff's. The
`favorites` setting only seeds them on first use.

Planned: pin and unpin from the context menu, drag to reorder, and the
assistant prompt in the search field (Phase 3, `glassfort-assistant`).

## Checking

```sh
qmllint -I /usr/lib/qt6/qml plasmoids/*/contents/ui/*.qml
../../scripts/plasmoid-screenshot out.png plasmoids/org.glassfort.startmenu -f planar -s 760x900
```

`scripts/plasmoid-screenshot` runs the plasmoid in an invisible KWin with
empty config and data dirs, so it neither shows windows nor touches your
Plasma data. In such a fresh environment the pinned apps stay empty,
because KActivities creates its database only after the first start.

qmllint reports three warnings in `main.qml` about the Kicker models'
dynamic types (`initForClient`, `portOldFavorites`,
`systemFavoritesModel`). Kickoff uses the same calls.
