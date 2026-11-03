set -euo pipefail

ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        --with-mango) : ;;
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
    mangowm
    niri
    labwc
    quickshell
    cmake
    ninja
    layer-shell-qt
    qt6-base
    xwayland-satellite
    xdg-desktop-portal-gnome
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
    swaybg
    swayidle
    swaylock
    polkit-gnome
    qt6-imageformats
    brightnessctl
    playerctl
    grim
    slurp
    wl-clipboard
    networkmanager
    bluez-utils
    curl
    ttf-jetbrains-mono-nerd
    gsfonts
    rust
    pam
    git
)

REMOVE_HYPR=(hyprland hypridle hyprlock hyprpaper hyprpm xdg-desktop-portal-hyprland)

echo "──────────────────────────────────────────────────────────────"
echo " user:        $USER_NAME ($USER_HOME)"
echo " repo:        $REPO_DIR"
echo " install:     ${INSTALL_PKGS[*]}"
echo " remove:      ${REMOVE_HYPR[*]}"
echo " remove:      plasma-meta (recursive) + cachyos-kde-settings (package only)"
echo " login:       rlogin  (replaces greetd/tuigreet and plasmalogin)"
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

if ! compgen -G "$USER_HOME/rice-backups/*.tar.zst" >/dev/null; then
    echo "No backup found in $USER_HOME/rice-backups — aborting."
    exit 1
fi

pacman -S --needed --noconfirm "${INSTALL_PKGS[@]}"

mkdir -p "$USER_HOME/.config/quickshell"
install -d -o "$USER_NAME" -g "$USER_NAME" "$USER_HOME/Pictures/Screenshots"
install -d -o "$USER_NAME" -g "$USER_NAME" "$USER_HOME/Pictures"

install -m 0644 -o "$USER_NAME" -g "$USER_NAME" \
    "$REPO_DIR/quickshell/assets/wallpaper-terminal.png" \
    "$USER_HOME/Pictures/wallpaper-terminal.png"
install -m 0644 -o "$USER_NAME" -g "$USER_NAME" \
    "$REPO_DIR/quickshell/assets/wallpaper-circuit.png" \
    "$USER_HOME/Pictures/wallpaper-circuit.png"
install -m 0644 -o "$USER_NAME" -g "$USER_NAME" \
    "$REPO_DIR/quickshell/assets/wallpaper-scene-on-the-ice.jpg" \
    "$USER_HOME/Pictures/wallpaper-scene-on-the-ice.jpg"

install -d -o "$USER_NAME" -g "$USER_NAME" "$USER_HOME/.local/bin"
install -m 0755 -o "$USER_NAME" -g "$USER_NAME" \
    "$REPO_DIR/scripts/screenshot-region.sh" \
    "$USER_HOME/.local/bin/screenshot-region"
install -m 0755 -o "$USER_NAME" -g "$USER_NAME" \
    "$REPO_DIR/scripts/screenshot-full.sh" \
    "$USER_HOME/.local/bin/screenshot-full"
install -m 0755 -o "$USER_NAME" -g "$USER_NAME" \
    "$REPO_DIR/scripts/screenshot-file.sh" \
    "$USER_HOME/.local/bin/screenshot-file"
install -m 0755 -o "$USER_NAME" -g "$USER_NAME" \
    "$REPO_DIR/scripts/wallpaper-restore" \
    "$USER_HOME/.local/bin/wallpaper-restore"

if [[ ! -f "$USER_HOME/Pictures/wallpaper-scene-on-the-ice.jpg" ]]; then
    echo "WARN: $USER_HOME/Pictures/wallpaper-scene-on-the-ice.jpg is missing; swaybg will have nothing to show."
fi

if [[ -e "$USER_HOME/.config/niri" && ! -L "$USER_HOME/.config/niri" ]]; then
    echo "ERROR: $USER_HOME/.config/niri exists and is not a symlink. Move it aside first."
    exit 1
fi
ln -sfn "$REPO_DIR/niri" "$USER_HOME/.config/niri"

if [[ -e "$USER_HOME/.config/mango" && ! -L "$USER_HOME/.config/mango" ]]; then
    echo "ERROR: $USER_HOME/.config/mango exists and is not a symlink. Move it aside first."
    exit 1
fi
ln -sfn "$REPO_DIR/mango" "$USER_HOME/.config/mango"

if [[ -e "$USER_HOME/.config/labwc" && ! -L "$USER_HOME/.config/labwc" ]]; then
    echo "ERROR: $USER_HOME/.config/labwc exists and is not a symlink. Move it aside first."
    exit 1
fi
ln -sfn "$REPO_DIR/labwc" "$USER_HOME/.config/labwc"

if [[ -e "$USER_HOME/.config/quickshell/niri" && ! -L "$USER_HOME/.config/quickshell/niri" ]]; then
    echo "ERROR: $USER_HOME/.config/quickshell/niri exists and is not a symlink. Move it aside first."
    exit 1
fi
ln -sfn "$REPO_DIR/quickshell" "$USER_HOME/.config/quickshell/niri"

chown -h "$USER_NAME:$USER_NAME" \
    "$USER_HOME/.config/niri" \
    "$USER_HOME/.config/mango" \
    "$USER_HOME/.config/labwc" \
    "$USER_HOME/.config/quickshell/niri"

runuser -u "$USER_NAME" -- env HOME="$USER_HOME" bash -c "
    set -e
    cmake -S '$REPO_DIR/wallpaper-picker' -B '$REPO_DIR/build/wallpaper-picker' \
        -G Ninja -DCMAKE_BUILD_TYPE=Release
    cmake --build '$REPO_DIR/build/wallpaper-picker'
    cmake --install '$REPO_DIR/build/wallpaper-picker' \
        --prefix '$USER_HOME/.local'
"

if ! runuser -u "$USER_NAME" -- env HOME="$USER_HOME" \
        niri validate -c "$USER_HOME/.config/niri/config.kdl"; then
    echo "niri fallback config failed validation — aborting before removal."
    exit 1
fi

if ! runuser -u "$USER_NAME" -- env HOME="$USER_HOME" \
        mango -c "$USER_HOME/.config/mango/config.conf" -p; then
    echo "Mango config failed validation — aborting before removal."
    exit 1
fi

systemctl disable plasmalogin.service 2>/dev/null || true
rm -f /etc/systemd/system/display-manager.service
"$REPO_DIR/scripts/install-rlogin.sh"

pacman -Rns --noconfirm "${REMOVE_HYPR[@]}"
pacman -Rns --noconfirm hyprpolkitagent 2>/dev/null || true

pacman -Rns --noconfirm plasma-meta
pacman -R --noconfirm cachyos-kde-settings 2>/dev/null || true

systemctl daemon-reload

echo
echo "Done. Packages installed, Hyprland/Plasma removed, rlogin enabled."
echo "Old Quickshell configs were left untouched in ~/.config/quickshell/."
echo "Orphans (review before removing):"
pacman -Qdtq || true
echo
echo "Reboot to land in rlogin → Mango (Labwc and Niri are still available as fallbacks):"
echo "  sudo reboot"
