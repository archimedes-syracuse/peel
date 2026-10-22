#!/usr/bin/env bash
# niri-rice install / teardown
#
#   sudo ./scripts/install.sh              # dry run, prints the removal plan
#   sudo ./scripts/install.sh --yes        # install niri, switch DM, remove Hyprland/Plasma
#   sudo ./scripts/install.sh --yes --with-mango   # also install Mango for comparison
#
set -euo pipefail

ASSUME_YES=0
WITH_MANGO=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        --with-mango) WITH_MANGO=1 ;;
        *) echo "unknown argument: $arg"; exit 2 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    echo "Run this with sudo: sudo $0 --yes"
    exit 1
fi

USER_NAME="${SUDO_USER:-}"
if [[ -z "$USER_NAME" || "$USER_NAME" == "root" ]]; then
    echo "Run this via sudo from your normal user, not as root directly."
    exit 1
fi
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INSTALL_PKGS=(
    niri
    quickshell
    xwayland-satellite
    greetd
    greetd-tuigreet
    xdg-desktop-portal-gnome
    swaybg
    swayidle
    swaylock
    polkit-gnome
    qt6-imageformats
    brightnessctl
    playerctl
)
if [[ $WITH_MANGO -eq 1 ]]; then
    INSTALL_PKGS+=(mangowm)
fi

REMOVE_HYPR=(hyprland hypridle hyprlock hyprpaper hyprpm xdg-desktop-portal-hyprland)

echo "──────────────────────────────────────────────────────────────"
echo " user:        $USER_NAME ($USER_HOME)"
echo " repo:        $REPO_DIR"
echo " install:     ${INSTALL_PKGS[*]}"
echo " remove:      ${REMOVE_HYPR[*]}"
echo " remove:      plasma-meta (recursive) + cachyos-kde-settings (package only)"
echo " login:       greetd + tuigreet  (replaces plasmalogin)"
echo "──────────────────────────────────────────────────────────────"

if [[ $ASSUME_YES -ne 1 ]]; then
    echo
    echo "DRY RUN — package removal preview:"
    pacman -Rs --print "${REMOVE_HYPR[@]}" 2>&1 | sed 's/^/  /' || true
    echo
    pacman -Rs --print plasma-meta 2>&1 | sed 's/^/  /' | head -60 || true
    echo
    echo "Re-run with --yes to execute. Nothing was changed."
    exit 0
fi

# The backup is intentionally made before this script runs.
if ! compgen -G "$USER_HOME/rice-backups/*.tar.zst" >/dev/null; then
    echo "No backup found in $USER_HOME/rice-backups — aborting."
    exit 1
fi

# ── 1. install ────────────────────────────────────────────────────────
pacman -S --needed --noconfirm "${INSTALL_PKGS[@]}"

# ── 2. symlinks ───────────────────────────────────────────────────────
mkdir -p "$USER_HOME/.config/quickshell"
install -d -o "$USER_NAME" -g "$USER_NAME" "$USER_HOME/Pictures/Screenshots"

if [[ ! -f "$USER_HOME/Pictures/wallpaper.png" ]]; then
    echo "WARN: $USER_HOME/Pictures/wallpaper.png is missing; swaybg will have nothing to show."
fi

if [[ -e "$USER_HOME/.config/niri" && ! -L "$USER_HOME/.config/niri" ]]; then
    echo "ERROR: $USER_HOME/.config/niri exists and is not a symlink. Move it aside first."
    exit 1
fi
ln -sfn "$REPO_DIR/niri" "$USER_HOME/.config/niri"

if [[ -e "$USER_HOME/.config/quickshell/niri" && ! -L "$USER_HOME/.config/quickshell/niri" ]]; then
    echo "ERROR: $USER_HOME/.config/quickshell/niri exists and is not a symlink. Move it aside first."
    exit 1
fi
ln -sfn "$REPO_DIR/quickshell" "$USER_HOME/.config/quickshell/niri"

chown -h "$USER_NAME:$USER_NAME" \
    "$USER_HOME/.config/niri" \
    "$USER_HOME/.config/quickshell/niri"

# ── 3. validate before removing anything ──────────────────────────────
if ! runuser -u "$USER_NAME" -- env HOME="$USER_HOME" \
        niri validate -c "$USER_HOME/.config/niri/config.kdl"; then
    echo "niri config failed validation — aborting before removal."
    exit 1
fi

# ── 4. greetd ─────────────────────────────────────────────────────────
id greeter >/dev/null 2>&1 || \
    useradd --system --home-dir /var/lib/greetd --shell /usr/bin/nologin greeter

install -d -m 0755 /etc/greetd
cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-user-session --sessions /usr/share/wayland-sessions"
user = "greeter"
EOF

# Disable the old DM first so it releases the display-manager.service alias.
# Do not stop it now; this session is still using Hyprland. The package
# removal below deletes plasmalogin, and greetd takes over on reboot.
systemctl disable plasmalogin.service 2>/dev/null || true
rm -f /etc/systemd/system/display-manager.service
systemctl enable greetd.service
systemctl is-enabled greetd.service

# ── 5. remove Hyprland ────────────────────────────────────────────────
pacman -Rns --noconfirm "${REMOVE_HYPR[@]}"
pacman -Rns --noconfirm hyprpolkitagent 2>/dev/null || true

# ── 6. remove Plasma ──────────────────────────────────────────────────
pacman -Rns --noconfirm plasma-meta
# Non-recursive: keeps capitaine-cursors, Fira Sans, and the Alacritty config
# that cachyos-kde-settings happens to depend on.
pacman -R --noconfirm cachyos-kde-settings 2>/dev/null || true

systemctl daemon-reload

echo
echo "Done. Packages installed, Hyprland/Plasma removed, greetd enabled."
echo "Old Quickshell configs were left untouched in ~/.config/quickshell/."
echo "Orphans (review before removing):"
pacman -Qdtq || true
echo
echo "Reboot to land in greetd → niri:"
echo "  sudo reboot"
