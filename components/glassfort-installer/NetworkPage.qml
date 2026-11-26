// SPDX-License-Identifier: GPL-3.0-or-later
// Screen 2: Wi-Fi (skipped when the computer is wired and online).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    property bool active: false
    readonly property string title: qsTr("Wi-Fi")
    // Glassfort's packages come from the medium, but Arch's base packages
    // are downloaded: the installer needs the internet.
    readonly property bool canContinue: installer.online
    property string selected: ""
    property string error: ""

    onActiveChanged: if (active)
        installer.scanWifi()

    Timer {
        interval: 10000
        repeat: true
        running: page.active && !installer.online
        onTriggered: installer.scanWifi()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: true
            type: installer.online ? Kirigami.MessageType.Positive : Kirigami.MessageType.Information
            text: installer.online ? qsTr("You are connected to the internet.") : qsTr("Glassfort needs the internet to install. Choose a network.")
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                model: installer.wifiNetworks
                clip: true
                delegate: QQC2.ItemDelegate {
                    id: net
                    required property var modelData
                    width: ListView.view.width
                    highlighted: page.selected === modelData.ssid
                    onClicked: {
                        page.selected = modelData.ssid;
                        page.error = "";
                        password.text = "";
                        if (!modelData.secure && !modelData.active)
                            page.error = installer.connectWifi(modelData.ssid, "");
                    }
                    contentItem: RowLayout {
                        Kirigami.Icon {
                            source: net.modelData.signal > 66 ? "network-wireless-signal-excellent" : net.modelData.signal > 33 ? "network-wireless-signal-ok" : "network-wireless-signal-weak"
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                            implicitHeight: implicitWidth
                        }
                        QQC2.Label {
                            text: net.modelData.ssid
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        QQC2.Label {
                            visible: net.modelData.active
                            text: qsTr("Connected")
                            color: Kirigami.Theme.positiveTextColor
                        }
                        Kirigami.Icon {
                            visible: net.modelData.secure
                            source: "object-locked"
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: implicitWidth
                        }
                    }
                }
                QQC2.BusyIndicator {
                    anchors.centerIn: parent
                    running: page.active && parent.count === 0
                    visible: running
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: page.selected !== ""

            Kirigami.PasswordField {
                id: password
                Layout.fillWidth: true
                placeholderText: qsTr("Password for %1").replace("%1", page.selected)
                onAccepted: connect.clicked()
            }
            QQC2.Button {
                id: connect
                text: qsTr("Connect")
                enabled: password.text.length >= 8
                onClicked: page.error = installer.connectWifi(page.selected, password.text)
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: page.error !== ""
            type: Kirigami.MessageType.Error
            text: page.error
        }
    }
}
