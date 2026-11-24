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

`kvantum/generate` writes both Kvantum themes from the two `.colors`
files, so Qt widgets and Plasma share one palette. Never edit the
`kvantum-*` files by hand; change the generator or the colour
scheme and run it again:

```sh
kvantum/generate          # rewrite the theme files
kvantum/generate --check  # CI: files up to date, SVG objects present, contrast
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

After changing the generator, update the four `sha256sums` in the
PKGBUILD (`updpkgsums`).

## Planned

GTK settings (adw-gtk3 with the accent colour), placeholder
wallpapers (D-35) and the Global Theme that ties them together.

## Build

```sh
cd components/glassfort-theme
extra-x86_64-build      # clean chroot (devtools)
```
