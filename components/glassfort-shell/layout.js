// SPDX-License-Identifier: GPL-3.0-or-later
//
// Glassfort default desktop layout (docs/03-desktop-design.md):
// - slim top bar: system tray, control center, clock
// - floating dock at the bottom, centred: start menu and dock
// Installed as contents/layouts/org.kde.plasma.desktop-layout.js of both
// Glassfort global themes; plasmashell runs it for a new user's first
// session and when the user applies the global theme with its layout.

// Top bar ---------------------------------------------------------------
var topBar = new Panel;
topBar.location = "top";
topBar.height = 2 * Math.ceil(gridUnit * 1.6 / 2);
topBar.floating = false;

// Push everything to the right; the left side stays calm (no global menu).
topBar.addWidget("org.kde.plasma.panelspacer");

var tray = topBar.addWidget("org.kde.plasma.systemtray");
// The control center already covers these; move them to the tray's
// overflow popup. In Plasma 6 the tray is itself a containment, so its
// settings live in its own [General] group.
tray.currentConfigGroup = ["General"];
tray.writeConfig("hiddenItems", [
    "org.kde.plasma.networkmanagement",
    "org.kde.plasma.volume",
    "org.kde.plasma.bluetooth",
    "org.kde.plasma.brightness",
]);

topBar.addWidget("org.glassfort.controlcenter");

var clock = topBar.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", "BesideTime");

// Dock ------------------------------------------------------------------
var dock = new Panel;
dock.location = "bottom";
dock.height = 2 * Math.ceil(gridUnit * 3 / 2);
dock.floating = true;
dock.alignment = "center";
dock.lengthMode = "fit";
dock.hiding = "none";

dock.addWidget("org.glassfort.startmenu");
dock.addWidget("org.glassfort.dock");

// Desktop ---------------------------------------------------------------
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = "org.kde.image";
}
