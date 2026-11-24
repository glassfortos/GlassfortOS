/*
    SPDX-License-Identifier: GPL-3.0-or-later

    The start button in the dock or panel.
*/

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

MouseArea {
    id: button

    property bool wasExpanded: false

    hoverEnabled: true
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: i18n("Start")

    onPressed: wasExpanded = root.expanded
    onClicked: root.expanded = !wasExpanded
    Keys.onPressed: event => {
        if ([Qt.Key_Space, Qt.Key_Enter, Qt.Key_Return, Qt.Key_Select].includes(event.key)) {
            root.expanded = !root.expanded;
            event.accepted = true;
        }
    }

    Kirigami.Icon {
        anchors.fill: parent
        anchors.margins: Math.round(Math.min(parent.width, parent.height) * 0.08)
        source: Plasmoid.icon
        fallback: "start-here-kde-symbolic"
        active: button.containsMouse || root.expanded
    }
}
