// SPDX-License-Identifier: GPL-3.0-or-later
// Glassfort installer: at most five screens (docs/04-installer.md), then
// progress and a final screen with the recovery key.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: window

    // Everything the backend needs (glassfort_install.Plan).
    property var plan: ({
        locale: "en_US",
        keyboard: "us",
        timezone: "America/New_York",
        disk: "",
        encrypt: true,
        username: "",
        full_name: "",
        password: "",
        disk_passphrase: null,
        hostname: "glassfort",
        look: "auto"
    })
    property int step: 0
    readonly property var steps: [languagePage, networkPage, diskPage, userPage, lookPage]
    readonly property bool installing: stack.currentIndex >= steps.length

    title: L10n.tr("Install Glassfort")
    width: Kirigami.Units.gridUnit * 46
    height: Kirigami.Units.gridUnit * 34
    minimumWidth: Kirigami.Units.gridUnit * 34
    minimumHeight: Kirigami.Units.gridUnit * 28
    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.None

    function setPlan(key, value) {
        const p = Object.assign({}, plan);
        p[key] = value;
        plan = p;
    }

    function next() {
        let i = step + 1;
        // Screen 2 (Wi-Fi) is skipped when the computer is wired.
        if (i === 1 && installer.wired && installer.online)
            i = 2;
        if (i < steps.length) {
            step = i;
            stack.currentIndex = i;
        } else {
            stack.currentIndex = steps.length;
            installer.install(plan);
        }
    }

    function back() {
        let i = step - 1;
        if (i === 1 && installer.wired && installer.online)
            i = 0;
        step = Math.max(0, i);
        stack.currentIndex = step;
    }

    Connections {
        target: installer
        function onFinished(recoveryKey) {
            donePage.recoveryKey = recoveryKey;
            stack.currentIndex = window.steps.length + 1;
        }
        function onFailed(message) {
            progressPage.error = message;
        }
    }

    Component.onCompleted: installer.refreshNetwork()

    pageStack.initialPage: Kirigami.Page {
        padding: 0

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Step indicator
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing * 2
                visible: !window.installing
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "glassfort"
                    implicitWidth: Kirigami.Units.iconSizes.medium
                    implicitHeight: Kirigami.Units.iconSizes.medium
                }
                Kirigami.Heading {
                    level: 2
                    text: window.steps[window.step].title
                    Layout.fillWidth: true
                }
                Repeater {
                    model: window.steps.length
                    delegate: Rectangle {
                        required property int index
                        width: Kirigami.Units.gridUnit * (index === window.step ? 1.5 : 0.5)
                        height: Kirigami.Units.gridUnit * 0.5
                        radius: height / 2
                        color: index <= window.step ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                        opacity: index === 1 && installer.wired && installer.online ? 0.3 : 1
                        Behavior on width {
                            NumberAnimation {
                                duration: Kirigami.Units.shortDuration
                            }
                        }
                    }
                }
            }

            StackLayout {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Kirigami.Units.largeSpacing * 3
                Layout.rightMargin: Kirigami.Units.largeSpacing * 3

                LanguagePage {
                    id: languagePage
                    plan: window.plan
                    onEdited: (key, value) => window.setPlan(key, value)
                }
                NetworkPage {
                    id: networkPage
                    active: stack.currentIndex === 1
                }
                DiskPage {
                    id: diskPage
                    plan: window.plan
                    active: stack.currentIndex === 2
                    onEdited: (key, value) => window.setPlan(key, value)
                }
                UserPage {
                    id: userPage
                    plan: window.plan
                    onEdited: (key, value) => window.setPlan(key, value)
                }
                LookPage {
                    id: lookPage
                    plan: window.plan
                    onEdited: (key, value) => window.setPlan(key, value)
                }
                ProgressPage {
                    id: progressPage
                }
                DonePage {
                    id: donePage
                }
            }

            // Navigation
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing * 2
                visible: !window.installing

                QQC2.Button {
                    text: L10n.tr("Back")
                    icon.name: "go-previous"
                    visible: window.step > 0
                    onClicked: window.back()
                }
                Item {
                    Layout.fillWidth: true
                }
                QQC2.Button {
                    id: nextButton
                    readonly property bool last: window.step === window.steps.length - 1
                    text: last ? L10n.tr("Install") : L10n.tr("Continue")
                    icon.name: last ? "run-install" : "go-next"
                    highlighted: true
                    enabled: window.steps[window.step].canContinue
                    onClicked: window.next()
                }
            }
        }
    }
}
