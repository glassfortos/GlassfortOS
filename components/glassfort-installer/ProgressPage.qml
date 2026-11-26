// SPDX-License-Identifier: GPL-3.0-or-later
// Installation progress with short slides about the six promises (docs/04).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    property bool active: false
    property int percent: 0
    property string stage: "start"
    property string error: ""
    readonly property var stageText: ({
        start: qsTr("Preparing…"),
        disk: qsTr("Preparing the disk…"),
        base: qsTr("Installing the system…"),
        boot: qsTr("Setting up the boot menu…"),
        desktop: qsTr("Installing the desktop and apps…"),
        settings: qsTr("Applying settings…"),
        finish: qsTr("Finishing…")
    })
    readonly property var promises: [
        [qsTr("Familiar"), qsTr("Taskbar, Start menu and the shortcuts you know – Glassfort works the way you expect.")],
        [qsTr("Beautiful"), qsTr("One consistent glass design, light or dark, across the whole system.")],
        [qsTr("Unbreakable"), qsTr("Every change can be undone – even if your system won't start.")],
        [qsTr("Secure"), qsTr("Encryption, firewall and AppArmor are on from the first minute.")],
        [qsTr("No excuses"), qsTr("Need a Windows app? It can run in a window next to your other apps.")],
        [qsTr("Open"), qsTr("Open source, no hidden extras. Your computer belongs to you.")]
    ]
    property int slide: 0

    Connections {
        target: installer
        function onProgress(stage, percent) {
            page.stage = stage;
            page.percent = Math.max(page.percent, percent);
        }
    }

    Timer {
        interval: 9000
        repeat: true
        running: page.active && page.error === ""
        onTriggered: page.slide = (page.slide + 1) % page.promises.length
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing * 2
        spacing: Kirigami.Units.largeSpacing * 2

        Item {
            Layout.fillHeight: true
        }
        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            source: "glassfort"
            implicitWidth: Kirigami.Units.iconSizes.enormous
            implicitHeight: implicitWidth
        }
        Kirigami.Heading {
            Layout.alignment: Qt.AlignHCenter
            visible: page.error === ""
            level: 1
            text: page.promises[page.slide][0]
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 28
            Layout.alignment: Qt.AlignHCenter
            visible: page.error === ""
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: page.promises[page.slide][1]
        }
        Item {
            Layout.fillHeight: true
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: page.error !== ""
            type: Kirigami.MessageType.Error
            text: qsTr("The installation failed: %1. Your data on other disks was not touched. Details: /var/log/glassfort-install.log").replace("%1", page.error)
        }
        QQC2.Label {
            visible: page.error === ""
            text: page.stageText[page.stage] || ""
            opacity: 0.8
        }
        // Created only while installing: Breeze's ProgressBar runs its
        // indeterminate animation all the time (running: true), even when
        // hidden, which keeps the whole window repainting.
        Loader {
            Layout.fillWidth: true
            active: page.active
            sourceComponent: QQC2.ProgressBar {
                from: 0
                to: 100
                value: page.percent
                indeterminate: page.percent === 0 && page.error === ""
            }
        }
    }
}
