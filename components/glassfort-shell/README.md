# glassfort-shell

Glassfort's own Plasma widgets (D-36 in
[`docs/DECISIONS.md`](../../docs/DECISIONS.md)), specified in
[`docs/03-desktop-design.md`](../../docs/03-desktop-design.md#glassfort-widgets-glassfort-shell).

| Plasmoid | Status |
|---|---|
| `org.glassfort.startmenu` – start menu | first version |
| `org.glassfort.dock` – taskbar/dock | first version |
| `org.glassfort.controlcenter` – control center | planned |

Installed to `/usr/share/plasma/plasmoids/`. The panel layout that places
them (slim top bar, floating dock) comes with the global themes.

makepkg takes local sources only as flat files, so the files sit flat in
this folder: `<plasmoid>-metadata.json`, `<plasmoid>-main.xml` and
`<plasmoid>-main.qml` become `metadata.json`, `contents/config/main.xml`
and `contents/ui/main.qml`; the other QML files have unique type names
(`StartMenuPopup.qml`, `DockTask.qml`, …) and go to `contents/ui/` unchanged.

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

## Dock

- One icon per app: pinned apps and running windows share the icon
  (windows are grouped by app; `TasksModel` with `separateLaunchers`
  off and `hideActivatedLaunchers` on).
- Left click works like the Windows taskbar: starts a pinned app,
  focuses its window, minimises it when it is already active, and with
  several windows cycles through them.
- Middle click or Shift+click opens a new window.
- Right click: New Window, Pin to Dock / Unpin from Dock, Close
  Window(s).
- Running indicator under the icon: a dot per running app, wider for
  several windows, an accent-coloured pill for the active app, the
  negative colour when an app demands attention. Starting apps pulse.
- Tooltip with the app name and window count.
- Pinned apps live in the `launchers` setting (TasksModel launcher URLs,
  `preferred://filemanager`, `applications:kitty.desktop`, …).

Data comes from Plasma's public task model (`org.kde.taskmanager`).

Planned: window previews on hover (PipeWire thumbnails), jump lists
(the stock task manager's jump list backend is compiled into that applet
and cannot be imported), drag to reorder, drop files on an icon.

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
The dock shows its pinned apps there but no running windows: KWin's
window management interface is only available to plasmashell. Running
indicators and click behaviour need the VM test.

qmllint reports three warnings in `startmenu-main.qml` about the Kicker models'
dynamic types (`initForClient`, `portOldFavorites`,
`systemFavoritesModel`). Kickoff uses the same calls.
