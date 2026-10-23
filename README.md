# niri-rice

A from-scratch **Niri + Quickshell** desktop. The compositor is Niri; the
top bar, launcher, system drawer, power menu, and notifications are custom
QML in `quickshell/`. No Waybar, no AGS, no KDE.

## Layout

```
niri/config.kdl              compositor config
quickshell/                  qs -c niri
  shell.qml                  entry point
  theme/Theme.qml            palette, type, glyphs, motion
  services/                  Niri IPC, sysstats, weather, brightness, disk,
                             network, bluetooth, battery, notifications
  components/                bar widgets
  overlays/                  launcher, system drawer, power menu, notifications,
                             calendar, OSD
scripts/install.sh           install niri, switch login manager, remove old stack
```

## Run

```
qs -c niri
```

The config is symlinked:

```
~/.config/niri              -> ~/niri-rice/niri
~/.config/quickshell/niri   -> ~/niri-rice/quickshell
```

Validate the compositor config:

```
niri validate -c ~/.config/niri/config.kdl
```

Reload after edits:

```
niri msg action load-config-file
```

Quickshell watches its QML files and hot-reloads them. If a reload leaves the
IPC socket unresponsive, restart the shell cleanly:

```
systemctl --user restart niri-quickshell 2>/dev/null || qs -n -c niri -d
```

## Bar

Left to right:

- Arch mark: opens the launcher.
- Numeric workspaces `1..5`; the active workspace is pink.
- Center: `date · time · weather`, with current conditions from wttr.in.
  Click it for the month calendar.
- `<`: opens the system drawer (now-playing controls, network, Bluetooth,
  battery, volume and brightness sliders, lock screen).
- Volume, brightness, root-disk, RAM, and CPU readouts.
- Bell: notification history and do-not-disturb.
- Power: session menu.

Volume and brightness changes show a small non-focusable OSD near the bottom
center. Hardware keys, the drawer sliders, and external tools all feed it.

The bar is deliberately minimal. Wi-Fi, Bluetooth, and battery live in the
system drawer instead of taking permanent space.

Useful IPC while developing:

```
qs -c niri ipc call shell toggleLauncher
qs -c niri ipc call shell toggleControl
qs -c niri ipc call shell toggleNotifications
qs -c niri ipc call shell toggleCalendar
qs -c niri ipc call shell togglePower
qs -c niri ipc call shell closeOverlays
```

## Install / teardown

The script is a dry run unless `--yes` is passed:

```
sudo ./scripts/install.sh              # preview
sudo ./scripts/install.sh --yes        # install + remove Hyprland/Plasma
sudo ./scripts/install.sh --yes --with-mango   # also install Mango
```

It installs Niri, greetd/tuigreet, xwayland-satellite, portals, swaybg,
swayidle, swaylock, polkit-gnome, and qt6-imageformats. It backs up
nothing itself — do that first:

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
| Super+Q | close window |
| Super+L | swaylock |
| Super+F / Super+Shift+F | maximize / fullscreen |
| Super+V | toggle floating |
| Super+O | overview |
| Super+1..5 | focus workspace |
| Super+Shift+1..5 | move column to workspace |
| Super+Left/Right | focus column |
| Super+Up/Down | focus window |
| Super+Shift+Left/Right | move column |
| Super+Shift+Up/Down | move window |
| Super+Shift+H/L | resize column |
| Super+Shift+J/K | resize window height |
| Super+R | cycle column width |
| Super+W | tabbed column |
| Super+Shift+E | quit niri |
| Print / Super+Shift+S | niri screenshot UI |

## Notes / next

- The palette is matched to the supplied compact bar reference: near-black
  surfaces, pink active state, and pale-gold system readouts. Swap
  `quickshell/theme/Theme.qml` or generate it later with matugen.
- Notifications are owned by Quickshell. The toast overlay and history panel
  share one `NotificationServer` singleton so they do not fight for the
  `org.freedesktop.Notifications` bus name. Caelestia is not started under
  Niri.
- v0 locking/idle/wallpaper still uses `swaylock`, `swayidle`, and `swaybg`.
  v1: Quickshell lock screen (`WlSessionLock` + PAM), an animated wallpaper
  via `awww`, and desktop sprite widgets (`AnimatedSprite` / `SpriteSequence`
  plus GIF and spritecook exports).
