#!/bin/tcsh -f
# wallpaper-picker — tcsh entry point for the custom shell.
#
# Uses the in-tree build first, then the system installation. No arguments
# toggles the carousel; --list/--get/--set/--random are passed through.

set here = `dirname "$0"`
set repo_bin = "$here/../../build/wallpaper-picker/wallpaper-picker"
set system_bin = "/usr/local/lib/wallpaper-picker/wallpaper-picker"
set user_bin = "$HOME/.local/lib/wallpaper-picker/wallpaper-picker"

if ( -x "$repo_bin" ) then
    set bin = "$repo_bin"
else if ( -x "$system_bin" ) then
    set bin = "$system_bin"
else if ( -x "$user_bin" ) then
    set bin = "$user_bin"
else
    echo "wallpaper-picker: binary not found; run 'cmake -S wallpaper-picker -B build/wallpaper-picker && cmake --build build/wallpaper-picker'" >&2
    exit 1
endif

if ( $#argv == 0 ) then
    exec "$bin" --toggle
else
    exec "$bin" $argv:q
endif
