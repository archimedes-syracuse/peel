#!/bin/sh
# Print: select a region and copy it to the clipboard. Cancelling slurp falls
# back to a full-screen copy, matching the behaviour of the Mango session.
set -eu

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"

if geometry=$(slurp 2>/dev/null) && [ -n "$geometry" ]; then
    grim -g "$geometry" - | wl-copy
else
    grim - | wl-copy
fi
