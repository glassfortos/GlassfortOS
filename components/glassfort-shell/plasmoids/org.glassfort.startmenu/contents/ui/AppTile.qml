/*
    SPDX-License-Identifier: GPL-3.0-or-later

    A pinned app in the start menu grid: large icon, name below.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

PC3.ItemDelegate {
    id: tile

    required property int index
    required property var model
    // The model that can trigger() this row.
    required property var sourceModel

    signal launched()

    width: GridView.view ? GridView.view.cellWidth : implicitWidth
    height: GridView.view ? GridView.view.cellHeight : implicitHeight
    hoverEnabled: true
    highlighted: GridView.isCurrentItem && GridView.view.activeFocus

    text: model.display ?? ""
    Accessible.name: text
    Accessible.description: model.description ?? ""

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.large
            Layout.preferredHeight: Kirigami.Units.iconSizes.large
            source: tile.model.decoration ?? ""
            animated: false
        }

        PC3.Label {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.ceil(implicitHeight)
            text: tile.text
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
        }
    }

    onClicked: {
        if (sourceModel.trigger(index, "", null)) {
            launched();
        }
    }
}
