// SPDX-License-Identifier: GPL-3.0-or-later
// Screen 3: disk. Default: erase the whole disk, encrypted (docs/04).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    required property var plan
    property bool active: false
    readonly property string title: qsTr("Disk")
    readonly property bool canContinue: plan.disk !== "" && confirm.checked

    signal edited(string key, var value)

    onActiveChanged: if (active)
        installer.refreshDisks()

    Connections {
        target: installer
        function onDisksChanged() {
            // Preselect the only (or first) big enough disk.
            const ok = installer.disks.filter(d => d.big_enough);
            if (page.plan.disk === "" && ok.length > 0)
                page.edited("disk", ok[0].path);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Glassfort uses the whole disk. It is encrypted, so nobody can read your files without your password – even if the computer is stolen.")
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                model: installer.disks
                clip: true
                spacing: Kirigami.Units.smallSpacing
                delegate: QQC2.ItemDelegate {
                    id: disk
                    required property var modelData
                    width: ListView.view.width
                    enabled: modelData.big_enough
                    highlighted: page.plan.disk === modelData.path
                    onClicked: {
                        page.edited("disk", modelData.path);
                        confirm.checked = false;
                    }
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            source: disk.modelData.removable ? "drive-removable-media" : disk.modelData.transport === "nvme" ? "drive-harddisk-solidstate" : "drive-harddisk"
                            implicitWidth: Kirigami.Units.iconSizes.large
                            implicitHeight: implicitWidth
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            QQC2.Label {
                                text: disk.modelData.label
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            QQC2.Label {
                                text: disk.modelData.big_enough ? disk.modelData.sizeText + " · " + disk.modelData.path : qsTr("%1 – too small (at least 40 GB)").replace("%1", disk.modelData.sizeText)
                                opacity: 0.7
                            }
                        }
                    }
                }
                Kirigami.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.gridUnit * 4
                    visible: parent.count === 0
                    icon.name: "drive-harddisk"
                    text: qsTr("No disk found")
                    explanation: qsTr("Glassfort needs a disk with at least 40 GB.")
                }
            }
        }

        QQC2.CheckBox {
            id: confirm
            Layout.fillWidth: true
            enabled: page.plan.disk !== ""
            text: qsTr("Erase everything on this disk and install Glassfort")
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: confirm.checked
            type: Kirigami.MessageType.Warning
            text: qsTr("All files, programs and systems on %1 will be deleted.").replace("%1", page.plan.disk)
        }

        QQC2.CheckBox {
            Layout.fillWidth: true
            checked: page.plan.encrypt
            text: qsTr("Encrypt the disk (recommended)")
            onToggled: page.edited("encrypt", checked)
        }
    }
}
