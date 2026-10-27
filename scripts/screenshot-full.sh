#!/bin/sh
# Super+Print: copy the whole output to the clipboard.
set -eu

grim - | wl-copy
