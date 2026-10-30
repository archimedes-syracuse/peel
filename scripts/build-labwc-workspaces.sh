set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${1:-$HOME/.local/bin}"
PROTOCOL="/usr/share/wayland-protocols/staging/ext-workspace/ext-workspace-v1.xml"

if [[ ! -f "$PROTOCOL" ]]; then
    echo "Missing $PROTOCOL (install wayland-protocols)." >&2
    exit 1
fi
if ! command -v wayland-scanner >/dev/null 2>&1; then
    echo "Missing wayland-scanner (install wayland)." >&2
    exit 1
fi
if ! command -v cc >/dev/null 2>&1; then
    echo "Missing a C compiler (install gcc)." >&2
    exit 1
fi

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

wayland-scanner client-header \
    "$PROTOCOL" "$BUILD_DIR/ext-workspace-v1-client-protocol.h"
wayland-scanner private-code \
    "$PROTOCOL" "$BUILD_DIR/ext-workspace-v1-protocol.c"

cc -O2 -Wall -Wextra \
    -I"$BUILD_DIR" \
    -o "$BUILD_DIR/labwc-workspaces" \
    "$REPO_DIR/scripts/labwc-workspaces.c" \
    "$BUILD_DIR/ext-workspace-v1-protocol.c" \
    $(pkg-config --cflags --libs wayland-client)

install -Dm755 "$BUILD_DIR/labwc-workspaces" "$BIN_DIR/labwc-workspaces"
echo "Installed $BIN_DIR/labwc-workspaces"
