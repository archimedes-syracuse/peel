#!/usr/bin/env bash
# Install rlogin as the TTY login manager and retire greetd/tuigreet.
#
# Usage:
#   sudo ./scripts/install-rlogin.sh
#
# This only changes the next-boot login setup. It does not stop greetd or the
# current graphical session while you are using it.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run this with sudo: sudo $0" >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RLOGIN_SRC="https://github.com/Beforov1337/rlogin.git"
BUILD_ROOT="$(mktemp -d /var/tmp/rlogin-build.XXXXXX)"
trap 'rm -rf "$BUILD_ROOT"' EXIT

# rlogin is a Rust/PAM program. Pull in its build dependencies if they are not
# already present; the main installer also lists them.
missing=()
for pkg in rust pam git; do
    pacman -Q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
if (( ${#missing[@]} > 0 )); then
    pacman -S --needed --noconfirm "${missing[@]}"
fi

git clone --depth=1 "$RLOGIN_SRC" "$BUILD_ROOT/rlogin"
cargo build --release --locked \
    --manifest-path "$BUILD_ROOT/rlogin/Cargo.toml" \
    --target-dir "$BUILD_ROOT/target"
install -m 0755 "$BUILD_ROOT/target/release/rlogin" /usr/local/bin/rlogin

# Hostname is the default banner. Set banner = "gentoo" here if you want the
# preview title rather than this machine's hostname.
install -d -m 0755 /etc/rlogin
cat > /etc/rlogin.toml <<'EOF'
pam_service = "login"
default_session = "Mango"
clear_password_on_error = true
clear_username_on_error = false
# Omit banner to use the machine hostname.
# banner = "gentoo"
EOF

# Run on the primary VT. Keep the VT allocated when rlogin restarts; clearing
# or disallocating it is what produces the white flash between sessions.
cat > /etc/systemd/system/rlogin.service <<'EOF'
[Unit]
Description=rlogin TUI login manager
After=systemd-user-sessions.service plymouth-quit-wait.service
After=rc-local.service
Before=getty.target
Conflicts=getty@tty1.service greetd.service

[Service]
Type=idle
ExecStart=/usr/local/bin/rlogin --tty 1
StandardInput=tty
StandardOutput=tty
StandardError=journal
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=no
TTYVTDisallocate=no
Restart=always
RestartSec=0

[Install]
WantedBy=graphical.target
EOF

systemctl daemon-reload
systemctl set-default graphical.target

# Do not stop greetd here: that would terminate the graphical session in which
# this script was launched. It will simply not start on the next boot.
systemctl disable greetd.service 2>/dev/null || true
systemctl disable getty@tty1.service 2>/dev/null || true
systemctl enable rlogin.service

echo
echo "rlogin is installed and enabled for the next boot on tty1."
echo "Reboot when convenient:"
echo "  sudo reboot"
