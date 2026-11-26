// SPDX-License-Identifier: GPL-3.0-or-later
// Restore Points (D-45): the snapshot timeline with pin and restore.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.ScrollViewKCM {
    id: root

    implicitWidth: Kirigami.Units.gridUnit * 38
    implicitHeight: Kirigami.Units.gridUnit * 30

    property int pendingRestore: 0
    property string pendingTitle: ""

    header: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        // Booted from the boot menu into a snapshot (docs/02).
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: kcm.bootedSnapshot > 0
            type: Kirigami.MessageType.Warning
            text: i18n("You are running an earlier state of the system. Restore it to keep it; otherwise the next restart goes back to the current state.")
            actions: [
                Kirigami.Action {
                    text: i18n("Restore this state")
                    icon.name: "edit-undo"
                    enabled: !kcm.restoring
                    onTriggered: root.askRestore(kcm.bootedSnapshot, i18n("the state you are running now"))
                }
            ]
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: kcm.error !== ""
            type: Kirigami.MessageType.Error
            text: kcm.error
            actions: [
                Kirigami.Action {
                    text: i18n("Try again")
                    icon.name: "view-refresh"
                    onTriggered: kcm.refresh()
                }
            ]
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            wrapMode: Text.WordWrap
            text: i18n("Glassfort saves a restore point before and after every software change. If something stops working, go back to a point from before the change. Your personal files are not affected.")
        }
    }

    view: ListView {
        id: list
        model: kcm.snapshots
        clip: true
        reuseItems: true

        section.property: "day"
        section.delegate: Kirigami.ListSectionHeader {
            required property string section
            width: ListView.view.width
            text: {
                const d = new Date(section + "T00:00:00");
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                const days = Math.round((today - d) / 86400000);
                if (days === 0)
                    return i18n("Today");
                if (days === 1)
                    return i18n("Yesterday");
                return d.toLocaleDateString(Qt.locale(), Locale.LongFormat);
            }
        }

        delegate: QQC2.ItemDelegate {
            id: row
            required property int number
            required property string kind
            required property date date
            required property string title
            required property string detail
            required property bool pinned
            required property bool booted

            width: ListView.view.width
            hoverEnabled: true
            down: false

            contentItem: RowLayout {
                spacing: Kirigami.Units.largeSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: row.title
                        elide: Text.ElideRight
                        font.bold: row.booted
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: {
                            const time = row.date.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
                            if (row.booted)
                                return i18n("%1 · running now", time);
                            return row.pinned ? i18n("%1 · kept", time) : time;
                        }
                        opacity: 0.7
                        font: Kirigami.Theme.smallFont
                        elide: Text.ElideRight
                    }
                }

                QQC2.ToolButton {
                    icon.name: row.pinned ? "window-pin" : "window-unpin"
                    checkable: true
                    checked: row.pinned
                    display: QQC2.AbstractButton.IconOnly
                    text: row.pinned ? i18n("Do not keep") : i18n("Keep")
                    QQC2.ToolTip.text: row.pinned ? i18n("Allow this restore point to be removed when it gets old") : i18n("Keep this restore point when older ones are removed")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: kcm.setPinned(row.number, !row.pinned)
                }

                QQC2.Button {
                    text: i18n("Restore…")
                    icon.name: "edit-undo"
                    enabled: !kcm.restoring && !row.booted
                    onClicked: root.askRestore(row.number, row.title + " (" + row.date.toLocaleString(Qt.locale(), Locale.ShortFormat) + ")")
                }
            }
        }

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 4
            visible: list.count === 0 && !kcm.loading && kcm.error === ""
            icon.name: "document-open-recent"
            text: i18n("No restore points yet")
            explanation: i18n("A restore point is saved automatically before and after the next software change.")
        }

        QQC2.BusyIndicator {
            anchors.centerIn: parent
            visible: kcm.loading && list.count === 0
            running: visible
        }
    }

    function askRestore(number, title) {
        pendingRestore = number;
        pendingTitle = title;
        confirmDialog.open();
    }

    Kirigami.PromptDialog {
        id: confirmDialog
        title: i18n("Restore an earlier state?")
        subtitle: i18n("The system goes back to %1. Programs and settings installed after it are undone; your personal files stay as they are. The current state is kept as a restore point, so you can come back.", root.pendingTitle)
        standardButtons: Kirigami.Dialog.NoButton
        customFooterActions: [
            Kirigami.Action {
                text: i18n("Restore")
                icon.name: "edit-undo"
                onTriggered: {
                    confirmDialog.close();
                    kcm.restore(root.pendingRestore);
                }
            },
            Kirigami.Action {
                text: i18n("Cancel")
                icon.name: "dialog-cancel"
                onTriggered: confirmDialog.close()
            }
        ]
    }

    Kirigami.PromptDialog {
        id: workingDialog
        title: i18n("Restoring…")
        subtitle: i18n("This takes a few seconds. Please do not turn off the computer.")
        standardButtons: Kirigami.Dialog.NoButton
        closePolicy: QQC2.Popup.NoAutoClose
        showCloseButton: false
        visible: kcm.restoring
    }

    Kirigami.PromptDialog {
        id: doneDialog
        title: i18n("Restart to finish")
        subtitle: i18n("The earlier state is restored. It is used from the next restart on.")
        standardButtons: Kirigami.Dialog.NoButton
        customFooterActions: [
            Kirigami.Action {
                text: i18n("Restart now")
                icon.name: "system-reboot"
                onTriggered: kcm.reboot()
            },
            Kirigami.Action {
                text: i18n("Later")
                onTriggered: doneDialog.close()
            }
        ]
    }

    Kirigami.PromptDialog {
        id: failedDialog
        property string message
        title: i18n("Not restored")
        subtitle: message
        standardButtons: Kirigami.Dialog.Ok
    }

    Connections {
        target: kcm
        function onRestored() {
            doneDialog.open();
        }
        function onRestoreFailed(message) {
            failedDialog.message = message;
            failedDialog.open();
        }
    }
}
