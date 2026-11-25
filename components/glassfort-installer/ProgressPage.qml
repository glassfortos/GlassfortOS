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
        start: L10n.tr("Preparing…"),
        disk: L10n.tr("Preparing the disk…"),
        base: L10n.tr("Installing the system…"),
        boot: L10n.tr("Setting up the boot menu…"),
        desktop: L10n.tr("Installing the desktop and apps…"),
        settings: L10n.tr("Applying settings…"),
        finish: L10n.tr("Finishing…")
    })
    readonly property var promises: [
        [L10n.tr("Familiar"), L10n.tr("Taskbar, Start menu and the shortcuts you know – Glassfort works the way you expect.")],
        [L10n.tr("Beautiful"), L10n.tr("One consistent glass design, light or dark, across the whole system.")],
        [L10n.tr("Unbreakable"), L10n.tr("Every change can be undone – even if your system won't start.")],
        [L10n.tr("Secure"), L10n.tr("Encryption, firewall and AppArmor are on from the first minute.")],
        [L10n.tr("No excuses"), L10n.tr("Need a Windows app? It can run in a window next to your other apps.")],
        [L10n.tr("Open"), L10n.tr("Open source, no hidden extras. Your computer belongs to you.")]
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
            text: L10n.tr("The installation failed: %1. Your data on other disks was not touched. Details: /var/log/glassfort-install.log").replace("%1", page.error)
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
