# 03 – Desktop, UX and design

**Look like macOS, work like Windows.** KDE Plasma 6 is the base; Glassfort must not look like "another KDE distro". Consistency matters more than effects.

## Layout

- **Top bar** (slim): clock, control center, notifications, system tray. No global menu (Windows switchers expect menus inside the window).
- **Bottom taskbar/dock** (floating panel): pinned apps centred, running indicators, hover previews; click focuses or minimises like Windows.
- Windows **float by default**. Tiling is opt-in via KWin quick tiling and custom tile layouts (`Meta+T`).

## Glassfort widgets (`glassfort-shell`)

| Widget | Requirements |
|---|---|
| Start menu | Opens with `Super`. Search field on top (apps, files, settings, assistant prompt). Grid of pinned apps. Recent files. Power menu. |
| Taskbar/dock | Pinned + running apps, previews, jump lists where available |
| Control center | Tiles for Wi-Fi, Bluetooth, volume, brightness, night light, dark mode, Do Not Disturb, screen recording |
| Snap layouts (later) | KWin script/effect: hovering the maximise button shows layout choices like Windows 11 |
| Shortcut overlay | Holding `Super` shows all important shortcuts |

## Default shortcuts

| Shortcut | Action |
|---|---|
| `Super` | Start menu |
| `Super+E` | File manager (Dolphin) |
| `Super+L` | Lock screen |
| `Super+V` | Clipboard history |
| `Super+Shift+S` | Screenshot of a region (Spectacle) |
| `Super+.` | Emoji picker |
| `Super+Arrow` | Snap window |
| `Ctrl+Shift+Esc` | System monitor |
| `Alt+Tab` | Window switcher with previews |
| Copilot key / `Super+A` | Assistant |

The Copilot key sends `Meta+Shift+F23`; KDE's shortcut recorder cannot capture F23. `glassfort-settings` ships a **keyd** config that maps it to the assistant.

## System Settings curation

- Glassfort modules: Time Machine, Updates, Assistant, Windows Apps, Appearance.
- Rarely needed modules are hidden; critical options are locked with KDE's Kiosk framework where changing them would break promises (e.g. disabling snapshots without a warning).
- Every visible option must be understandable by a Windows switcher.

## Visual language

| Element | Rule |
|---|---|
| Windows | Own decoration with round, coloured buttons (own artwork, never Apple's) |
| Effects | Blur behind panels/menus, "magic lamp" minimise, smooth animations, rounded corners |
| Accent | One accent colour drives GTK (adw-gtk3), Qt (Kvantum), kitty, KWin borders and all widgets |
| Light/Dark | Switches automatically by time of day; manual override |
| Fonts | UI: **Inter** (or Geist); monospace: **Geist Mono** or JetBrains Mono. SF Pro is not allowed (licence). |
| Icons/cursor | One consistent icon set, our own over time |

## Default applications

| Category | Default | Offered at first boot |
|---|---|---|
| Browser | Firefox | Chromium, Brave, Chrome (Flathub) |
| Office | LibreOffice with the "Tabbed" UI | OnlyOffice; MS Office via Windows Apps |
| Mail | Thunderbird | Outlook via Windows Apps |
| Files | Dolphin (Explorer-like preset) | – |
| Others | Okular, Gwenview, Kate, Spectacle, Haruna, KeePassXC | Gaming pack (Steam), etc. |

Note: Thunderbird supports Exchange natively via EWS since version 145, but Microsoft is turning EWS off for Exchange Online. Microsoft 365 accounts need Thunderbird's Graph support; check its status before each release. Until then, Outlook via Windows Apps is the fallback.

## Corporate identity

### Name and slogan

- **Glassfort** – *Beautiful as glass. Strong as a fortress.*
- Product language: English. The name is always written `Glassfort` (capital G, one word).

### Colour palette

| Role | Name | Hex |
|---|---|---|
| Accent 1 (gradient start) | Glacier Teal | `#3DD6C6` |
| Accent 2 (gradient end) | Fort Indigo | `#4C4FE0` |
| Dark (text, dark mode background) | Midnight | `#0E1222` |
| Light (background) | Frost | `#F5F7FA` |
| Neutral | Steel | `#8B93A7` |

Teal/indigo is deliberate: it stays clearly distinct from Arch blue and KDE blue.

### Logo

- Symbol: an abstract fortress tower with **three rounded crenellations**, built from overlapping translucent frosted-glass panes, gradient teal → indigo.
- Current state: AI-generated drafts exist (symbol, app icon, wallpaper). **Open:** decide whether to simplify the symbol (fewer overlapping panes) for legibility at 16 px, then redraw it as clean vector (Inkscape) – the final logo must be our own vector artwork.
- Required variants: full-colour symbol (light and dark backgrounds), app icon (squircle, symbol ≈ 60 % of the area), flat monochrome (dark and white) for 16–32 px, horizontal and stacked lockup with the wordmark set in Inter Semibold.
- Must never resemble Arch's logo, Apple's or Microsoft's marks, or KDE's logo.

### Wallpapers

- Default: abstract frosted-glass shapes in the palette on Midnight (dark) and Frost (light), empty calm centre.
- Variants **with** centred logo: login screen, lock screen, installer, website, GitHub social preview.
- Variants **without** logo: desktop.
- Deliver at least 3840×2160 (upscale the AI drafts, e.g. with Upscayl, or recreate as vector).

### Where the CI appears

Boot splash (Plymouth), Limine splash, login screen, lock screen, installer, first boot, About dialog, website, docs, social previews.
