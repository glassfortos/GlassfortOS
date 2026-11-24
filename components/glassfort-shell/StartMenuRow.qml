/*
    SPDX-License-Identifier: GPL-3.0-or-later

    One row in a list: search results, recent files, all apps.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

PC3.ItemDelegate {
    id: row

    required property int index
    required property var model
    // The model that can trigger() this row.
    required property var sourceModel

    signal launched()

    width: ListView.view ? ListView.view.width : implicitWidth
    hoverEnabled: true
    highlighted: ListView.isCurrentItem && ListView.view.activeFocus
    visible: !(model.isSeparator ?? false)
    height: visible ? implicitHeight : 0

    text: model.display ?? ""
    Accessible.name: text
    Accessible.description: model.description ?? ""

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            source: row.model.decoration ?? ""
            animated: false
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PC3.Label {
                Layout.fillWidth: true
                text: row.text
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
            PC3.Label {
                Layout.fillWidth: true
                visible: text.length > 0 && text !== row.text
                text: row.model.description ?? ""
                elide: Text.ElideMiddle
                textFormat: Text.PlainText
                opacity: 0.7
                font: Kirigami.Theme.smallFont
            }
        }
    }

    onClicked: {
        if (sourceModel.trigger(index, "", null)) {
            launched();
        }
    }
}
