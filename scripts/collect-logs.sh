#!/bin/sh
# Collect device, kbase and driver logs into one tarball.
#
# Runs inside Termux (direct commands) or on a Linux host with adb. Root is used only for dmesg
# and is optional; the script keeps going when it is unavailable.
set -eu

stamp=$(date -u +%Y%m%dT%H%M%SZ)
outdir=${OUTDIR:-$HOME/panvk-logs-$stamp}
mkdir -p "$outdir"

if [ -n "${PREFIX:-}" ] && [ -d "$PREFIX" ] && command -v getprop >/dev/null 2>&1; then
    run() { sh -c "$1" > "$outdir/$2" 2>&1 || true; }
    run 'getprop' props.txt
    run 'uname -a' uname.txt
    run 'cat /proc/meminfo' meminfo.txt
    run 'cat /sys/class/misc/mali0/device/gpuinfo' gpuinfo.txt
    run 'cat /sys/class/misc/mali0/device/core_mask' core_mask.txt
    run 'dmesg | grep -iE "mali|kbase|gpu"' dmesg-mali.txt
    run 'su -c "dmesg | grep -iE \"mali|kbase|gpu\""' dmesg-mali-root.txt
    run 'logcat -d -s panvk:* Mesa:* AndroidRuntime:E' logcat.txt
    run 'vulkaninfo --summary' vulkaninfo-summary.txt
    run 'VK_ICD_FILENAMES=$PREFIX/etc/vulkan/icd.d/panvk-exynos9611.json PANVK_DEBUG=startup vulkaninfo --summary' vulkaninfo-startup.txt
else
    command -v adb >/dev/null 2>&1 || { echo "error: neither Termux nor adb found" >&2; exit 1; }
    adb shell getprop > "$outdir/props.txt" 2>&1 || true
    adb shell 'uname -a; cat /proc/meminfo' > "$outdir/uname-meminfo.txt" 2>&1 || true
    adb shell 'cat /sys/class/misc/mali0/device/gpuinfo; cat /sys/class/misc/mali0/device/core_mask' > "$outdir/gpuinfo.txt" 2>&1 || true
    adb shell 'dmesg | grep -iE "mali|kbase|gpu"' > "$outdir/dmesg-mali.txt" 2>&1 || true
    adb logcat -d -s 'panvk:*' 'Mesa:*' 'AndroidRuntime:E' > "$outdir/logcat.txt" 2>&1 || true
fi

cat > "$outdir/README.txt" <<EOF
PanVK Exynos 9611 log bundle
collected: $stamp
device:    $(adb shell getprop ro.product.model 2>/dev/null || getprop ro.product.model 2>/dev/null || echo unknown)
build:     $(adb shell getprop ro.build.display.id 2>/dev/null || getprop ro.build.display.id 2>/dev/null || echo unknown)
EOF

tar -czf "$outdir.tar.gz" -C "$(dirname -- "$outdir")" "$(basename -- "$outdir")"
rm -rf "$outdir"
echo "wrote $outdir.tar.gz"
