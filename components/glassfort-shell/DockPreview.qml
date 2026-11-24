/*
    SPDX-License-Identifier: GPL-3.0-or-later

    Hover preview of a dock icon: one live thumbnail per window (PipeWire
    screencast through KWin), the window title and a close button.
    Clicking a thumbnail brings that window forward. Pinned apps that are
    not running only show their name.
*/

import QtQuick
import QtQuick.Layouts
import QtQml.Models
import org.kde.kirigami as Kirigami
import org.kde.pipewire as PipeWire
import org.kde.plasma.components as PC3
import org.kde.taskmanager as TaskManager

Item {
    id: preview

    required property TaskManager.TasksModel tasksModel
    required property int taskIndex
    required property var taskModel

    readonly property bool isGroup: taskModel.IsGroupParent === true
    readonly property bool isWindow: taskModel.IsWindow === true
    // Stream only while the tooltip window is on screen.
    readonly property bool shown: Window.window !== null && Window.window.visible

    readonly property real thumbWidth: Kirigami.Units.gridUnit * 14
    readonly property real thumbHeight: Math.round(thumbWidth * 9 / 16)

    implicitWidth: content.implicitWidth + Kirigami.Units.largeSpacing * 2
    implicitHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2

    component WindowThumb: ColumnLayout {
        id: thumb

        required property var modelIndex
        required property string title
        required property var winId
        required property var appIcon
        required property bool minimized

        spacing: Kirigami.Units.smallSpacing
        Layout.preferredWidth: preview.thumbWidth

        RowLayout {
            Layout.fillWidth: true
            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                source: thumb.appIcon
            }
            PC3.Label {
                Layout.fillWidth: true
                text: thumb.title
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
            PC3.ToolButton {
                icon.name: "window-close-symbolic"
                display: PC3.AbstractButton.IconOnly
                text: i18n("Close")
                PC3.ToolTip.text: text
                PC3.ToolTip.visible: hovered
                onClicked: preview.tasksModel.requestClose(thumb.modelIndex)
            }
        }

        MouseArea {
            id: thumbMouse
            Layout.preferredWidth: preview.thumbWidth
            Layout.preferredHeight: preview.thumbHeight
            hoverEnabled: true
            onClicked: preview.tasksModel.requestActivate(thumb.modelIndex)
            Accessible.role: Accessible.Button
            Accessible.name: i18n("Switch to %1", thumb.title)

            Rectangle {
                anchors.fill: parent
                radius: Kirigami.Units.cornerRadius
                color: Kirigami.Theme.textColor
                opacity: thumbMouse.containsMouse ? 0.10 : 0.04
            }

            PipeWire.PipeWireSourceItem {
                id: stream
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                nodeId: screencast.nodeId
                visible: ready
                TaskManager.ScreencastingRequest {
                    id: screencast
                    uuid: preview.shown && !thumb.minimized ? thumb.winId : ""
                }
            }

            // No stream (minimised, not yet ready, or screencasting off).
            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.huge
                height: width
                visible: !stream.visible
                source: thumb.appIcon
            }
        }
    }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Kirigami.Units.largeSpacing

        // Pinned app that is not running: just its name.
        PC3.Label {
            visible: !preview.isGroup && !preview.isWindow
            text: preview.taskModel.display ?? ""
            textFormat: Text.PlainText
        }

        // A single window.
        Loader {
            active: preview.isWindow && !preview.isGroup
            visible: active
            sourceComponent: WindowThumb {
                modelIndex: preview.tasksModel.makeModelIndex(preview.taskIndex)
                title: preview.taskModel.display ?? ""
                winId: (preview.taskModel.WinIdList ?? [])[0] ?? ""
                appIcon: preview.taskModel.decoration ?? ""
                minimized: preview.taskModel.IsMinimized === true
            }
        }

        // Several windows of the same app.
        Repeater {
            model: DelegateModel {
                model: preview.isGroup ? preview.tasksModel : null
                rootIndex: preview.tasksModel.makeModelIndex(preview.taskIndex)
                delegate: WindowThumb {
                    required property int index
                    required property var model
                    modelIndex: preview.tasksModel.makeModelIndex(preview.taskIndex, index)
                    title: model.display ?? ""
                    winId: (model.WinIdList ?? [])[0] ?? ""
                    appIcon: model.decoration ?? ""
                    minimized: model.IsMinimized === true
                }
            }
        }
    }
}
