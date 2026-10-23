# mango-rice

A from-scratch **Mango + Quickshell** desktop, migrated from the original
Niri rice. Mango is the primary compositor; Niri remains installed as a
fallback session at the login screen. The vertical right rail, launcher,
system drawer, power menu, notifications, and desktop widgets are custom QML
in `quickshell/`. No Waybar, no AGS, no KDE.

The migration lives on the `mango` branch. Niri is kept in `niri/config.kdl`
so the fallback session still works.

## Layout

```
mango/config.conf            Mango compositor config (primary)
niri/config.kdl              Niri compositor config (fallback)
quickshell/                  qs -c niri
  shell.qml                  entry point
  theme/Theme.qml            palette, type, glyphs, motion
  services/                  Mango + Niri IPC, sysstats, weather, brightness,
                             disk, network, bluetooth, battery, notifications
  components/                vertical rail widgets and desktop windows
  overlays/                  launcher, system drawer, power menu, notifications,
                             calendar, OSD
  assets/                    bundled desktop-widget artwork
scripts/install.sh           install Mango + Niri fallback, switch login manager
scripts/install-razer-resize.sh  optional Basilisk mouse-button resize helper
scripts/razer-resize.c           helper source
```

## Run

```
qs -c niri
```

The Quickshell profile keeps its historical `niri` name so the Niri fallback
and existing IPC commands continue to work. The compositor underneath is
detected automatically: Mango's `mmsg` IPC is used when available, otherwise
the shell falls back to Niri's `niri msg` IPC.

The configs are symlinked:

```
~/.config/mango             -> ~/niri-rice/mango
~/.config/niri              -> ~/niri-rice/niri
~/.config/quickshell/niri   -> ~/niri-rice/quickshell
```

Validate and reload Mango:

```
mango -c ~/.config/mango/config.conf -p
mmsg dispatch reload_config
```

`auto_reload_config=1` also reloads Mango when the config changes. The Niri
fallback still validates with:

```
niri validate -c ~/.config/niri/config.kdl
niri msg action load-config-file
```

Quickshell watches its QML files and hot-reloads them. If a reload leaves the
IPC socket unresponsive, restart the shell cleanly:

```
systemctl --user restart niri-quickshell 2>/dev/null || qs -n -c niri -d
```

## Bar

The bar is a floating vertical rail on the right edge, inspired by gdots'
Waybar layout. It reserves 42 px through a layer-shell exclusive zone, so
Mango tiles windows to its left instead of underneath it.

Top group:

- Arch mark: opens the launcher.
- Tags `1..5` (Mango's dwm-style tags). The active tag is pink; occupied tags
  are brighter than empty ones.
- CPU, RAM, and root-disk readouts.

Bottom group:

- Volume and brightness.
- `<`: opens the system drawer (now-playing controls, Wi-Fi, Bluetooth,
  battery, volume/brightness sliders, lock screen).
- Bell: notification history and do-not-disturb.
- Clock.
- Power: session menu.

The rail is deliberately minimal. Wi-Fi, Bluetooth, and battery live in the
system drawer instead of taking permanent space. The old horizontal bar
documentation no longer applies; the shell is now one vertical rail.

## Desktop widgets

The wallpaper layer carries three small reference-matched windows:

- **Weather**: live wttr.in feels-like/min/max, rain so far, today's rain
  total, clothing/umbrella advice, and sunset.
- **Now playing**: MPRIS cover/title/artist with previous/play/next. Browser
  players that only expose a generic "playing media" title keep the bundled
  illustrated demo state; real tracks take over automatically.
- **Notes**: an editable olive/yellow notepad. Click the body to type; the
  arrows are undo/redo and X hides it.

The widgets share one background-layer surface, so they sit on the wallpaper
and disappear behind tiled windows. Switch to an empty tag to see them. Drag
any widget by its title bar. Positions and the note text persist in
Quickshell's state directory. The shared `RetroWindow` frame and `PixelText`
component are the starting point for the later sprite/GIF widget host.

The typewriter pixel text uses `Nimbus Mono PS` (package `gsfonts`); the
install script includes it.

Useful IPC while developing:

```
qs -c niri ipc call shell toggleLauncher
qs -c niri ipc call shell toggleControl
qs -c niri ipc call shell toggleNotifications
qs -c niri ipc call shell toggleCalendar
qs -c niri ipc call shell toggleNotes
qs -c niri ipc call shell togglePower
qs -c niri ipc call shell closeOverlays
```

## Window chrome and edge resize

Windows are square and borderless:

- `border_px=0`
- `border_radius=0`
- `no_radius_when_single=1`
- no focus outline or coloured border
- a soft shadow is kept only for floating windows

Mango's `enable_border_resize=1` adds a 10 px grab strip for plain left-button
edge resizing. For the original right-button behaviour, the config binds
`Super+right-drag` to Mango's `moveresize,curresize` action. Floating windows
expose every edge; tiled windows expose the edges shared with a neighbour.

The Basilisk helper is optional and still works on Mango. It holds the
`Super+right` chord while a chosen physical mouse button is pressed:

```
sudo ./scripts/install-razer-resize.sh                    # forward thumb
sudo ./scripts/install-razer-resize.sh --button BTN_RIGHT # normal right button
```

The current machine uses `BUTTON=BTN_RIGHT` in `/etc/razer-resize.conf`.
Change that value (`BTN_EXTRA` is the forward thumb, `BTN_SIDE` is the back
thumb) and run `sudo systemctl restart razer-resize` to switch. `BTN_RIGHT`
makes right-drag resize everywhere, but it holds Super during ordinary
right-clicks, so context menus and games may react differently. Remove it with:

```
sudo ./scripts/install-razer-resize.sh --uninstall
```

Files/Nautilus is GTK4/libadwaita and ignores `prefer-no-csd`; a local
GTK-NoCSD wrapper (`~/.local/bin/nautilus-nocsd`) removes its headerbar and
CSD edge handles so it matches the tiled windows. Launch Files normally from
the bar.

## Install / teardown

The script is a dry run unless `--yes` is passed:

```
sudo ./scripts/install.sh              # preview
sudo ./scripts/install.sh --yes        # install Mango + Niri fallback,
                                       # remove Hyprland/Plasma
```

It installs `mangowm`, Niri (fallback), greetd/tuigreet, Quickshell,
xwayland-satellite, portals, swaybg, swayidle, swaylock, polkit-gnome,
grim/slurp/wl-clipboard, and qt6-imageformats. Both session files are listed
by tuigreet; choose Mango for the new desktop, or Niri if Mango fails to
start.

The script backs up nothing itself — do that first:

```
tar --zstd -cf ~/rice-backups/config-$(date +%Y%m%d-%H%M).tar.zst \
  --exclude='.config/quickshell/caelestia/build' -C ~ .config
```

## Keybinds

| Key | Action |
|---|---|
| Super+Return | Alacritty |
| Super+D | launcher |
| Super+Escape | power menu |
| Super+Shift+C | system drawer |
| Super+Shift+N | notifications |
| Super+Shift+D | calendar |
| Super+Shift+W | show/hide desktop notes |
| Super+Q | close window |
| Super+L | swaylock |
| Super+F / Super+Shift+F | maximize / fullscreen |
| Super+V | toggle floating |
| Super+M / Super+Shift+M | minimize / restore |
| Super+O | overview |
| Super+R | cycle layout |
| Super+1..5 | view tag |
| Super+Shift+1..5 | move window to tag (stay on current tag) |
| Super+Ctrl+1..5 | move window to tag and follow it |
| Super+Left/Right/Up/Down | focus window in direction |
| Super+Shift+Left/Right/Up/Down | move window in direction |
| Super+Ctrl+Left/Right | move window to previous/next tag |
| Super+Shift+H/L/K/J | resize floating window |
| Super+Tab | previous tagset |
| Super+Page_Up/Page_Down | previous/next tag |
| Super+Shift+E | quit Mango |
| Print / Super+Shift+S | save screenshot / region to clipboard |

Mango consumes `Super+1..5` as tag switches. Niri's column-width presets and
tabbed-column bindings have no direct Mango equivalent; the dwindle layout
plus mouse resizing replaces them.

## Notes / next

- The palette is matched to the supplied compact bar reference: near-black
  surfaces, pink active state, and pale-gold system readouts. Swap
  `quickshell/theme/Theme.qml` or generate it later with matugen.
- Notifications are owned by Quickshell. The toast overlay and history panel
  share one `NotificationServer` singleton so they do not fight for the
  `org.freedesktop.Notifications` bus name. Caelestia is not started.
- v0 locking/idle/wallpaper still uses `swaylock`, `swayidle`, and `swaybg`.
  v1: Quickshell lock screen (`WlSessionLock` + PAM), an animated wallpaper
  via `awww`, and the generic sprite/GIF widget host (`AnimatedImage`,
  `AnimatedSprite` / `SpriteSequence`, and spritecook exports).
- The Quickshell settings UI is still pending; it will write JSON through
  `services/Widgets.qml` and the shell theme without editing
  `mango/config.conf`.
