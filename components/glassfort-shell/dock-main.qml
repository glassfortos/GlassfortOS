/*
    SPDX-License-Identifier: GPL-3.0-or-later

    Glassfort dock (docs/03-desktop-design.md, D-36): pinned and running
    apps, one icon per app. Data comes from Plasma's public task model
    (org.kde.taskmanager), the same one the stock task manager uses.
*/

import QtQuick
import QtQuick.Layouts
import QtQml.Models
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    // Square cells that fill the panel's thickness.
    readonly property real cellSize: vertical ? width : height
    readonly property real cellOrDefault: cellSize > 0 ? cellSize : Kirigami.Units.iconSizes.huge

    preferredRepresentation: fullRepresentation
    Plasmoid.constraintHints: Plasmoid.CanFillArea
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Layout.fillWidth: false
    Layout.fillHeight: false
    Layout.preferredWidth: vertical ? cellOrDefault : tasksModel.count * cellOrDefault
    Layout.preferredHeight: vertical ? tasksModel.count * cellOrDefault : cellOrDefault
    Layout.minimumWidth: Layout.preferredWidth
    Layout.minimumHeight: Layout.preferredHeight

    TaskManager.ActivityInfo {
        id: activityInfo
    }
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    readonly property TaskManager.TasksModel tasksModel: TaskManager.TasksModel {
        // One icon per app: windows are grouped under their app, and pinned
        // apps become the icon of their running windows.
        groupMode: TaskManager.TasksModel.GroupApplications
        groupInline: false
        separateLaunchers: false
        hideActivatedLaunchers: true
        sortMode: TaskManager.TasksModel.SortManual
        launchInPlace: true

        activity: activityInfo.currentActivity
        virtualDesktop: virtualDesktopInfo.currentDesktop
        screenGeometry: Plasmoid.containment.screenGeometry
        filterByActivity: true
        filterByVirtualDesktop: false
        filterByScreen: false

        launcherList: Plasmoid.configuration.launchers
        onLauncherListChanged: Plasmoid.configuration.launchers = launcherList
    }

    // Jump lists: the app actions of each .desktop file ("New Private
    // Window", ...). Plasma's task manager keeps its jump list backend inside
    // that applet, so take them from Kicker's app model, like the start menu.
    readonly property Kicker.RootModel kickerRoot: Kicker.RootModel {
        autoPopulate: false
        appletInterface: root
        flat: true
        sorted: true
        showSeparators: false
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        showFavoritesPlaceholder: false
        Component.onCompleted: refresh()
    }
    property var kickerApps: null
    // favoriteId (e.g. "firefox.desktop") -> { row, actions }, filled on demand.
    property var jumpLists: ({})
    Connections {
        target: root.kickerRoot
        function onRefreshed() {
            root.jumpLists = {};
            root.kickerApps = root.kickerRoot.count > 0 ? root.kickerRoot.modelForRow(0) : null;
        }
    }
    // Row access without creating delegates. Asking every app for its
    // actionList up front is slow (Kicker adds AppStream entries), so only
    // the app whose menu opens is asked.
    DelegateModel {
        id: kickerItems
        model: root.kickerApps
        delegate: Item {}
    }

    // The jump list of a dock entry, from its launcher URL or app id.
    function jumpListFor(launcherUrl, appId) {
        const url = String(launcherUrl ?? "");
        const candidates = [];
        if (url.startsWith("applications:")) {
            candidates.push(url.slice("applications:".length));
        }
        if (appId) {
            candidates.push(appId + ".desktop", appId);
        }
        for (const id of candidates) {
            if (id in root.jumpLists) {
                return root.jumpLists[id];
            }
        }
        for (let row = 0; row < kickerItems.items.count; ++row) {
            const m = kickerItems.items.get(row).model;
            if (!candidates.includes(m.favoriteId)) {
                continue;
            }
            const actions = (m.actionList ?? []).filter(a => a.actionId === "_kicker_jumpListAction");
            const entry = actions.length > 0 ? {
                row: row,
                actions: actions
            } : null;
            root.jumpLists[m.favoriteId] = entry;
            return entry;
        }
        return null;
    }

    function runJumpAction(entry, action) {
        root.kickerApps.trigger(entry.row, "_kicker_jumpListAction", action.actionArgument);
    }

    fullRepresentation: ListView {

        orientation: root.vertical ? ListView.Vertical : ListView.Horizontal
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        model: root.tasksModel

        delegate: DockTask {
            tasksModel: root.tasksModel
            size: root.cellOrDefault
            vertical: root.vertical
        }

        add: Transition {
            NumberAnimation {
                property: "scale"
                from: 0.6
                to: 1
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
