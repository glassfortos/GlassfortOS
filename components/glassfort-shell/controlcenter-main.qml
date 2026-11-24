/*
    SPDX-License-Identifier: GPL-3.0-or-later

    Glassfort control center (docs/03-desktop-design.md, D-36): one button
    in the top bar that opens quick settings. Every tile uses the backend
    of the matching Plasma applet:
      Wi-Fi             plasma-nm (org.kde.plasma.networkmanagement)
      Bluetooth         bluez-qt (org.kde.bluezqt), as in bluedevil
      Volume            plasma-pa (org.kde.plasma.private.volume)
      Brightness, dark  powerdevil (org.kde.plasma.private.brightnesscontrolplugin)
      Night light       KWin's org.kde.KWin.NightLight D-Bus interface
      Do not disturb    org.kde.notificationmanager
      Screen recording  Spectacle (spectacle -R)
*/

import QtQuick
import QtQuick.Layouts
import org.kde.bluezqt as BluezQt
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import org.kde.plasma.private.brightnesscontrolplugin as Brightness
import org.kde.plasma.private.volume as Volume
import org.kde.plasma.workspace.dbus as DBus

PlasmoidItem {
    id: root

    // --- Network --------------------------------------------------------
    readonly property PlasmaNM.EnabledConnections enabledConnections: PlasmaNM.EnabledConnections {}
    readonly property PlasmaNM.Handler networkHandler: PlasmaNM.Handler {}
    readonly property PlasmaNM.NetworkStatus networkStatus: PlasmaNM.NetworkStatus {}
    readonly property PlasmaNM.ConnectionIcon connectionIcon: PlasmaNM.ConnectionIcon {}

    // --- Bluetooth ------------------------------------------------------
    readonly property bool bluetoothAvailable: BluezQt.Manager.adapters.length > 0
    readonly property bool bluetoothOn: bluetoothAvailable && !BluezQt.Manager.bluetoothBlocked && (BluezQt.Manager.usableAdapter !== null)
    function setBluetooth(on: bool): void {
        BluezQt.Manager.bluetoothBlocked = !on;
        BluezQt.Manager.adapters.forEach(adapter => {
            adapter.powered = on;
        });
    }

    // --- Volume ---------------------------------------------------------
    readonly property var sink: Volume.PreferredDevice.sink
    readonly property real normalVolume: Volume.PulseAudio.NormalVolume

    // --- Brightness -----------------------------------------------------
    readonly property Brightness.ScreenBrightnessControl screenBrightness: Brightness.ScreenBrightnessControl {
        isSilent: false
    }

    // --- Night light ----------------------------------------------------
    readonly property DBus.Properties nightLight: DBus.Properties {
        busType: DBus.BusType.Session
        service: "org.kde.KWin.NightLight"
        path: "/org/kde/KWin/NightLight"
        iface: "org.kde.KWin.NightLight"
    }
    readonly property bool nightLightAvailable: Boolean(nightLight.properties.available)
    readonly property bool nightLightActive: Boolean(nightLight.properties.running) && Number(nightLight.properties.currentTemperature) !== 6500
    function nightLightCall(member: string, on: bool): void {
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin.NightLight",
            path: "/org/kde/KWin/NightLight",
            iface: "org.kde.KWin.NightLight",
            member: member,
            arguments: [on],
            signature: "(b)"
        });
    }
    function toggleNightLight(): void {
        // Undo a manual override first, otherwise override the schedule.
        if (nightLight.properties.activatedManual) {
            nightLightCall("activateManual", false);
        } else if (nightLight.properties.deactivatedManual) {
            nightLightCall("deactivateManual", false);
        } else if (nightLightActive) {
            nightLightCall("deactivateManual", true);
        } else {
            nightLightCall("activateManual", true);
        }
    }

    // --- Do not disturb -------------------------------------------------
    readonly property NotificationManager.Settings notificationSettings: NotificationManager.Settings {}
    readonly property bool doNotDisturb: NotificationManager.Server.inhibited
    function setDoNotDisturb(on: bool): void {
        if (on) {
            // "Until turned off": the same far-future date Plasma uses.
            const until = new Date();
            until.setFullYear(until.getFullYear() + 1);
            notificationSettings.notificationsInhibitedUntil = until;
        } else {
            notificationSettings.notificationsInhibitedUntil = new Date(0);
            notificationSettings.revokeApplicationInhibitions();
        }
        notificationSettings.save();
    }

    // --- Screen recording -----------------------------------------------
    readonly property P5Support.DataSource launcher: P5Support.DataSource {
        engine: "executable"
        connectedSources: []
        onNewData: sourceName => disconnectSource(sourceName)
    }
    function startRecording(): void {
        const mode = ["r", "s", "w"].includes(Plasmoid.configuration.recordMode) ? Plasmoid.configuration.recordMode : "r";
        root.expanded = false;
        launcher.connectSource("spectacle -R " + mode);
    }

    Plasmoid.icon: connectionIcon.connectionIcon
    toolTipMainText: i18n("Control Center")
    toolTipSubText: i18n("Wi-Fi, Bluetooth, sound, brightness and quick settings")

    preferredRepresentation: compactRepresentation
    compactRepresentation: ControlCenterButton {}
    fullRepresentation: ControlCenterPopup {}
}
