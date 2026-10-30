set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run this with sudo: sudo $0" >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE=/etc/systemd/system/mouse-resize.service
BINARY=/usr/local/bin/mouse-resize
CONFIG=/etc/mouse-resize.conf
BUTTON_VALUE=BTN_EXTRA

if [[ -f /etc/systemd/system/razer-resize.service ]]; then
    systemctl disable --now razer-resize.service 2>/dev/null || true
    rm -f /etc/systemd/system/razer-resize.service \
          /usr/local/bin/razer-resize \
          /etc/razer-resize.conf
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --uninstall)
            systemctl disable --now mouse-resize.service 2>/dev/null || true
            rm -f "$SERVICE" "$BINARY" "$CONFIG"
            systemctl daemon-reload
            echo "Removed mouse-resize. Mouse buttons are back to normal."
            exit 0
            ;;
        --button)
            if [[ $# -lt 2 ]]; then
                echo "--button needs BTN_EXTRA, BTN_SIDE or BTN_RIGHT" >&2
                exit 2
            fi
            BUTTON_VALUE="$2"
            shift 2
            ;;
        *)
            echo "unknown argument: $1" >&2
            echo "usage: sudo $0 [--button BTN_EXTRA|BTN_SIDE|BTN_RIGHT] [--uninstall]" >&2
            exit 2
            ;;
    esac
done

if ! pkg-config --exists libevdev; then
    echo "libevdev development files are required. Install: sudo pacman -S libevdev" >&2
    exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

gcc -O2 -Wall -Wextra \
    -o "$tmpdir/mouse-resize" "$REPO_DIR/scripts/mouse-resize.c" \
    $(pkg-config --cflags --libs libevdev)

install -Dm755 "$tmpdir/mouse-resize" "$BINARY"
install -Dm644 "$REPO_DIR/scripts/mouse-resize.service" "$SERVICE"

cat > "$CONFIG" <<EOF
# Mouse button translated into Super+right-drag for the compositor resize
# gesture. BTN_EXTRA is the forward thumb button, BTN_SIDE the back thumb.
BUTTON=$BUTTON_VALUE
EOF
chmod 644 "$CONFIG"

systemctl daemon-reload
systemctl enable --now mouse-resize.service

if systemctl is-active --quiet mouse-resize.service; then
    active_button="$(grep -E '^BUTTON=' "$CONFIG" | cut -d= -f2- || true)"
    echo "mouse-resize is running (BUTTON=${active_button:-BTN_EXTRA})."
    if [[ "$active_button" == "BTN_RIGHT" ]]; then
        echo "Right-drag anywhere in a window resizes it. Right-click menus are replaced."
    else
        echo "Hold that mouse button in a window and drag to resize; normal clicks are unchanged."
    fi
else
    echo "mouse-resize failed to start. Check:" >&2
    echo "  systemctl status mouse-resize.service" >&2
    echo "  journalctl -u mouse-resize.service -n 30" >&2
fi
