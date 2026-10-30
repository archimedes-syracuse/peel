set -eu

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/Screenshot-$(date +%Y%m%d-%H%M%S).png"

grim "$file"
notify-send "Screenshot saved" "$file" >/dev/null 2>&1 || true
