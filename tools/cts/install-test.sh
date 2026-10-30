#!/bin/sh
# Install build-android/libvulkan_panfrost.so as the Termux CTS test driver.
set -e
adb push ${1:-build-android/libvulkan_panfrost.so} /data/local/tmp/lvp.so >/dev/null
adb shell su -c chmod 644 /data/local/tmp/lvp.so
"$(dirname "$0")/tx.sh" 'cp /data/local/tmp/lvp.so ~/panvk-test/d896/libvulkan_panfrost.so && ls -la ~/panvk-test/d896/libvulkan_panfrost.so'
