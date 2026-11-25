// SPDX-License-Identifier: GPL-3.0-or-later
// Screen 1: language, keyboard layout and time zone.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    required property var plan
    readonly property string title: L10n.tr("Language and keyboard")
    readonly property bool canContinue: plan.locale !== "" && plan.keyboard !== ""

    signal edited(string key, var value)

    function indexOf(list, key, value) {
        for (let i = 0; i < list.length; i++) {
            if ((key ? list[i][key] : list[i]) === value)
                return i;
        }
        return -1;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: L10n.tr("Welcome to Glassfort. Choose your language – the keyboard layout and time zone follow, and you can change them below.")
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: languages
                model: installer.languages
                clip: true
                currentIndex: page.indexOf(installer.languages, "locale", page.plan.locale)
                delegate: QQC2.ItemDelegate {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    text: modelData.name
                    highlighted: ListView.isCurrentItem
                    onClicked: {
                        installer.setLanguage(modelData.locale);
                        page.edited("locale", modelData.locale);
                        page.edited("keyboard", modelData.keyboard);
                        page.edited("timezone", modelData.timezone);
                        installer.setKeyboard(modelData.keyboard);
                    }
                }
            }
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true

            QQC2.ComboBox {
                Kirigami.FormData.label: L10n.tr("Keyboard layout:")
                model: installer.keyboards
                textRole: "name"
                valueRole: "keymap"
                currentIndex: page.indexOf(installer.keyboards, "keymap", page.plan.keyboard)
                onActivated: {
                    page.edited("keyboard", currentValue);
                    installer.setKeyboard(currentValue);
                }
            }
            QQC2.TextField {
                Kirigami.FormData.label: L10n.tr("Try your keyboard:")
                placeholderText: L10n.tr("Type here to test the layout")
            }
            QQC2.ComboBox {
                Kirigami.FormData.label: L10n.tr("Time zone:")
                model: installer.timezones
                currentIndex: page.indexOf(installer.timezones, "", page.plan.timezone)
                onActivated: page.edited("timezone", currentText)
            }
        }
    }
}
