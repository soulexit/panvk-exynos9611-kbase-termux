# Target device

## Hardware

| Item | Value | How to check |
|---|---|---|
| Model | Samsung Galaxy A51 4G | `getprop ro.product.model` → `SM-A515F` |
| Codename | `a51` | `getprop ro.product.device` |
| SoC | Samsung Exynos 9611 | `getprop ro.board.platform` → `universal9611` |
| GPU | Mali-G72 MP3, r0p1 | `cat /sys/class/misc/mali0/device/gpuinfo` → `Mali-G72 3 cores r0p1 0x6221` |
| Mesa arch | **6** (Bifrost 1st gen) | product id `0x6221` in `pan_model.c` |
| RAM | 6 GB (5,707,564 kB total) | `grep MemTotal /proc/meminfo` |
| Display | 1080 × 2400 | `wm size` |
| Android | 16 / API 36 | `getprop ro.build.version.release` / `ro.build.version.sdk` |
| Build | `BP2A.250605.031.A2` | `getprop ro.build.display.id` |
| Kernel | `4.14.364-openela-SomethingNew-15-New` | `uname -a` |
| Kbase DDK | `r38p1-01bet0` | `dmesg \| grep -i mali` |
| Mali node | `/dev/mali0`, `crw-rw-rw- system system` | `ls -l /dev/mali0` |

The device has **no `/dev/dri`**. The only GPU kernel interface is Arm's proprietary `mali_kbase`,
which is why this port uses the kbase Job Manager backend instead of the upstream Panfrost/Panthor
DRM interface.

## Kernel log at boot

```text
mali 11500000.mali: Kernel DDK version r38p1-01bet0
mali 11500000.mali: GPU identified as 0x1 arch 6.2.2 r0p1 status 0
mali 11500000.mali: No priority control manager is configured
mali 11500000.mali: No memory group manager is configured
mali 11500000.mali: No OPPs found in device tree! Scaling timeouts using 100000 kHz
mali 11500000.mali: Probed as mali0
```

`arch 6.2.2` is the hardware architecture field reported by kbase; Mesa maps product id `0x6221`
to the G72 row. This is the v6 Bifrost backend.

## Sysfs facts

```sh
cat /sys/class/misc/mali0/device/gpuinfo
# Mali-G72 3 cores r0p1 0x6221

cat /sys/class/misc/mali0/device/core_mask
# Current core mask (JS0) : 0x7
# Current core mask (JS1) : 0x7
# Current core mask (JS2) : 0x7
# Available core mask : 0x7
```

Some files under `/sys/class/misc/mali0/device/` are root-only. Reading `gpuinfo` and `core_mask`
does not need root on this device.

## Graphics stack

| Layer | Component | Note |
|---|---|---|
| Kernel | `mali_kbase` r38p1 | Job Manager, `/dev/mali0` |
| Vendor GLES | `/vendor/lib64/egl/libGLES_mali.so` | Not used by PanVK |
| Vendor Vulkan | `/vendor/lib64/hw/vulkan.universal9611.so` | Not used by PanVK |
| Our Vulkan | `libvulkan_panfrost.so` | PanVK over kbase |
| Loader | `/system/lib64/libvulkan.so` (apps), Termux loader | `VK_ICD_FILENAMES` selects the ICD |

The vendor Vulkan driver remains installed and is the fallback. Nothing in this project replaces
files in `/vendor` or `/system`.

## What "kbase" means here

`mali_kbase` is Arm's out-of-tree Android GPU driver. User space submits "job atoms" with
`KBASE_IOCTL_JOB_SUBMIT`; memory is allocated with `KBASE_IOCTL_MEM_ALLOC`; GPU properties are read
with `KBASE_IOCTL_GET_GPUPROPS`. PanVK's kbase backend implements the `pan_kmod` interface on top of
those ioctls, so the rest of PanVK is unchanged.

The A51's kbase is old (r38p1, kernel 4.14). Newer Android devices use CSF and a different
submission model. The Bifrost JM path is therefore the relevant one: one atom carries a chain of
vertex/tiler/fragment jobs, and the kernel returns a `BASE_JD_EVENT_DONE` fence.

## Version and build identifiers

The driver package reports:

- Mesa `26.3.0-devel`
- PanVK API `1.3`
- kbase profile `exynos9611-g72-jm`
- local build tag `v0.01` and the git commit of this repository

`vulkaninfo` shows the Mesa version in `driverInfo`; include it in every report.
