set -eu

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"

lock="${XDG_RUNTIME_DIR:-/tmp}/mango-screenshot-region.lock"
exec 9>"$lock"
flock -n 9 || exit 0

if geometry=$(slurp -b '#00000000' -c '#ffffff' -s '#00000000' -w 2 2>/dev/null) \
        && [ -n "$geometry" ]; then
    grim -g "$geometry" - | wl-copy
else
    grim - | wl-copy
fi
