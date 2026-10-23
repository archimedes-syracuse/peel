#!/usr/bin/env bash
# Install the Razer Basilisk resize helper.
#
#   sudo ./scripts/install-razer-resize.sh
#   sudo ./scripts/install-razer-resize.sh --uninstall
#
# By default the helper maps the forward thumb button (BTN_EXTRA) to
# Meta+right-drag. Use --button BTN_SIDE for the back thumb, or
# --button BTN_RIGHT for the normal right mouse button.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run this with sudo: sudo $0" >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE=/etc/systemd/system/razer-resize.service
BINARY=/usr/local/bin/razer-resize
CONFIG=/etc/razer-resize.conf
BUTTON_VALUE=BTN_EXTRA
BUTTON_EXPLICIT=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --uninstall)
            systemctl disable --now razer-resize.service 2>/dev/null || true
            rm -f "$SERVICE" "$BINARY" "$CONFIG"
            systemctl daemon-reload
            echo "Removed razer-resize. The mouse is back to normal."
            exit 0
            ;;
        --button)
            if [[ $# -lt 2 ]]; then
                echo "--button needs BTN_EXTRA, BTN_SIDE, or BTN_RIGHT" >&2
                exit 2
            fi
            BUTTON_VALUE="$2"
            BUTTON_EXPLICIT=1
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
    -o "$tmpdir/razer-resize" "$REPO_DIR/scripts/razer-resize.c" \
    $(pkg-config --cflags --libs libevdev)

install -Dm755 "$tmpdir/razer-resize" "$BINARY"
install -Dm644 "$REPO_DIR/scripts/razer-resize.service" "$SERVICE"

if [[ ! -f "$CONFIG" || $BUTTON_EXPLICIT -eq 1 ]]; then
    cat > "$CONFIG" <<EOF
# Mouse button translated into Meta+right-drag for the compositor's resize
# gesture. Works with Mango (mousebind=SUPER,btn_right,moveresize,curresize)
# and with the Niri fallback. BTN_EXTRA is the forward thumb button; BTN_SIDE
# is the back thumb button.
BUTTON=$BUTTON_VALUE
EOF
    chmod 644 "$CONFIG"
fi

systemctl daemon-reload
systemctl enable --now razer-resize.service

if systemctl is-active --quiet razer-resize.service; then
    active_button="$(grep -E '^BUTTON=' "$CONFIG" | cut -d= -f2- || true)"
    echo "razer-resize is running (BUTTON=${active_button:-BTN_EXTRA})."
    if [[ "$active_button" == "BTN_RIGHT" ]]; then
        echo "Right-drag at a window edge to resize; ordinary right-clicks now carry Super."
    else
        echo "Hold that mouse button at a window edge and drag to resize; normal right-click is unchanged."
    fi
else
    echo "razer-resize failed to start. Check:" >&2
    echo "  systemctl status razer-resize.service" >&2
    echo "  journalctl -u razer-resize.service -n 30" >&2
fi
