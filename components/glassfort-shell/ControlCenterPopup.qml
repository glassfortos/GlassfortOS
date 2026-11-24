/*
    SPDX-License-Identifier: GPL-3.0-or-later

    The open control center: quick toggles in a 2-column grid, then the
    volume and brightness sliders, then a link to System Settings.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.bluezqt as BluezQt
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.brightnesscontrolplugin as Brightness

PlasmaExtras.Representation {
    id: popup

    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.preferredWidth: Layout.minimumWidth
    Layout.minimumHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
    Layout.preferredHeight: Layout.minimumHeight

    collapseMarginsHint: true

    Keys.onEscapePressed: root.expanded = false

    contentItem: ColumnLayout {
        id: content
        spacing: Kirigami.Units.largeSpacing

        GridLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            columns: 2
            columnSpacing: Kirigami.Units.smallSpacing * 2
            rowSpacing: Kirigami.Units.smallSpacing * 2
            uniformCellWidths: true

            ControlCenterTile {
                text: i18n("Wi-Fi")
                iconName: root.enabledConnections.wirelessEnabled ? "network-wireless-symbolic" : "network-wireless-disconnected-symbolic"
                subtitle: !root.enabledConnections.wirelessHwEnabled ? i18n("Turned off by a switch")
                    : root.enabledConnections.wirelessEnabled ? root.networkStatus.activeConnections : i18n("Off")
                checkable: true
                checked: root.enabledConnections.wirelessEnabled
                enabled: root.enabledConnections.wirelessHwEnabled
                onToggled: root.networkHandler.enableWireless(checked)
            }

            ControlCenterTile {
                text: i18n("Bluetooth")
                iconName: root.bluetoothOn ? "network-bluetooth-symbolic" : "network-bluetooth-inactive-symbolic"
                subtitle: !root.bluetoothAvailable ? i18n("Not available")
                    : !root.bluetoothOn ? i18n("Off")
                    : BluezQt.Manager.connectedDevices.length > 0 ? i18np("%1 device connected", "%1 devices connected", BluezQt.Manager.connectedDevices.length)
                    : i18n("On")
                checkable: true
                checked: root.bluetoothOn
                enabled: root.bluetoothAvailable
                onToggled: root.setBluetooth(checked)
            }

            ControlCenterTile {
                text: i18n("Do Not Disturb")
                iconName: root.doNotDisturb ? "notifications-disabled-symbolic" : "notifications-symbolic"
                subtitle: root.doNotDisturb ? i18n("On") : i18n("Off")
                checkable: true
                checked: root.doNotDisturb
                onToggled: root.setDoNotDisturb(checked)
            }

            ControlCenterTile {
                text: i18n("Dark Mode")
                iconName: "lighttable-symbolic"
                subtitle: Brightness.DarkModeControl.darkMode ? i18n("On") : i18n("Off")
                checkable: true
                checked: Brightness.DarkModeControl.darkMode
                onToggled: Brightness.DarkModeControl.darkMode = checked
            }

            ControlCenterTile {
                text: i18n("Night Light")
                iconName: root.nightLightActive ? "redshift-status-on" : "redshift-status-off"
                subtitle: !root.nightLightAvailable ? i18n("Not available") : root.nightLightActive ? i18n("On") : i18n("Off")
                checkable: true
                checked: root.nightLightActive
                enabled: root.nightLightAvailable
                onToggled: root.toggleNightLight()
            }

            ControlCenterTile {
                text: i18n("Record Screen")
                iconName: "media-record-symbolic"
                subtitle: i18n("Choose an area")
                onClicked: root.startRecording()
            }
        }

        ControlCenterSlider {
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            visible: root.sink !== null
            text: i18n("Volume")
            iconName: root.sink && root.sink.muted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
            buttonText: root.sink && root.sink.muted ? i18n("Unmute") : i18n("Mute")
            from: 0
            to: root.normalVolume
            stepSize: root.normalVolume / 100
            value: root.sink ? root.sink.volume : 0
            onMoved: value => {
                root.sink.volume = Math.round(value);
                root.sink.muted = value <= 0;
            }
            onButtonClicked: root.sink.muted = !root.sink.muted
        }

        Repeater {
            model: root.screenBrightness.isBrightnessAvailable ? root.screenBrightness.displays : null
            delegate: ControlCenterSlider {
                required property string displayName
                required property string label
                required property int brightness
                required property int maxBrightness

                Layout.leftMargin: Kirigami.Units.largeSpacing
                Layout.rightMargin: Kirigami.Units.largeSpacing
                text: root.screenBrightness.displays.rowCount() > 1 ? i18n("Brightness – %1", label) : i18n("Brightness")
                iconName: "video-display-brightness"
                from: 0
                to: maxBrightness
                stepSize: Math.max(1, maxBrightness / 100)
                value: brightness
                onMoved: value => root.screenBrightness.setBrightness(displayName, Math.round(value))
            }
        }

        PC3.ToolButton {
            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            text: i18n("All Settings")
            icon.name: "configure-symbolic"
            onClicked: {
                root.expanded = false;
                root.launcher.connectSource("systemsettings");
            }
        }
    }
}
