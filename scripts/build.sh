#!/bin/sh
# Build the arm64 Android driver with the NDK.
#
# usage: ./scripts/build.sh [/path/to/android-ndk] [--no-fetch]
#
# The NDK path can also come from ANDROID_NDK_HOME or ANDROID_NDK_ROOT. This script is a thin,
# reproducible wrapper around the base tree's two-stage build:
#   1. host tools (mesa_clc, vtn_bindgen2, panfrost_compile), native;
#   2. libvulkan_panfrost.so, Android API 31 arm64.
set -eu
. "$(dirname -- "$0")/lib.sh"

ndk_arg=""
fetch=1
for arg in "$@"; do
    case "$arg" in
        --no-fetch) fetch=0 ;;
        --*) die "unknown option: $arg" ;;
        *) ndk_arg=$arg ;;
    esac
done

[ "$fetch" = 1 ] && "$ROOT/scripts/fetch-source.sh"
[ -d "$SRC_DIR" ] || die "source tree missing; run scripts/fetch-source.sh"

NDK=$(find_ndk "$ndk_arg") || die "pass the NDK path or set ANDROID_NDK_HOME"
BIN=$(check_ndk "$NDK")

for tool in meson ninja python3 pkg-config glslangValidator; do
    need "$tool"
done

# Keep the build directory under this repository, not inside the vendored source tree.
mkdir -p "$BUILD_DIR"
BUILD_DIR="$BUILD_DIR" "$SRC_DIR/build.sh" "$NDK"

SO="$BUILD_DIR/libvulkan_panfrost.so"
[ -f "$SO" ] || SO="$SRC_DIR/$BUILD_DIR/libvulkan_panfrost.so"
[ -f "$SO" ] || die "build finished but libvulkan_panfrost.so was not found"

mkdir -p "$DIST_DIR"
cp "$SO" "$DIST_DIR/libvulkan_panfrost.so"
log "driver: $DIST_DIR/libvulkan_panfrost.so"
log "next: ./scripts/package.sh"
