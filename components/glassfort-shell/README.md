# glassfort-shell

Glassfort's own Plasma widgets (D-36 in
[`docs/DECISIONS.md`](../../docs/DECISIONS.md)), specified in
[`docs/03-desktop-design.md`](../../docs/03-desktop-design.md#glassfort-widgets-glassfort-shell).

| Plasmoid | Status |
|---|---|
| `org.glassfort.startmenu` – start menu | first version |
| `org.glassfort.dock` – taskbar/dock | first version |
| `org.glassfort.controlcenter` – control center | first version |

Installed to `/usr/share/plasma/plasmoids/`.

## Layout

`layout.js` is installed as the default layout of both Glassfort global
themes (`contents/layouts/org.kde.plasma.desktop-layout.js`); plasmashell
runs it for a new user's first session and when a global theme is
applied together with its layout:

- slim top bar (not floating): spacer, system tray, control center,
  clock with date. The tray items the control center covers (network,
  volume, Bluetooth, brightness) are moved to the tray's overflow. In
  Plasma 6 the tray is itself a containment, so the script writes
  `hiddenItems` into the tray's own `[General]` group.
- floating dock at the bottom, centred, as wide as its content: start
  menu and dock.

Without glassfort-shell the global themes fall back to Breeze's layout.

makepkg takes local sources only as flat files, so the files sit flat in
this folder: `<plasmoid>-metadata.json`, `<plasmoid>-main.xml` and
`<plasmoid>-main.qml` become `metadata.json`, `contents/config/main.xml`
and `contents/ui/main.qml`; the other QML files have unique type names
(`StartMenuPopup.qml`, `DockTask.qml`, `ControlCenterTile.qml`, …) and go to `contents/ui/` unchanged.

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
- Hover preview (`DockPreview.qml`): a live thumbnail per window
  (PipeWire screencast through KWin, `org.kde.pipewire` from kpipewire),
  the window title and a close button; clicking a thumbnail brings the
  window forward. Streams run only while the preview is on screen;
  minimised windows show the app icon. Pinned apps that are not running
  show their name.
- Pinned apps live in the `launchers` setting (TasksModel launcher URLs,
  `preferred://filemanager`, `applications:kitty.desktop`, …).

Data comes from Plasma's public task model (`org.kde.taskmanager`).

Planned: jump lists
(the stock task manager's jump list backend is compiled into that applet
and cannot be imported), drag to reorder, drop files on an icon.

## Control center

A button in the top bar with network and volume status. It opens:

| Tile / slider | Backend (the matching Plasma applet's) |
|---|---|
| Wi-Fi on/off, current connection | plasma-nm (`org.kde.plasma.networkmanagement`) |
| Bluetooth on/off, connected devices | bluez-qt (`org.kde.bluezqt`), as in bluedevil's applet |
| Do Not Disturb | `org.kde.notificationmanager` (until turned off) |
| Dark Mode | powerdevil `DarkModeControl` (switches Glassfort ↔ Glassfort Dark) |
| Night Light | KWin `org.kde.KWin.NightLight` (manual override of the schedule) |
| Record Screen | `spectacle -R r` (`recordMode`: r region, s screen, w window) |
| Volume slider + mute | plasma-pa (`PreferredDevice.sink`) |
| Brightness slider per display | powerdevil `ScreenBrightnessControl` |
| All Settings | starts `systemsettings` |

qmllint cannot see plasma-pa's `PreferredDevice` and `PulseAudio` (the
plugin registers them at runtime) and warns about them.

## Checking

`scripts/session-screenshot OUT.png` builds glassfort-branding,
glassfort-theme and glassfort-shell into a temporary root and takes a
screenshot of a complete, invisible Plasma session with them (global
theme, layout and widgets as on a new user's first login).

```sh
../../scripts/check-qml   # qmllint, known Plasma warnings allowlisted
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
indicators and click behaviour need the VM test. The control center
shows real Wi-Fi and Bluetooth state there, but no volume or brightness
sliders (no audio or brightness service in the private session).

qmllint reports three warnings in `startmenu-main.qml` about the Kicker models'
dynamic types (`initForClient`, `portOldFavorites`,
`systemFavoritesModel`). Kickoff uses the same calls.
