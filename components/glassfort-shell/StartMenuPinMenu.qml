/*
    SPDX-License-Identifier: GPL-3.0-or-later

    Context menu for an app in the start menu: pin to or unpin from the
    pinned grid. Pinned apps are stored by Kicker's favorites model.
*/

import QtQuick
import org.kde.plasma.extras as PlasmaExtras

PlasmaExtras.Menu {
    id: pinMenu

    // Kicker favorite id of the app (usually its .desktop file name).
    property string favoriteId: ""
    readonly property var favorites: root.rootModel.favoritesModel
    readonly property bool pinned: favoriteId.length > 0 && favorites.isFavorite(favoriteId)

    PlasmaExtras.MenuItem {
        text: pinMenu.pinned ? i18n("Unpin from Start") : i18n("Pin to Start")
        icon: pinMenu.pinned ? "window-unpin" : "window-pin"
        onClicked: {
            if (pinMenu.pinned) {
                pinMenu.favorites.removeFavorite(pinMenu.favoriteId);
            } else {
                pinMenu.favorites.addFavorite(pinMenu.favoriteId);
            }
        }
    }
}
