# glassfort-desktop

Meta package: `pacman -S glassfort-desktop` turns a plain Arch install into
Glassfort (roadmap Phase 1). It contains only a service preset; everything
else comes through dependencies. Decisions: D-37 to D-40 in
[`docs/DECISIONS.md`](../../docs/DECISIONS.md).

| Group | Packages |
|---|---|
| Glassfort | glassfort-settings, glassfort-theme, glassfort-branding, glassfort-shell, glassfort-mirrorlist |
| Plasma (curated, D-37) | plasma-desktop, plasma-workspace, kwin, systemsettings, kscreen, powerdevil + power-profiles-daemon, plasma-nm, plasma-pa, plasma-firewall, plasma-systemmonitor, kinfocenter, discover + flatpak, kde-gtk-config, breeze, xdg-desktop-portal-kde, kactivitymanagerd, kde-cli-tools, polkit-kde-agent, kwallet-pam, kio-extras, xdg-user-dirs |
| Login (D-38) | sddm, sddm-kcm |
| Boot splash (D-41) | plymouth |
| Sound, network, Bluetooth | pipewire-pulse, wireplumber, networkmanager, bluez, bluez-utils, bluedevil |
| Default apps (docs/03, D-39, D-40) | firefox, libreoffice-fresh, thunderbird, dolphin, okular, gwenview, kate, spectacle, haruna, keepassxc, kitty, ark |
| Fonts | noto-fonts, noto-fonts-emoji (Inter and JetBrains Mono come with glassfort-theme) |

`50-glassfort-desktop.preset` lists the desktop services (SDDM,
NetworkManager, Bluetooth, power profiles). `glassfort-setup` (from
glassfort-settings) enables them together with the system services;
the package's install message says to run it. Packages do not enable
services on their own.

glassfort-keyring is not a dependency yet: it waits for the real
repository key (D-26).

## Build

The package has nothing to compile. In CI it is built with
`makepkg --nodeps` instead of a clean chroot (`# ci: no-chroot` in the
PKGBUILD), which would otherwise download every dependency on each run;
namcap still checks it.

```sh
makepkg --nodeps
```
