# niri-rice

A from-scratch **Niri + Quickshell** desktop. The compositor is Niri; the
bar, launcher, power menu, and notifications are custom QML in
`quickshell/`. No Waybar, no AGS, no KDE.

## Layout

```
niri/config.kdl              compositor config
quickshell/                  qs -c niri
  shell.qml                  entry point
  theme/Theme.qml            palette, type, glyphs, motion
  services/                  Niri IPC, sysstats, network, bluetooth, battery
  components/                bar widgets
  overlays/                  launcher, power menu, notifications
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

- The palette is currently lifted from `~/.config/hypr/scheme/current.conf`
  (lavender Material You). Swap `quickshell/theme/Theme.qml` or generate it
  later with matugen.
- Notifications are owned by Quickshell (`NotificationServer`). Caelestia is
  still running under Hyprland during development; it will not start under
  Niri.
- v1: Quickshell lock screen (`WlSessionLock` + PAM), media/calendar popups,
  animated wallpaper via `awww`, and sprite widgets (`AnimatedSprite` /
  `SpriteSequence`).
