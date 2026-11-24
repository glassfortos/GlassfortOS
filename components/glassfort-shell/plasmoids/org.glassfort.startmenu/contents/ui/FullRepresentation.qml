/*
    SPDX-License-Identifier: GPL-3.0-or-later

    The open start menu: search on top, then either the home page (pinned
    apps, recent files), all apps, or search results; user and power at
    the bottom.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.coreaddons as KCoreAddons
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

PlasmaExtras.Representation {
    id: menu

    readonly property int columns: 6
    readonly property real cellSize: Kirigami.Units.iconSizes.large + Kirigami.Units.gridUnit * 3
    readonly property bool searching: searchField.text.length > 0
    property bool showAllApps: false

    Layout.minimumWidth: columns * cellSize + Kirigami.Units.largeSpacing * 4
    Layout.preferredWidth: Layout.minimumWidth
    Layout.minimumHeight: Kirigami.Units.gridUnit * 34
    Layout.preferredHeight: Layout.minimumHeight

    collapseMarginsHint: true

    function close() {
        root.expanded = false;
    }

    // Typing anywhere in the menu goes to the search field.
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (searching) {
                searchField.clear();
            } else if (showAllApps) {
                showAllApps = false;
            } else {
                close();
            }
            event.accepted = true;
        } else if (event.text.length > 0 && !searchField.activeFocus && event.text.trim().length > 0) {
            searchField.forceActiveFocus();
            searchField.text += event.text;
            event.accepted = true;
        }
    }

    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                menu.showAllApps = false;
                searchField.clear();
                searchField.forceActiveFocus();
            }
        }
    }

    header: PlasmaExtras.PlasmoidHeading {
        contentItem: PlasmaExtras.SearchField {
            id: searchField
            placeholderText: i18n("Search apps, files and settings")
            focus: true
            onTextChanged: root.runnerModel.query = text
            Keys.onDownPressed: event => {
                const view = menu.searching ? searchView : (menu.showAllApps ? allAppsView : pinnedView);
                view.forceActiveFocus();
                view.currentIndex = 0;
            }
            function launchFirst() {
                if (menu.searching && searchView.count > 0) {
                    searchView.currentIndex = 0;
                    (searchView.currentItem as ResultRow).clicked();
                }
            }
            Keys.onReturnPressed: launchFirst()
            Keys.onEnterPressed: launchFirst()
        }
    }

    contentItem: Item {
        // Home: pinned apps and recent files.
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            visible: !menu.searching && !menu.showAllApps
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 4
                    text: i18n("Pinned")
                }
                PC3.ToolButton {
                    text: i18n("All apps")
                    icon.name: "go-next-symbolic"
                    LayoutMirroring.enabled: true
                    onClicked: menu.showAllApps = true
                }
            }

            GridView {
                id: pinnedView
                Layout.fillWidth: true
                Layout.preferredHeight: menu.cellSize * 3
                clip: true
                cellWidth: Math.floor(width / menu.columns)
                cellHeight: menu.cellSize
                keyNavigationWraps: false
                model: root.rootModel.favoritesModel
                delegate: AppTile {
                    sourceModel: root.rootModel.favoritesModel
                    onLaunched: menu.close()
                }
                Keys.onReturnPressed: (currentItem as PC3.ItemDelegate)?.clicked()
                Keys.onUpPressed: event => {
                    if (currentIndex < menu.columns) {
                        searchField.forceActiveFocus();
                    } else {
                        moveCurrentIndexUp();
                    }
                }
                PlasmaExtras.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.gridUnit * 4
                    visible: pinnedView.count === 0
                    text: i18n("No pinned apps")
                    explanation: i18n("Right-click an app in All apps to pin it here.")
                }
            }

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 4
                text: i18n("Recent files")
            }

            ListView {
                id: recentView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.recentFilesModel
                delegate: ResultRow {
                    sourceModel: root.recentFilesModel
                    onLaunched: menu.close()
                }
                Keys.onReturnPressed: (currentItem as PC3.ItemDelegate)?.clicked()
                PlasmaExtras.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.gridUnit * 4
                    visible: recentView.count === 0
                    text: i18n("No recent files")
                }
            }
        }

        // All apps, alphabetical.
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            visible: !menu.searching && menu.showAllApps
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                PC3.ToolButton {
                    icon.name: "go-previous-symbolic"
                    text: i18n("Back")
                    onClicked: menu.showAllApps = false
                }
                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 4
                    text: i18n("All apps")
                }
            }

            PC3.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ListView {
                    id: allAppsView
                    model: root.appsModel
                    section.property: "display"
                    section.criteria: ViewSection.FirstCharacter
                    section.delegate: Kirigami.ListSectionHeader {
                        required property string section
                        width: ListView.view.width
                        text: section.toUpperCase()
                    }
                    delegate: ResultRow {
                        sourceModel: root.appsModel
                        onLaunched: menu.close()
                    }
                    Keys.onReturnPressed: (currentItem as PC3.ItemDelegate)?.clicked()
                }
            }
        }

        // Search results.
        PC3.ScrollView {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            visible: menu.searching

            ListView {
                id: searchView
                // modelForRow does not notify; re-evaluate when the count changes.
                model: root.runnerModel.count ? root.runnerModel.modelForRow(0) : null
                highlightMoveDuration: 0
                delegate: ResultRow {
                    sourceModel: searchView.model
                    onLaunched: menu.close()
                }
                Keys.onReturnPressed: (currentItem as PC3.ItemDelegate)?.clicked()
                Keys.onUpPressed: event => {
                    if (currentIndex === 0) {
                        searchField.forceActiveFocus();
                    } else {
                        decrementCurrentIndex();
                    }
                }
                PlasmaExtras.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.gridUnit * 4
                    visible: searchView.count === 0 && !root.runnerModel.querying
                    iconName: "edit-none"
                    text: i18n("No results")
                }
            }
        }
    }

    footer: PlasmaExtras.PlasmoidHeading {
        position: PC3.ToolBar.Footer
        contentItem: RowLayout {
            KCoreAddons.KUser {
                id: kuser
            }

            KirigamiComponents.Avatar {
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                source: kuser.faceIconUrl
                name: kuser.fullName || kuser.loginName
            }
            PC3.Label {
                Layout.fillWidth: true
                text: kuser.fullName || kuser.loginName
                elide: Text.ElideRight
            }

            PC3.ToolButton {
                id: powerButton
                icon.name: "system-shutdown-symbolic"
                text: i18n("Power")
                display: PC3.AbstractButton.IconOnly
                PC3.ToolTip.text: text
                PC3.ToolTip.visible: hovered
                onClicked: powerMenu.open()

                PlasmaExtras.Menu {
                    id: powerMenu
                    visualParent: powerButton
                    placement: PlasmaExtras.Menu.TopPosedLeftAlignedPopup
                }

                Instantiator {
                    model: root.systemModel
                    delegate: PlasmaExtras.MenuItem {
                        required property int index
                        required property var model
                        text: model.display
                        icon: model.decoration
                        visible: String(Plasmoid.configuration.powerActions).split(",").includes(model.favoriteId)
                        onClicked: root.systemModel.trigger(index, "", null)
                    }
                    onObjectAdded: (index, object) => {
                        if ((object as PlasmaExtras.MenuItem).visible) {
                            powerMenu.addMenuItem(object);
                        }
                    }
                    onObjectRemoved: (index, object) => powerMenu.removeMenuItem(object)
                }
            }
        }
    }
}
