# mango-rice

A from-scratch **Mango + Quickshell** desktop with a terminal monochrome
palette: near-black surfaces, grey hairline boxes, and plain text. Mango is
the primary compositor; Labwc and Niri remain installed as fallback sessions
at the login screen. The top bar, dmenu-style launcher, power menu, notifications,
desktop icons, companion, and desktop widgets are custom QML in `quickshell/`.
No Waybar, no AGS, no KDE.

The active branch is `mango-naturalist`, but the shell palette is now plain
grey/black. Labwc is kept in `labwc/` and Niri in `niri/config.kdl` so both
fallback sessions still work.

## Layout

```
mango/config.conf            Mango compositor config (primary)
labwc/                       Labwc fallback config
niri/config.kdl              Niri compositor config (fallback)
quickshell/                  qs -c niri
  shell.qml                  entry point
  theme/Theme.qml            palette, type, glyphs, motion
  services/                  Mango + Niri IPC, sysstats, weather, brightness,
                             disk, network, bluetooth, battery, notifications
  components/                top bar, desktop icons, companion, widgets
  overlays/                  launcher, power menu, notifications, calendar, OSD
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
the shell falls back to Labwc's foreign-toplevel data or Niri's `niri msg`
IPC.

The configs are symlinked:

```
~/.config/mango             -> ~/niri-rice-mango/mango
~/.config/labwc             -> ~/niri-rice-mango/labwc
~/.config/niri              -> ~/niri-rice-mango/niri
~/.config/quickshell/niri   -> ~/niri-rice-mango/quickshell
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

The active layout is a single 32 px top strip of square, hairline-bordered
text readouts. There are no icons or drawer popups; status is text only.

- Left: time and the current track.
- Center: workspace tags `1..5`.
- Right: open-app icons, then `PKG`, `BT`, `WIFI`, `BAT`, `VOL`, and `BRT`
  readouts.
- Click the time for the calendar, click the track to play/pause, and scroll
  over `VOL` to change the volume.
- Floating windows are kept below the strip when focused, and the strip gets
  out of the way while a fullscreen window is active.
- The old vertical right rail remains available in `components/Bar.qml` for
  comparison, but the top strip is the active shell.

### Open application icons

The box left of `PKG` shows one monochrome icon per application with a window
on the **active tag**; two terminals show a single icon. Clicking an icon
focuses that window through `mmsg dispatch focusid client,<id>`. The box hides
completely on an empty tag rather than leaving an empty frame.

Icons are tinted to `Theme.deskText` with `MultiEffect` so they stay grey
rather than introducing colour into the strip. Resolution is deliberately more
forgiving than `Quickshell.iconPath(name, true)`, which only consults the active
icon theme plus `hicolor`: the active theme here is `WhiteSur-dark`, which
inherits `breeze` but does not ship every breeze icon, so `utilities-terminal`
(the icon for Konsole) would otherwise render blank. `services/Icons.qml`
resolves appid → the application's own `Icon=` → a prebuilt index of the
`WhiteSur-dark`, `WhiteSur`, `breeze`, `Adwaita`, and `hicolor` themes → a Nerd
Font glyph as the last resort.

`PKG` is the count of pending package updates, not a package manager: it runs
`checkupdates` every six hours and shows how many lines it printed. It is a
readout only and has no click action.

### Now-playing codec

The track readout starts with a codec badge. MPRIS has no codec field, so
`services/Media.qml` resolves it in this order:

1. An explicit codec/format key in the player's MPRIS metadata.
2. The file extension in `xesam:url` (local files, HLS/DASH) — so VLC or mpv
   playing `song.flac` shows `FLAC`.
3. The browser bridge, below.
4. Otherwise `WEB` for a browser, `AUDIO` for anything else.

Firefox never publishes a codec, so web **videos** correctly show `WEB`. For
web **music**, install `scripts/nowplaying-codec.user.js` in a userscript
manager (Violentmonkey/Tampermonkey). It reads YouTube's own player stats and
puts the real audio codec (`OPUS`, `AAC`, …) into
`navigator.mediaSession.metadata.album`, which Firefox mirrors to MPRIS. The
bar reads that slot only for browser players, so a normal album name is never
mistaken for a codec.

### Launcher
`Super+D` opens a plain dmenu-style panel: a white `Launch:` prompt and cursor,
one column of white application text, and a `>` marker on the selected row,
all on a black background. The list shows ten rows and scrolls through every
match; type to filter, use Up/Down or scroll to move the selection, Enter to
run, and Escape or a click outside to dismiss.

### Window close control

The focused Mango window gets a titlebar-style `×` sitting flush inside its
top-right corner: no border, dark-on-dark, and a grey glyph that brightens with
a subtle fill on hover. Geometry comes from the live `mmsg watch all-clients`
stream, so it stays attached through moves and resizes; it hides for fullscreen
windows, windows on other tags or outputs, and app ids listed in
`ignoreAppIds` in `components/WindowCloseOverlay.qml` (apps that draw their own
control there, such as VSCodium or Firefox). Clicking it closes that window by
id via `mmsg dispatch killclient client,<id>`. The layer surface is masked to
the button, so all other input passes through to the application. `Super+Q`
still closes the focused window, and the taskbar task buttons have a second
close affordance.

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
qs -c niri ipc call shell toggleNotifications
qs -c niri ipc call shell toggleCalendar
qs -c niri ipc call shell toggleNotes
qs -c niri ipc call shell togglePower
qs -c niri ipc call shell closeOverlays
```

## Window chrome and edge resize

Windows are square and borderless:

- `border_px=1` (transparent)
- `border_radius=0`
- `no_radius_when_single=0`
- no focus outline or coloured border
- a soft shadow is kept only for floating windows

`enable_border_resize=1` with a thin `border_resize_size=4`: hover a window
border, then press and hold the left button to resize. The strip is measured
inward from the window edge, so on an app whose scrollbar sits flush to that
edge (Konsole) the outer few pixels resize instead of scroll — hence the small
value. `Super+right-drag` resizes from anywhere, and the keyboard binds below
also resize.

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

It installs `mangowm`, Niri (fallback), rlogin, Quickshell,
xwayland-satellite, Labwc (fallback), portals, swaybg, swayidle, swaylock,
polkit-gnome, grim/slurp/wl-clipboard, and qt6-imageformats. All three session
files are listed by rlogin; choose Mango for the new desktop, or Labwc/Niri
if Mango fails to start.

### Login manager

`rlogin` replaces greetd/tuigreet and runs directly on tty1, so returning from
a Mango session does not hand off to a second greeter or clear the VT white.
The installer builds it from
[`Beforov1337/rlogin`](https://github.com/Beforov1337/rlogin) and enables
`rlogin.service`. Use `sudo ./scripts/install-rlogin.sh` to install or update
just the login manager without rerunning the full rice installer.

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
| Print | region screenshot to clipboard |
| Super+Print | full screen to clipboard |
| Shift+Print | full screen to `~/Pictures/Screenshots` |

Mango consumes `Super+1..5` as tag switches. Niri's column-width presets and
tabbed-column bindings have no direct Mango equivalent; the dwindle layout
plus mouse resizing replaces them.

## Notes / next

- The palette is terminal monochrome: near-black surfaces, grey hairlines,
  and no accent colors. The wallpaper is a plain graphite gradient. Swap
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
