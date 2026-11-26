// SPDX-License-Identifier: GPL-3.0-or-later
// Screen 5: light, dark or automatic (by time of day).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    required property var plan
    readonly property string title: qsTr("Look")
    readonly property bool canContinue: true
    readonly property var looks: [
        {
            look: "light",
            name: qsTr("Light"),
            image: "file:///usr/share/wallpapers/Glassfort/contents/images/1920x1080.png"
        },
        {
            look: "dark",
            name: qsTr("Dark"),
            image: "file:///usr/share/wallpapers/Glassfort/contents/images_dark/1920x1080.png"
        },
        {
            look: "auto",
            name: qsTr("Automatic"),
            image: ""
        }
    ]

    signal edited(string key, var value)

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Automatic switches to dark in the evening. You can change this any time in System Settings.")
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing * 2

            Repeater {
                model: page.looks
                delegate: QQC2.AbstractButton {
                    id: card
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: width * 0.75
                    checked: page.plan.look === modelData.look
                    onClicked: page.edited("look", modelData.look)

                    contentItem: ColumnLayout {
                        spacing: Kirigami.Units.smallSpacing
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Kirigami.Units.cornerRadius * 2
                            clip: true
                            color: "transparent"
                            border.width: card.checked ? 3 : 1
                            border.color: card.checked ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor

                            Image {
                                anchors.fill: parent
                                anchors.margins: parent.border.width
                                visible: card.modelData.image !== ""
                                source: card.modelData.image
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            // Automatic: half light, half dark.
                            Row {
                                anchors.fill: parent
                                anchors.margins: parent.border.width
                                visible: card.modelData.image === ""
                                Image {
                                    width: parent.width / 2
                                    height: parent.height
                                    source: page.looks[0].image
                                    fillMode: Image.PreserveAspectCrop
                                    horizontalAlignment: Image.AlignLeft
                                }
                                Image {
                                    width: parent.width / 2
                                    height: parent.height
                                    source: page.looks[1].image
                                    fillMode: Image.PreserveAspectCrop
                                    horizontalAlignment: Image.AlignRight
                                }
                            }
                        }
                        QQC2.Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: card.modelData.name
                            font.bold: card.checked
                        }
                    }
                }
            }
        }
    }
}
