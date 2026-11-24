# glassfort-theme

The Glassfort look: colour schemes and application themes. Specification:
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
reproducible. Only gradients are used: blur filters looked better in
places but leave light seams at the image edges. The PKGBUILD renders
3840×2160 and 1920×1080 PNGs with `rsvg-convert` (makedepends
`librsvg`), so no rendered images are committed. The Plasma wallpaper
package has `contents/images` (light) and `contents/images_dark`
(dark); Plasma switches between them with the colour scheme.

Licence: CC BY-SA 4.0 (artwork, D-21).

Known limitation: the dark radial gradients show slight banding when
you look closely at 4K. Dithering at build time would fix it.

## Planned

The Global Theme that ties everything together.

## Build

```sh
cd components/glassfort-theme
extra-x86_64-build      # clean chroot (devtools)
```
