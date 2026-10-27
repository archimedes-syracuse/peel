#!/bin/sh
# Print: select a region and copy it to the clipboard. Cancelling slurp falls
# back to a full-screen copy, matching the behaviour of the Mango session.
set -eu

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"

# One selection UI at a time. Repeated Print presses must not stack slurp
# overlays or start competing selections.
lock="${XDG_RUNTIME_DIR:-/tmp}/mango-screenshot-region.lock"
exec 9>"$lock"
flock -n 9 || exit 0

# slurp's default backdrop is translucent white, which looks like a blur and
# gets brighter each time another slurp is opened. Keep the backdrop fully
# transparent and show only a thin border around the selection.
if geometry=$(slurp -b '#00000000' -c '#ffffff' -s '#00000000' -w 2 2>/dev/null) \
        && [ -n "$geometry" ]; then
    grim -g "$geometry" - | wl-copy
else
    grim - | wl-copy
fi
