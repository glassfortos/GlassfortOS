/*
    SPDX-License-Identifier: GPL-3.0-or-later

    A quick-settings tile: icon, title, optional status line. Checked
    tiles are filled with the accent colour.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

PC3.AbstractButton {
    id: tile

    property string iconName: ""
    property string subtitle: ""

    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 3.2
    hoverEnabled: true
    Accessible.role: checkable ? Accessible.CheckBox : Accessible.Button
    Accessible.description: subtitle

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius * 2
        color: tile.checked ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
        opacity: tile.checked ? (tile.hovered ? 0.9 : 1) : (tile.pressed ? 0.18 : tile.hovered ? 0.12 : 0.07)
        border.width: tile.visualFocus ? 2 : 0
        border.color: Kirigami.Theme.focusColor
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing * 3

        Kirigami.Icon {
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            source: tile.iconName
            color: tile.checked ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
            isMask: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            PC3.Label {
                Layout.fillWidth: true
                text: tile.text
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                color: tile.checked ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
            }
            PC3.Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: tile.subtitle
                elide: Text.ElideRight
                font: Kirigami.Theme.smallFont
                color: tile.checked ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                opacity: 0.8
            }
        }
    }
}
