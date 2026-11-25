/*
    SPDX-License-Identifier: GPL-3.0-or-later

    Glassfort's Plasma start splash (KSplash), shown between login and the
    desktop. It continues the boot splash (D-41): Midnight, the Glassfort
    symbol from glassfort-branding, three pulsing dots.
*/

import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property int stage

    color: "#0E1222"

    onStageChanged: {
        if (stage == 2) {
            fadeIn.running = true;
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Image {
            id: logo
            readonly property real size: Kirigami.Units.gridUnit * 8
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -parent.height / 12
            asynchronous: true
            source: "file:///usr/share/glassfort/branding/glassfort-symbol-dark.svg"
            sourceSize.width: size
            sourceSize.height: size
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom
            anchors.topMargin: root.height / 14
            spacing: Kirigami.Units.gridUnit * 0.6

            Repeater {
                model: 3
                delegate: Rectangle {
                    id: dot
                    required property int index
                    width: Kirigami.Units.gridUnit * 0.6
                    height: width
                    radius: width / 2
                    color: "#F5F7FA"
                    opacity: 0.3
                    SequentialAnimation on opacity {
                        running: Kirigami.Units.longDuration > 1
                        loops: Animation.Infinite
                        PauseAnimation {
                            duration: dot.index * 250
                        }
                        NumberAnimation {
                            to: 1
                            duration: 500
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: 0.3
                            duration: 500
                            easing.type: Easing.InOutSine
                        }
                        PauseAnimation {
                            duration: (2 - dot.index) * 250
                        }
                    }
                }
            }
        }
    }

    OpacityAnimator {
        id: fadeIn
        target: content
        from: 0
        to: 1
        duration: Kirigami.Units.longDuration * 2
        easing.type: Easing.InOutQuad
    }
}
