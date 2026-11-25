// SPDX-License-Identifier: GPL-3.0-or-later
// Done: show the recovery key once (docs/04, screen 4), then restart.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    property string recoveryKey: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing * 2
        spacing: Kirigami.Units.largeSpacing * 2

        Item {
            Layout.fillHeight: true
        }
        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            source: "emblem-success"
            implicitWidth: Kirigami.Units.iconSizes.huge
            implicitHeight: implicitWidth
        }
        Kirigami.Heading {
            Layout.alignment: Qt.AlignHCenter
            level: 1
            text: L10n.tr("Glassfort is installed")
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: page.recoveryKey !== ""
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: L10n.tr("This is your recovery key. If you ever forget your disk password, it is the only way to get to your files. Write it down or take a photo and keep it somewhere safe – it is shown only now.")
            }
            QQC2.TextArea {
                Layout.fillWidth: true
                readOnly: true
                wrapMode: TextEdit.WrapAnywhere
                horizontalAlignment: TextEdit.AlignHCenter
                font.family: "JetBrains Mono"
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.3
                text: page.recoveryKey
            }
            QQC2.CheckBox {
                id: saved
                text: L10n.tr("I have written down my recovery key")
            }
        }

        Item {
            Layout.fillHeight: true
        }
        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            highlighted: true
            icon.name: "system-reboot"
            text: L10n.tr("Restart now")
            enabled: page.recoveryKey === "" || saved.checked
            onClicked: installer.reboot()
        }
        QQC2.Label {
            Layout.alignment: Qt.AlignHCenter
            text: L10n.tr("Remove the USB stick when the computer turns off.")
            opacity: 0.7
        }
    }
}
