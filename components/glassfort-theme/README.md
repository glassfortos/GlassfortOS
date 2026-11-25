# glassfort-theme

The Glassfort look: global theme, colour schemes, application themes and
wallpaper. Specification:
[`docs/03-desktop-design.md`](../../docs/03-desktop-design.md#visual-language).
Palette: D-22, dependencies: D-34 in
[`docs/DECISIONS.md`](../../docs/DECISIONS.md).

## Files

| File | Installed to | Purpose |
|---|---|---|
| `GlassfortLight.colors`, `GlassfortDark.colors` | `/usr/share/color-schemes/` | Plasma colour schemes |
| `kitty-glassfort-light.conf`, `kitty-glassfort-dark.conf` | `/usr/share/glassfort/kitty/` | kitty colours |
| `kitty.conf` | `/etc/xdg/kitty/` | Default kitty config: JetBrains Mono, slight translucency, Glassfort colours |
| – (symlinks) | `/etc/xdg/kitty/{dark,light}-theme.auto.conf` | kitty follows the desktop's light/dark setting |
| `kvantum-*.kvconfig`, `kvantum-*.svg` (generated) | `/usr/share/Kvantum/Glassfort/` | Kvantum Qt widget style, light (`Glassfort`) and dark (`GlassfortDark`) |
| `gtk{3,4}-gtk.css`, `gtk{3,4}-gtk-dark.css` (generated), `gtk-index.theme` | `/usr/share/themes/Glassfort/` | GTK theme: adw-gtk3 with the Glassfort accent and surfaces |
| `wallpaper-{light,dark}.svg` (generated), `wallpaper-metadata.json` | `/usr/share/wallpapers/Glassfort/` | Desktop wallpaper; PNGs rendered at build time |
| `lnf-{light,dark}-metadata.json`, `lnf-{light,dark}-defaults` | `/usr/share/plasma/look-and-feel/org.glassfort{,.dark}.desktop/` | Global themes Glassfort and Glassfort Dark (preview rendered at build time) |
| `xdg-kdeglobals` | `/etc/xdg/kdeglobals` | Glassfort as default global theme, light/dark by time of day |
| `lnf-splash.qml` | `…/org.glassfort.desktop/contents/splash/Splash.qml` | Start splash after login (Midnight, Glassfort symbol, dots – continues the Plymouth splash); both global themes use it |
| `xdg-kscreenlockerrc` | `/etc/xdg/kscreenlockerrc` | Glassfort wallpaper on the lock screen (light/dark with the colour scheme) |
| `xdg-kvantum.kvconfig` | `/etc/xdg/Kvantum/kvantum.kvconfig` | Glassfort as default Kvantum theme |
| `gtk-settings.ini` | `/etc/gtk-{3,4}.0/`, `/etc/skel/.config/gtk-{3,4}.0/` | Makes `Glassfort` the default GTK theme |

## Colours

| Scheme | Accent | Selection | Why |
|---|---|---|---|
| Glassfort Light | Fort Indigo `#4C4FE0` | white text on indigo (6.0:1) | Teal is too light for text on Frost |
| Glassfort Dark | Glacier Teal `#3DD6C6` | Midnight text on teal (10.3:1) | Teal reads well on Midnight |

All text colours (normal, inactive, link, positive, neutral, negative) reach
at least WCAG AA (4.5:1) on window, view and button backgrounds.

## kitty

kitty reads `/etc/xdg/kitty/` only if the user has no
`~/.config/kitty/kitty.conf` (checked with kitty 0.49). The `*.auto.conf`
files must live in the same directory; a user with an own config can
include `/usr/share/glassfort/kitty/glassfort-dark.conf` or
`glassfort-light.conf`.

## Kvantum

`generate` writes both Kvantum themes from the two `.colors`
files, so Qt widgets and Plasma share one palette. Never edit the
`kvantum-*` files by hand; change the generator or the colour
scheme and run it again:

```sh
./generate          # rewrite the generated files
./generate --check  # CI: files up to date, SVG objects present, contrast
```

Look: rounded corners (5 px controls, 6 px menus), flat buttons with a
thin border, accent-coloured selection, check boxes and focus rings,
overlay scrollbars, pill-shaped sliders and progress bars. Menus and
tooltips are translucent; KWin blurs what is behind them. Widgets the
generator does not draw (dial, MDI title bar buttons, scrollbar grip)
fall back to Kvantum's built-in default theme.

Kvantum chooses the theme by widget style name: `kvantum` →
`Glassfort`, `kvantum-dark` → `GlassfortDark`. Selecting the theme in
`~/.config/Kvantum/kvantum.kvconfig` (`theme=Glassfort`) is the Global
Theme's job.

After changing the generator, update the `sha256sums` of the generated
files in the PKGBUILD (`updpkgsums`).

## GTK

The GTK theme `Glassfort` imports adw-gtk3 (package `adw-gtk-theme`)
and only redefines its named colours: accent, window, view, header bar,
sidebar, cards, dialogs and popovers. `generate` writes the CSS from
the same colour schemes. Status colours (destructive, success, warning,
error) keep adw-gtk3's values.

- Light/dark: GTK loads `gtk-dark.css` when
  `gtk-application-prefer-dark-theme` is set. Plasma's kde-gtk-config
  sets it whenever the colour scheme is dark.
- Plasma does not colour adw-gtk3: kde-gtk-config writes only
  `*_breeze` colours into `~/.config/gtk-*/colors.css`, which only
  Breeze-GTK reads. That is why the colours live in the theme itself.
- Default theme: on a user's first Plasma login, kde-gtk-config's
  `gtk_theme` update script switches an empty `gtk-theme-name` to
  Breeze. The copy in `/etc/skel` prevents this for new users; users
  that already exist keep their setting.
- libadwaita apps (GTK4 with Adwaita widgets) ignore GTK themes. They
  take the accent from the desktop portal; check this in the Plasma VM.

Checked headless (GTK 3.24 and 4.22 on Broadway, `GTK_THEME=Glassfort`
and `Glassfort:dark`): the overrides apply, including derived colours
such as `theme_selected_bg_color`.

## Wallpaper

A vector recreation of the maintainer's wallpaper draft: frosted-glass
shapes in teal and indigo frame an empty centre, on Midnight (dark) and
Frost (light). Desktop version without logo (D-35); variants with the
logo for login and lock screen follow with `glassfort-branding`.

`generate` draws the shapes from a fixed list and seed, so the output is
reproducible. The shapes use gradients only: blur filters looked better in
places but leave light seams at the image edges. On top, a dither filter
adds zero-mean grain (picture + k·(noise − 0.5), `feComposite
arithmetic`), so the smooth dark gradients no longer band in 8-bit PNGs
while the average colours stay the palette's. The PKGBUILD renders
3840×2160 and 1920×1080 PNGs with `rsvg-convert` (makedepends
`librsvg`), so no rendered images are committed. The Plasma wallpaper
package has `contents/images` (light) and `contents/images_dark`
(dark); Plasma switches between them with the colour scheme.

Licence: CC BY-SA 4.0 (artwork, D-21).

## Global theme

Two Plasma global themes tie everything together:

| | Glassfort (`org.glassfort.desktop`) | Glassfort Dark (`org.glassfort.dark.desktop`) |
|---|---|---|
| Colour scheme | GlassfortLight | GlassfortDark |
| Widget style | `kvantum` (Kvantum theme Glassfort) | `kvantum-dark` (GlassfortDark) |
| Fonts | Inter 10 (window titles Semibold), JetBrains Mono 10 | same |
| Wallpaper | Glassfort | Glassfort |
| Icons | Breeze | Breeze Dark |

Cursor, Plasma style and window decoration stay Breeze until Glassfort
ships its own (`glassfort-shell`, `glassfort-branding`). No
panel layout yet; that also comes with `glassfort-shell`.

How the defaults reach a user (from plasma-workspace's `startplasma`):
at every login Plasma reads `[KDE] LookAndFeelPackage` from kdeglobals,
including `/etc/xdg/kdeglobals`, and writes the theme's `defaults` to
`~/.config/kdedefaults`. Those act as defaults; whatever the user sets
in System Settings wins. With `AutomaticLookAndFeel=true` Plasma picks
`DefaultLightLookAndFeel` or `DefaultDarkLookAndFeel` by time of day,
which implements the light/dark rule in
[`docs/03-desktop-design.md`](../../docs/03-desktop-design.md#visual-language).
Users who already chose a global theme keep it.

GTK follows on its own (see GTK above): kde-gtk-config sets the dark
preference whenever the colour scheme is dark.

Checked: both packages load with `kpackagetool6`; `kreadconfig6` reads
every value; font strings are in Qt's `QFont::toString` format. Not
checked yet: a real Plasma session (VM test).

## Build

```sh
cd components/glassfort-theme
extra-x86_64-build      # clean chroot (devtools)
```
