set -euo pipefail

# Install rlogin as the TTY login manager and retire greetd/tuigreet.

if [[ $EUID -ne 0 ]]; then
    echo "Run this with sudo: sudo $0" >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RLOGIN_SRC="https://github.com/Beforov1337/rlogin.git"
BUILD_ROOT="$(mktemp -d /var/tmp/rlogin-build.XXXXXX)"
trap 'rm -rf "$BUILD_ROOT"' EXIT

missing=()
for pkg in rust pam git; do
    pacman -Q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
if (( ${#missing[@]} > 0 )); then
    pacman -S --needed --noconfirm "${missing[@]}"
fi

git clone --depth=1 "$RLOGIN_SRC" "$BUILD_ROOT/rlogin"

PAM_PATCH="$REPO_DIR/scripts/rlogin-pam-session.patch"
if [[ ! -f "$PAM_PATCH" ]]; then
    echo "Missing patch: $PAM_PATCH" >&2
    exit 1
fi
git -C "$BUILD_ROOT/rlogin" apply --check "$PAM_PATCH"
git -C "$BUILD_ROOT/rlogin" apply "$PAM_PATCH"

cargo build --release --locked \
    --manifest-path "$BUILD_ROOT/rlogin/Cargo.toml" \
    --target-dir "$BUILD_ROOT/target"
install -m 0755 "$BUILD_ROOT/target/release/rlogin" /usr/local/bin/rlogin

install -d -m 0755 /etc/rlogin
cat > /etc/rlogin.toml <<'EOF'
pam_service = "login"
default_session = "Mango"
clear_password_on_error = true
clear_username_on_error = false
# Omit banner to use the machine hostname.
# banner = "gentoo"
EOF

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

systemctl disable greetd.service 2>/dev/null || true
systemctl disable getty@tty1.service 2>/dev/null || true
systemctl enable rlogin.service

echo
echo "rlogin is installed and enabled for the next boot on tty1."
echo "Reboot when convenient:"
echo "  sudo reboot"
