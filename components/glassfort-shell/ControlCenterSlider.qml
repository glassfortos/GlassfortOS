/*
    SPDX-License-Identifier: GPL-3.0-or-later

    A labelled slider row (volume, brightness) with an icon button in
    front, e.g. to mute.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

ColumnLayout {
    id: row

    property alias text: label.text
    property alias iconName: button.icon.name
    property alias buttonText: button.text
    property alias from: slider.from
    property alias to: slider.to
    property alias value: slider.value
    property alias stepSize: slider.stepSize
    property alias slider: slider

    signal moved(real value)
    signal buttonClicked()

    Layout.fillWidth: true
    spacing: 0

    PC3.Label {
        id: label
        Layout.fillWidth: true
        font.weight: Font.DemiBold
    }

    RowLayout {
        Layout.fillWidth: true
        PC3.ToolButton {
            id: button
            display: PC3.AbstractButton.IconOnly
            PC3.ToolTip.text: text
            PC3.ToolTip.visible: hovered && text.length > 0
            onClicked: row.buttonClicked()
        }
        PC3.Slider {
            id: slider
            Layout.fillWidth: true
            Accessible.name: label.text
            onMoved: row.moved(value)
        }
        PC3.Label {
            Layout.minimumWidth: Kirigami.Units.gridUnit * 2
            horizontalAlignment: Text.AlignRight
            text: slider.to > slider.from ? i18nc("percentage", "%1%", Math.round(100 * (slider.value - slider.from) / (slider.to - slider.from))) : ""
        }
    }
}
