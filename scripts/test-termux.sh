#!/bin/sh
# Smoke-test the installed driver inside Termux.
#
# usage: ./scripts/test-termux.sh [--no-color]
set -eu

PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
ICD="$PREFIX/etc/vulkan/icd.d/panvk-exynos9611.json"
[ -f "$ICD" ] || { echo "error: $ICD not found; install the driver first" >&2; exit 1; }

command -v vulkaninfo >/dev/null 2>&1 || {
    echo "error: vulkaninfo not found; run: pkg install vulkan-tools" >&2; exit 1
}

export VK_ICD_FILENAMES="$ICD"
out=$(mktemp)
trap 'rm -f "$out"' EXIT INT TERM

echo "== ICD =="
cat "$ICD"
echo
echo "== vulkaninfo --summary =="
vulkaninfo --summary 2>&1 | tee "$out" || true

echo
if grep -qiE 'deviceName.*Mali-G72|driverName.*panvk|driverInfo.*PanVK' "$out"; then
    echo "RESULT: PASS - PanVK enumerated a Mali-G72 device"
    exit 0
fi
echo "RESULT: FAIL - no Mali-G72/PanVK device in vulkaninfo output"
echo "Try: PANVK_DEBUG=startup vulkaninfo --summary"
echo "Then: ./scripts/collect-logs.sh"
exit 1
