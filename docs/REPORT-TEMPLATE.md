# PanVK Exynos 9611 test report

## Driver

- Version / release asset:
- SHA-256:
- Installed by (Termux / Winlator / ARMSX2):
- Date (UTC):

## Device

- Model:
- Android build:
- Kernel:
- Kbase DDK (`dmesg | grep -i mali`):
- GPU info (`cat /sys/class/misc/mali0/device/gpuinfo`):
- RAM free at test start:

## Test

- Level (L0/L1/L2/L3):
- App and version:
- Container / emulator settings:
- Renderer (Vulkan / DXVK version / ARMSX2 renderer):
- Resolution and frame limit:
- Steps to reproduce:

## Result

- Expected:
- Actual:
- FPS / frame time (if rendering):
- Visual corruption (screenshot attached?):

## Logs

- `vulkaninfo --summary`:
- `logcat -d -s panvk:* Mesa:* AndroidRuntime:E`:
- `dmesg | grep -iE 'mali|kbase|gpu|fault|mmu'`:
- Other:

## Additional context

Anything that changed since the last working build (driver, app, ROM, kernel, settings).
