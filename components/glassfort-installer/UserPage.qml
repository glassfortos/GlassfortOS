// SPDX-License-Identifier: GPL-3.0-or-later
// Screen 4: user account and the disk password.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: page

    required property var plan
    readonly property string title: L10n.tr("Your account")
    readonly property bool nameOk: /^[a-z_][a-z0-9_-]{0,31}$/.test(username.text) && username.text !== "root"
    readonly property bool passwordOk: password.text.length > 0 && password.text === repeat.text
    readonly property bool diskOk: !plan.encrypt || samePassword.checked ? password.text.length >= 8 || !plan.encrypt : diskPassword.text.length >= 8 && diskPassword.text === diskRepeat.text
    readonly property bool canContinue: fullName.text.trim() !== "" && nameOk && passwordOk && diskOk

    signal edited(string key, var value)

    function sync() {
        edited("full_name", fullName.text.trim());
        edited("username", username.text);
        edited("password", password.text);
        edited("disk_passphrase", plan.encrypt && !samePassword.checked ? diskPassword.text : null);
    }

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        QQC2.TextField {
            id: fullName
            Kirigami.FormData.label: L10n.tr("Your name:")
            onTextEdited: {
                if (!username.edited)
                    username.text = installer.suggestUsername(text);
                page.sync();
            }
        }
        QQC2.TextField {
            id: username
            property bool edited: false
            Kirigami.FormData.label: L10n.tr("User name:")
            onTextEdited: {
                edited = true;
                page.sync();
            }
        }
        QQC2.Label {
            visible: username.text !== "" && !page.nameOk
            text: L10n.tr("Lower-case letters, digits, - and _ only.")
            color: Kirigami.Theme.negativeTextColor
        }
        Kirigami.PasswordField {
            id: password
            Kirigami.FormData.label: L10n.tr("Password:")
            onTextEdited: page.sync()
        }
        Kirigami.PasswordField {
            id: repeat
            Kirigami.FormData.label: L10n.tr("Repeat password:")
            onTextEdited: page.sync()
        }
        QQC2.Label {
            visible: repeat.text !== "" && password.text !== repeat.text
            text: L10n.tr("The passwords do not match.")
            color: Kirigami.Theme.negativeTextColor
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            visible: page.plan.encrypt
        }
        QQC2.CheckBox {
            id: samePassword
            visible: page.plan.encrypt
            checked: true
            text: L10n.tr("Use this password to unlock the disk")
            onToggled: page.sync()
        }
        QQC2.Label {
            visible: page.plan.encrypt && samePassword.checked && password.text.length > 0 && password.text.length < 8
            text: L10n.tr("The disk password needs at least 8 characters.")
            color: Kirigami.Theme.negativeTextColor
        }
        Kirigami.PasswordField {
            id: diskPassword
            visible: page.plan.encrypt && !samePassword.checked
            Kirigami.FormData.label: L10n.tr("Disk password:")
            onTextEdited: page.sync()
        }
        Kirigami.PasswordField {
            id: diskRepeat
            visible: page.plan.encrypt && !samePassword.checked
            Kirigami.FormData.label: L10n.tr("Repeat disk password:")
            onTextEdited: page.sync()
        }
    }
}
