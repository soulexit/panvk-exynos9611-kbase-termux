#!/bin/sh
# Shared helpers for the Exynos 9611 PanVK build. Source this file, do not execute it.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(cat "$ROOT/VERSION")

# Pinned base tree. Never follow a moving branch: a build must be reproducible from this commit.
SRC_REPO=${SRC_REPO:-https://github.com/JimVulkan/mali-panvk.git}
SRC_COMMIT=${SRC_COMMIT:-d896b0a9c10b92f0f9d53ef3373006b79ed709e8}
SRC_DIR=${SRC_DIR:-$ROOT/build/src/mali-panvk}
BUILD_DIR=${BUILD_DIR:-$ROOT/build/android}
DIST_DIR=${DIST_DIR:-$ROOT/dist}

log() { printf '==> %s\n' "$*" >&2; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "$1 not found in PATH"; }

# Print the NDK path from $1, then ANDROID_NDK_HOME, then ANDROID_NDK_ROOT.
find_ndk() {
    for candidate in "${1:-}" "${ANDROID_NDK_HOME:-}" "${ANDROID_NDK_ROOT:-}"; do
        if [ -n "$candidate" ] && [ -d "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

host_tag() {
    case "$(uname -s)-$(uname -m)" in
        Linux-x86_64) printf 'linux-x86_64\n' ;;
        Linux-aarch64|Linux-arm64) printf 'linux-aarch64\n' ;;
        Darwin-*) printf 'darwin-x86_64\n' ;;
        *) die "unsupported host: $(uname -s)-$(uname -m)" ;;
    esac
}

check_ndk() {
    ndk=$1
    bin="$ndk/toolchains/llvm/prebuilt/$(host_tag)/bin"
    [ -x "$bin/aarch64-linux-android31-clang" ] ||
        die "no API 31 arm64 compiler in $bin (NDK r29+ is required)"
    printf '%s\n' "$bin"
}
