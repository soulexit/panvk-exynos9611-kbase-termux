#!/bin/sh
# Build inside `proot-distro login ubuntu`. Slow, but needs no second computer.
#
# usage (from Termux):
#   proot-distro login ubuntu -- bash -lc '
#     cd /data/data/com.termux/files/home/panvk-exynos9611-kbase-termux &&
#     ./scripts/build-in-proot.sh --install-deps'
#
# The Android NDK must be visible inside the container. Put it at $HOME/android-ndk-r30 or set
# ANDROID_NDK_HOME. NDK downloads are large; this script does not fetch one automatically.
set -eu
. "$(dirname -- "$0")/lib.sh"

install_deps=0
[ "${1:-}" = "--install-deps" ] && install_deps=1

[ "$(id -u)" = 0 ] || die "run this inside proot-distro (root inside the container)"
[ -f /etc/os-release ] || die "no /etc/os-release; this is not a Linux container"
. /etc/os-release
log "container: $PRETTY_NAME"

if [ "$install_deps" = 1 ]; then
    log "installing build dependencies"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential meson ninja-build pkg-config python3 python3-mako \
        python3-packaging python3-yaml glslang-tools git curl unzip ca-certificates \
        llvm-dev libclang-dev clang libclc-dev libllvmspirvlib-dev
fi

for tool in meson ninja python3 pkg-config glslangValidator git; do
    need "$tool"
done

NDK=$(find_ndk "${ANDROID_NDK_HOME:-}") || NDK=""
if [ -z "$NDK" ]; then
    for candidate in "$HOME/android-ndk-r30" "/root/android-ndk-r30" "/opt/android-ndk-r30"; do
        [ -d "$candidate" ] && NDK=$candidate && break
    done
fi
[ -n "$NDK" ] || die "Android NDK not found.
Download it inside the container, for example:
  curl -LO https://dl.google.com/android/repository/android-ndk-r30-linux.zip
  unzip android-ndk-r30-linux.zip -d \$HOME
  export ANDROID_NDK_HOME=\$HOME/android-ndk-r30"

log "using NDK: $NDK"
"$ROOT/scripts/fetch-source.sh"
"$ROOT/scripts/build.sh" "$NDK" --no-fetch
"$ROOT/scripts/package.sh"
log "done"
