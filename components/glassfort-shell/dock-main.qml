/*
    SPDX-License-Identifier: GPL-3.0-or-later

    Glassfort dock (docs/03-desktop-design.md, D-36): pinned and running
    apps, one icon per app. Data comes from Plasma's public task model
    (org.kde.taskmanager), the same one the stock task manager uses.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
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
