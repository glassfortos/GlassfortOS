/*
    SPDX-License-Identifier: GPL-3.0-or-later

    One app in the dock: icon, running indicator, Windows-like clicks.
    - left click: start a pinned app; focus its window; minimise it when
      it is already active; with several windows, cycle through them
    - middle click or Shift+click: new window
    - right click: context menu (jump list, new window, pin/unpin, close)
*/

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.taskmanager as TaskManager

MouseArea {
    id: task

    required property int index
    required property var model
    required property TaskManager.TasksModel tasksModel
    required property real size
    required property bool vertical

    readonly property bool running: model.IsWindow === true || model.IsGroupParent === true
    readonly property bool active: model.IsActive === true
    readonly property bool demandsAttention: model.IsDemandingAttention === true
    readonly property int windowCount: model.IsGroupParent ? (model.ChildCount ?? 1) : (running ? 1 : 0)

    width: size
    height: size
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: model.display ?? ""
    Accessible.description: running ? i18np("%1 window", "%1 windows", windowCount) : i18n("Not running")

    function modelIndex() {
        return tasksModel.makeModelIndex(index);
    }

    function activate() {
        if (!model.IsGroupParent) {
            if (active && model.IsWindow) {
                tasksModel.requestToggleMinimized(modelIndex());
            } else {
                tasksModel.requestActivate(modelIndex());
            }
            return;
        }
        // Several windows: bring the most recent one forward; if one of
        // them is already active, go to the next one.
        const n = tasksModel.rowCount(modelIndex());
        let activeChild = -1;
        for (let i = 0; i < n; ++i) {
            if (tasksModel.data(tasksModel.makeModelIndex(index, i), TaskManager.AbstractTasksModel.IsActive)) {
                activeChild = i;
                break;
            }
        }
        if (activeChild < 0) {
            tasksModel.requestActivate(modelIndex());
        } else {
            tasksModel.requestActivate(tasksModel.makeModelIndex(index, (activeChild + 1) % n));
        }
    }

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton || (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ShiftModifier))) {
            tasksModel.requestNewInstance(modelIndex());
        } else if (mouse.button === Qt.RightButton) {
            openMenu(mouse.x, mouse.y);
        } else {
            activate();
        }
    }
    Keys.onPressed: event => {
        if ([Qt.Key_Space, Qt.Key_Enter, Qt.Key_Return].includes(event.key)) {
            activate();
            event.accepted = true;
        } else if (event.key === Qt.Key_Menu) {
            openMenu(width / 2, height / 2);
            event.accepted = true;
        }
    }

    // Hover and press feedback: a soft rounded plate behind the icon.
    Rectangle {
        anchors.fill: parent
        anchors.margins: Math.round(task.size * 0.06)
        radius: Kirigami.Units.cornerRadius * 2
        color: Kirigami.Theme.textColor
        opacity: task.pressed ? 0.16 : (task.containsMouse || task.activeFocus ? 0.09 : 0)
        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
            }
        }
    }

    Kirigami.Icon {
        id: icon
        anchors.centerIn: parent
        width: Math.round(task.size * 0.68)
        height: width
        source: task.model.decoration ?? ""
        active: task.containsMouse
        scale: task.pressed ? 0.92 : 1
        Behavior on scale {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
            }
        }
        // Starting apps pulse until their window appears.
        SequentialAnimation on opacity {
            running: task.model.IsStartup === true
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation {
                to: 0.4
                duration: Kirigami.Units.veryLongDuration
            }
            NumberAnimation {
                to: 1
                duration: Kirigami.Units.veryLongDuration
            }
        }
    }

    // Running indicator below the icon (beside it in a vertical dock): a
    // dot per running app, a wider accent pill for the active one, and the
    // negative colour when the app wants attention.
    Rectangle {
        visible: task.running
        readonly property real thickness: Math.max(3, Math.round(task.size * 0.06))
        readonly property real length: task.active ? Math.round(task.size * 0.32) : thickness * (task.windowCount > 1 ? 2.5 : 1)
        width: task.vertical ? thickness : length
        height: task.vertical ? length : thickness
        radius: thickness / 2
        x: task.vertical ? 1 : (task.width - width) / 2
        y: task.vertical ? (task.height - height) / 2 : task.height - height - 1
        color: task.demandsAttention ? Kirigami.Theme.negativeTextColor : (task.active ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor)
        opacity: task.active || task.demandsAttention ? 1 : 0.55
        Behavior on width {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    // Hover: live window previews (DockPreview); clicks inside it work.
    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        location: task.vertical ? PlasmaCore.Types.LeftEdge : PlasmaCore.Types.BottomEdge
        interactive: task.running
        active: !menu.status
        mainItem: DockPreview {
            tasksModel: task.tasksModel
            taskIndex: task.index
            taskModel: task.model
        }
    }

    // Jump list entries are created when the menu opens, above "New Window".
    property var jumpItems: []
    Component {
        id: jumpItemComponent
        PlasmaExtras.MenuItem {
            property var entry
            property var jumpAction
            onClicked: root.runJumpAction(entry, jumpAction)
        }
    }
    function openMenu(x, y) {
        for (const item of jumpItems) {
            menu.removeMenuItem(item);
            item.destroy();
        }
        const items = [];
        const entry = root.jumpListFor(task.model.LauncherUrlWithoutIcon, task.model.AppId);
        if (entry) {
            for (const action of entry.actions) {
                const item = jumpItemComponent.createObject(menu, {
                    text: action.text,
                    icon: action.icon,
                    entry: entry,
                    jumpAction: action
                });
                menu.addMenuItem(item, newWindowItem);
                items.push(item);
            }
            const separator = jumpItemComponent.createObject(menu, {
                separator: true
            });
            menu.addMenuItem(separator, newWindowItem);
            items.push(separator);
        }
        jumpItems = items;
        menu.open(x, y);
    }

    PlasmaExtras.Menu {
        id: menu

        readonly property url launcherUrl: task.model.LauncherUrlWithoutIcon ?? ""
        readonly property bool pinned: launcherUrl.toString().length > 0 && task.tasksModel.launcherPosition(launcherUrl) >= 0

        visualParent: task
        placement: task.vertical ? PlasmaExtras.Menu.RightPosedTopAlignedPopup : PlasmaExtras.Menu.TopPosedLeftAlignedPopup

        PlasmaExtras.MenuItem {
            id: newWindowItem
            text: i18n("New Window")
            icon: "window-new"
            visible: task.model.CanLaunchNewInstance === true
            onClicked: task.tasksModel.requestNewInstance(task.modelIndex())
        }

        PlasmaExtras.MenuItem {
            text: menu.pinned ? i18n("Unpin from Dock") : i18n("Pin to Dock")
            icon: menu.pinned ? "window-unpin" : "window-pin"
            visible: menu.launcherUrl.toString().length > 0
            onClicked: {
                if (menu.pinned) {
                    task.tasksModel.requestRemoveLauncher(menu.launcherUrl);
                } else {
                    task.tasksModel.requestAddLauncher(menu.launcherUrl);
                }
            }
        }

        PlasmaExtras.MenuItem {
            text: task.windowCount > 1 ? i18n("Close All Windows") : i18n("Close Window")
            icon: "window-close"
            visible: task.running
            onClicked: task.tasksModel.requestClose(task.modelIndex())
        }
    }
}
