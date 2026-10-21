#!/bin/sh
# Package the Termux release zip.
#
# usage: ./scripts/package.sh [path/to/libvulkan_panfrost.so]
set -eu
. "$(dirname -- "$0")/lib.sh"

SO=${1:-$DIST_DIR/libvulkan_panfrost.so}
[ -f "$SO" ] || die "driver not found: $SO (run scripts/build.sh first)"

need python3
mkdir -p "$DIST_DIR"
python3 "$ROOT/scripts/package.py" "$SO" "$DIST_DIR"

log "release files:"
ls -l "$DIST_DIR"
