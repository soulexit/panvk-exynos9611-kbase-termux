# PanVK for Exynos 9611 / Mali-G72 MP3 — Termux

Experimental **Mesa PanVK** Vulkan driver for the **Samsung Galaxy A51 (SM-A515F, `a51`)** and other
**Exynos 9611** devices with a **Mali-G72 MP3** GPU.

The driver talks directly to the phone's stock **Arm `mali_kbase`** kernel driver through
`/dev/mali0`. It does **not** need `/dev/dri`, a custom kernel, or a Panfrost DRM port. Root is only
needed for optional log collection, not for using the driver.

This repository is the **source of truth** for the Exynos 9611 port. It builds the driver, installs
it in Termux, runs smoke tests, and publishes the binaries consumed by the Winlator and ARMSX2
packaging repositories.

| | |
|---|---|
| **Device** | Samsung Galaxy A51 4G (SM-A515F, `a51`) |
| **SoC** | Samsung Exynos 9611 (`universal9611`) |
| **GPU** | Mali-G72 MP3, r0p1, GPU info `0x6221` / Mesa arch **v6 (Bifrost, Job Manager)** |
| **RAM** | 6 GB (5.4 GiB usable) |
| **Android** | 16 / API 36 (`BP2A.250605.031.A2`, custom ROM) |
| **Kernel** | Linux 4.14.364-openela (`SomethingNew`) |
| **Kbase** | Arm DDK `r38p1-01bet0`, `/dev/mali0` mode `0666` |
| **Display** | 1080 × 2400 |
| **Status** | **v0.01 — bring-up / debug build. Not stable, not conformant.** |

> [!WARNING]
> This is a debug-quality driver built from a heavily modified Mesa tree. It can hang the GPU,
> kill the app that loads it, or require a reboot. Keep a known-good driver installed, and do not
> use it for anything you cannot lose.

## Why this repository exists

Mali-G72 is **Bifrost generation 1 (Mesa `PAN_ARCH` 6)**. Upstream PanVK still treats v6/v7 as
experimental and gates them behind `PAN_I_WANT_A_BROKEN_VULKAN_DRIVER`; on Android the loader loads
the ICD inside an app process, so an environment gate is not usable. Stock Samsung kernels only
expose `mali_kbase`, not the upstream `panfrost`/`panthor` DRM interface.

This port therefore combines:

1. **Mesa PanVK** (Vulkan 1.3 on Bifrost) from the pinned tree below.
2. A **kbase Job Manager backend** (`/dev/mali0`, 64-byte `base_jd_atom`, no JIT).
3. Bifrost-specific work from **JimVulkan/mali-panvk**, which already targets the same
   Exynos 9611 + Mali-G72 MP3 combination (Galaxy Tab S6 Lite).
4. Device-specific packaging, test tooling and documentation for the Galaxy A51.

### Upstream / base

| Item | Value |
|---|---|
| Base tree | [`JimVulkan/mali-panvk`](https://github.com/JimVulkan/mali-panvk) |
| Pinned commit | `fb3b49d016544c19d83e558462f2d29470e77c28` |
| Mesa version | `26.3.0-devel` |
| Base license | MIT (changes), Mesa per-file licenses |
| Local patches | `patches/` (series applied on top of the pinned commit) |

JimVulkan's tree is MIT-licensed. Mesa components keep their original licenses. See
[`NOTICE.md`](NOTICE.md) and the `NOTICE.txt` shipped in release packages. This project is not
affiliated with or endorsed by Arm, Samsung, Google, Mesa, JimVulkan or the Panfrost project.

## Goal

Run real Vulkan workloads on the A51's Mali-G72 through `mali_kbase`, and make that driver usable
from the three app families people actually run on this phone:

| Consumer | Repository | What it needs |
|---|---|---|
| **Termux** | this repo | Bionic arm64 ICD + JSON manifest, `vulkaninfo`/`vkcube` smoke tests |
| **Winlator** | [`panvk-exynos9611-kbase-winlator`](https://github.com/soulexit/panvk-exynos9611-kbase-winlator) | AdrenoTools-style zip: `meta.json` + `libvulkan_panfrost.so` |
| **ARMSX2** | [`panvk-exynos9611-kbase-armsx2`](https://github.com/soulexit/panvk-exynos9611-kbase-armsx2) | AdrenoTools-style zip with `libvulkan_freedreno.so` at the root |

The long-term target is **Vulkan 1.3 with DXVK D3D9/10/11** in Winlator and a usable Vulkan
renderer in ARMSX2. Geometry shaders, tessellation and transform feedback are emulated with compute
jobs because Bifrost has no hardware support for them.

## Current status

Versioning is `v0.01`, `v0.02`, … for debug builds; a build only moves forward when the test log in
[`docs/TEST-RESULTS.md`](docs/TEST-RESULTS.md) is updated.

| Build | Date | Driver | Termux `vulkaninfo` | Winlator | ARMSX2 | Notes |
|---|---|---|---|---|---|---|
| v0.01 | 2026-10-21 | Mesa 26.3.0-devel + kbase JM | **PASS** (L0 + L1 + offscreen) | **swapchain PASS**, game pending | package built, import pending | First device build; see test log |

### v0.01 device validation

Run on the A51, Android 16 / kbase r38p1, Termux loader 1.4.365:

| Test | Result | Evidence |
|---|---|---|
| ICD enumeration | **PASS** | `deviceName = Mali-G72 MC3`, `driverName = panvk`, `apiVersion = 1.3.358` |
| Device + memory creation | **PASS** | compute sample created a device, buffer and host-visible allocation |
| Compute submission | **PASS** | 64 invocations, readback `1 3 5 7 9 11 13 15 …`, exact match |
| Offscreen graphics | **PASS** | full-screen triangle, 65,536 red pixels, centre `255,0,0,255` |
| Android swapchain (Winlator) | **PASS** | Winlator compositor created a 1080×2400 swapchain on `Mali-G72 MC3` |
| DXVK game | pending | NFS process exited after ~13 s without a captured DXVK error |

The complete log is in [`docs/TEST-RESULTS.md`](docs/TEST-RESULTS.md). The Winlator/DXVK result is
deliberately **not** marked as working: a loaded driver and a created swapchain are not the same as
a rendered game.

### What should work (inherited from the base tree)

- Vulkan 1.3 as exposed by PanVK on Bifrost.
- Compute, vertex/tiler/fragment submission through `KBASE_IOCTL_JOB_SUBMIT`.
- Offscreen rendering and readback.
- Android gralloc swapchains and `AHardwareBuffer` import (Arm handle layout).
- DXVK D3D9/10/11 feature set: robustness2, null descriptors, geometry/tessellation/transform
  feedback emulation, multi-draw indirect, multiple vertex streams.

### Known limitations

- **Mali-G72 is v6, the least-tested Bifrost path.** The base tree validates G72 on a Tab S6 Lite;
  the A51's Android 16 + kbase r38 combination is new and may expose kernel/ABI differences.
- **No native BCn.** Winlator's Vulkan wrapper may decode BC textures; native BC is not implemented.
- **No D3D12 / vkd3d-proton path.** That needs features this driver does not provide yet.
- **GS/tessellation/XFB are compute-emulated**, so they are slow on a 3-core G72.
- **4–6 GB shared RAM.** GPU allocations come out of the same memory as Android and Wine.
- **Termux presentation is not solved yet.** `vulkaninfo` works headless; an on-screen Termux
  surface needs Termux:X11/XCB support and is tracked as a separate task.
- **Android 16 gralloc changes** may affect window-system integration; offscreen tests come first.

## Repository layout

```text
README.md                  this file
VERSION                    current debug build number (0.01)
NOTICE.md                  attribution and licensing
profiles/                  device/kbase profile (JSON)
patches/                   local patch series on top of the pinned base commit
scripts/
  fetch-source.sh          clone + pin + patch the Mesa tree
  build.sh                 host build with the Android NDK
  build-in-proot.sh        build inside `proot-distro login ubuntu`
  package.sh               build the Termux release zip
  install-termux.sh        install / uninstall inside Termux
  test-termux.sh           vulkaninfo + smoke test
  collect-logs.sh          gather device, kbase and driver logs
  lib.sh                   shared helpers
icd/                       Vulkan ICD manifest template
docs/
  DEVICE.md                hardware, kernel and kbase details
  BUILD.md                 host, Termux and proot build instructions
  TESTING.md               test procedure and what to report
  DEBUGGING.md             environment switches, log tags, fault triage
  TEST-RESULTS.md          per-build results (updated every release)
  REPORT-TEMPLATE.md       copy/paste test report
```

## Dependencies

### Host build (recommended)

Ubuntu 24.04/26.04 or similar, x86_64:

```sh
sudo apt install build-essential meson ninja-build pkg-config python3 \
  python3-mako python3-packaging python3-yaml glslang-tools \
  llvm-20-dev libclang-20-dev clang-20 libclc-20-dev libllvmspirvlib-20-dev
```

- Android NDK **r29 or newer** (r30 tested here), API 31 arm64 toolchain.
- Meson **≥ 1.4**, Ninja, Python **≥ 3.10**.
- `glslangValidator` **≥ 12.2**.
- One LLVM major version for the host tools (`mesa_clc`, `vtn_bindgen2`,
  `panfrost_compile`): LLVM/clang/libclc/SPIR-V LLVM translator must match. LLVM 20 is used here.

Dependencies fetched by Meson at configure time: libdrm 2.4.133, zlib 1.3.1, Expat 2.5.0. The
first configure needs network access.

### Termux runtime

```sh
pkg update
pkg install vulkan-tools vulkan-loader
```

- Android 12+ (driver is built for API 31), arm64-v8a.
- No root required. `/dev/mali0` must be readable/writable by the app UID (it is `0666` on the A51).

### proot Ubuntu build

```sh
proot-distro login ubuntu
# inside the container:
apt update
apt install build-essential meson ninja-build pkg-config python3 \
  python3-mako python3-packaging python3-yaml glslang-tools \
  llvm-20-dev libclang-20-dev clang-20 libclc-20-dev libllvmspirvlib-20-dev git curl unzip
```

The NDK must be inside the container (for example `~/android-ndk-r30`). `scripts/build-in-proot.sh`
checks for it and explains how to fetch it.

## Build

```sh
git clone https://github.com/soulexit/panvk-exynos9611-kbase-termux.git
cd panvk-exynos9611-kbase-termux
./scripts/fetch-source.sh
./scripts/build.sh /opt/android-sdk/android-ndk-r30
./scripts/package.sh
```

`build.sh` builds the three host tools first, then the arm64 driver, strips it, and writes
`dist/`. It is intentionally the same two-stage flow as the base project because the OpenCL helper
kernels must be generated by tools from the same Mesa tree.

Useful variables:

| Variable | Default | Meaning |
|---|---|---|
| `ANDROID_NDK_HOME` | — | NDK path if not passed as `$1` |
| `BUILD_DIR` | `build/android` | Driver build directory |
| `SRC_DIR` | `build/src/mali-panvk` | Pinned source checkout |

### Build inside proot Ubuntu

```sh
proot-distro login ubuntu -- bash -lc '
  cd /data/data/com.termux/files/home/panvk-exynos9611-kbase-termux &&
  ./scripts/build-in-proot.sh
'
```

Termux and proot share the same filesystem, so the checkout can live in Termux home and be built
from the container. This is slower than the host build but needs no second computer.

### Build directly in Termux (host tools only)

Termux has clang, meson, ninja, python and glslang, so the **host tools** can be built there. The
full Mesa build is memory-hungry on a 6 GB phone; use proot Ubuntu or a Linux host for the driver.
The scripts do not modify Termux packages automatically.

## Install in Termux

From a release zip:

```sh
cd ~
curl -LO https://github.com/soulexit/panvk-exynos9611-kbase-termux/releases/download/v0.01/panvk-exynos9611-termux-v0.01.zip
unzip -o panvk-exynos9611-termux-v0.01.zip -d panvk-v001
bash panvk-v001/install-termux.sh
```

From a local build:

```sh
./scripts/install-termux.sh --from-zip dist/panvk-exynos9611-termux-v0.01.zip
```

The installer writes:

```text
$PREFIX/lib/panvk-exynos9611/libvulkan_panfrost.so
$PREFIX/etc/vulkan/icd.d/panvk-exynos9611.json
$PREFIX/bin/panvk-run
```

`panvk-run` sets `VK_ICD_FILENAMES` and runs a command with only the PanVK ICD visible:

```sh
panvk-run vulkaninfo --summary
panvk-run vkcube            # needs a display (Termux:X11)
```

To use the driver for the current shell only:

```sh
export VK_ICD_FILENAMES=$PREFIX/etc/vulkan/icd.d/panvk-exynos9611.json
```

Uninstall:

```sh
./scripts/install-termux.sh --uninstall
```

## Test

```sh
./scripts/test-termux.sh
```

The script checks the ICD manifest, runs `vulkaninfo --summary`, and reports whether the physical
device is a Mali-G72/PanVK device. Attach the output to a test report.

Collect logs for a bug report:

```sh
./scripts/collect-logs.sh
# writes dist/panvk-logs-<timestamp>.tar.gz
```

## Debugging

| Switch | Effect |
|---|---|
| `PANVK_DEBUG=startup` | Why the physical device could not be created |
| `PANVK_DEBUG=trace` | Verbose driver tracing |
| `PANVK_FORCE_IDVS=1` | Re-enable index-driven vertex shading (off by default on Bifrost) |
| `MESA_LOG=stderr` | Send Mesa logs to stderr instead of logcat |

Useful commands:

```sh
logcat -d -s panvk:* Mesa:* AndroidRuntime:E
dmesg | grep -iE 'mali|kbase|gpu'
cat /sys/class/misc/mali0/device/gpuinfo
cat /sys/class/misc/mali0/device/core_mask
```

See [`docs/DEBUGGING.md`](docs/DEBUGGING.md) for fault triage and the report template.

## Releases

Every release contains:

- `libvulkan_panfrost.so` (stripped, arm64, API 31)
- `panvk-exynos9611.json` (ICD manifest with an install-time path placeholder)
- `install-termux.sh` / `uninstall` support
- `NOTICE.txt`, `LICENSE`, `SHA256SUMS`
- `BUILD-INFO.txt` (base commit, patches, NDK, Mesa, build date, git commit)

Releases are immutable. A new patch series or Mesa pin gets a new `v0.0x` tag. The release notes
must include the test results and the exact device/kbase combination.

## Versioning

| Version | Meaning |
|---|---|
| `v0.01` | first device build, debug only |
| `v0.02+` | each driver change or test-driven fix |
| `v1.00` | reserved for a build that passes the documented Termux + Winlator + ARMSX2 test matrix |

## Test results

Results are kept in [`docs/TEST-RESULTS.md`](docs/TEST-RESULTS.md). The table is the source of
truth: do not claim a build works on a configuration that is not listed there.

## Credits

- **Mesa / Panfrost / PanVK** — the driver this is built from.
- **JimVulkan/mali-panvk** — Bifrost kbase port, Exynos 9611/G72 validation, GS/tess/XFB
  emulation, Android gralloc/WSI work. MIT.
- **LukeValen/panvk-mali-g52** and **zenithblue-oss/panvk-kbase-android** — public Bifrost/kbase
  research and packaging references.
- Everyone who tested an experimental Mali Vulkan driver and sent logs.

## License

The build scripts, documentation and local patches in this repository are MIT licensed. Mesa and
base-tree files keep their own licenses; see [`NOTICE.md`](NOTICE.md). No warranty of any kind.
