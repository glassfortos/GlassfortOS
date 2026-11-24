/*
    SPDX-License-Identifier: GPL-3.0-or-later

    Glassfort start menu (docs/03-desktop-design.md, D-36).
    Data comes from Plasma's Kicker models, the same ones Kickoff uses.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root

    // Pinned apps (favoritesModel, stored per user in KActivities and seeded
    // from the config) and all apps: with these settings row 0 of the root
    // model is "All Applications", a flat alphabetical list.
    readonly property Kicker.RootModel rootModel: Kicker.RootModel {
        autoPopulate: false
        appletInterface: root
        flat: true
        sorted: true
        showSeparators: false
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        showFavoritesPlaceholder: false

        Component.onCompleted: {
            favoritesModel.initForClient("org.glassfort.startmenu.favorites.instance-" + Plasmoid.id);
            if (!Plasmoid.configuration.favoritesPortedToKAstats) {
                if (favoritesModel.count < 1) {
                    favoritesModel.portOldFavorites(Plasmoid.configuration.favorites);
                }
                Plasmoid.configuration.favoritesPortedToKAstats = true;
            }
        }
    }

    // modelForRow() does not notify, so re-read it after every refresh.
    property var appsModel: null
    Connections {
        target: root.rootModel
        function onRefreshed() {
            root.appsModel = root.rootModel.count > 0 ? root.rootModel.modelForRow(0) : null;
        }
    }

    // Search: apps, files, settings and everything else KRunner finds.
    readonly property Kicker.RunnerModel runnerModel: Kicker.RunnerModel {
        appletInterface: root
        mergeResults: true
        favoritesModel: root.rootModel.favoritesModel
    }

    readonly property Kicker.RecentUsageModel recentFilesModel: Kicker.RecentUsageModel {
        shownItems: Kicker.RecentUsageModel.OnlyDocs
        favoritesModel: root.rootModel.favoritesModel
    }

    readonly property Kicker.SystemModel systemModel: Kicker.SystemModel {
        favoritesModel: root.rootModel.systemFavoritesModel
    }

    Plasmoid.icon: Plasmoid.configuration.icon
    toolTipMainText: i18n("Start")
    toolTipSubText: i18n("Search, apps, recent files and power")

    preferredRepresentation: compactRepresentation
    compactRepresentation: StartMenuButton {}
    fullRepresentation: StartMenuPopup {}

    onExpandedChanged: {
        if (!expanded) {
            runnerModel.query = "";
        }
    }

    Component.onCompleted: {
        // Super (via plasmashell's launcher menu activation) opens and closes the menu.
        Plasmoid.activationTogglesExpanded = true;
        rootModel.refresh();
    }
}
