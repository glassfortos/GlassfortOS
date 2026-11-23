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

## Planned

Kvantum theme, GTK settings (adw-gtk3 with the accent colour), placeholder
wallpapers (D-35) and the Global Theme that ties them together.

## Build

```sh
cd components/glassfort-theme
extra-x86_64-build      # clean chroot (devtools)
```
