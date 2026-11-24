/*
    SPDX-License-Identifier: GPL-3.0-or-later

    Control center button in the top bar: network and volume status.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

MouseArea {
    id: button

    property bool wasExpanded: false

    readonly property string volumeIcon: {
        if (!root.sink || root.sink.muted || root.sink.volume <= 0) {
            return "audio-volume-muted-symbolic";
        }
        const ratio = root.sink.volume / root.normalVolume;
        return ratio < 0.34 ? "audio-volume-low-symbolic" : ratio < 0.67 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic";
    }

    implicitWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
    Layout.minimumWidth: implicitWidth
    hoverEnabled: true
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: i18n("Control Center")

    onPressed: wasExpanded = root.expanded
    onClicked: root.expanded = !wasExpanded
    Keys.onPressed: event => {
        if ([Qt.Key_Space, Qt.Key_Enter, Qt.Key_Return, Qt.Key_Select].includes(event.key)) {
            root.expanded = !root.expanded;
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: Kirigami.Units.cornerRadius * 2
        color: Kirigami.Theme.textColor
        opacity: root.expanded ? 0.14 : (button.containsMouse ? 0.08 : 0)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing
        readonly property real iconSize: Math.min(button.height * 0.6, Kirigami.Units.iconSizes.smallMedium)

        Kirigami.Icon {
            Layout.preferredWidth: row.iconSize
            Layout.preferredHeight: row.iconSize
            source: root.connectionIcon.connectionIcon
        }
        Kirigami.Icon {
            Layout.preferredWidth: row.iconSize
            Layout.preferredHeight: row.iconSize
            source: button.volumeIcon
        }
    }
}
