# Test results

The table is the source of truth for what has actually been run. "Pending" means the build exists
but has not been validated on the device.

## Device under test

| | |
|---|---|
| Model | Samsung Galaxy A51 4G (SM-A515F, `a51`) |
| SoC / GPU | Exynos 9611 / Mali-G72 MP3 r0p1 (`0x6221`) |
| Android | 16 / API 36, build `BP2A.250605.031.A2` |
| Kernel | 4.14.364-openela-SomethingNew-15-New |
| Kbase | DDK r38p1-01bet0, `/dev/mali0` |
| RAM | 6 GB |

## Builds

| Version | Date | Driver | L0 enumerate | L1 offscreen | L2 WSI | L3 app | Notes |
|---|---|---|---|---|---|---|---|
| v0.01 | 2026-10-21 | Mesa 26.3.0-devel, base `fb3b49d`, kbase JM | **PASS** | **PASS** (compute + triangle) | **PASS** (Winlator compositor) | pending (NFS/DXVK) | first debug build |

### v0.01 details

**L0 — enumeration (Termux, loader 1.4.365):**

```text
WARNING: panvk is not a conformant Vulkan implementation, testing use only.
deviceName         = Mali-G72 MC3
deviceID           = 0x62210010
apiVersion         = 1.3.358
driverVersion      = 26.2.99
driverID           = DRIVER_ID_MESA_PANVK
driverName         = panvk
driverInfo         = Mesa 26.3.0-devel (git-fb3b49d016)
```

The driver also reports `VK_EXT_headless_surface` and the full Android WSI surface extensions.

**L1 — compute:** 64 invocations, storage buffer readback matched `i * 2 + 1` for all 64 values
(first eight: `1 3 5 7 9 11 13 15`). No GPU fault.

**L1 — offscreen graphics:** 256×256 `VK_FORMAT_R8G8B8A8_UNORM` render pass, full-screen triangle,
readback centre `255,0,0,255`, 65,536 red pixels (entire image covered). This exercises the
vertex/tiler/fragment path, not only compute.

**L2 — Android WSI:** Winlator's own compositor (`Winlator_Renderer`) loaded the imported
`libvulkan_panfrost.so` and created a 1080×2400 swapchain on `Mali-G72 MC3`
(`vendorID=0x13b5`, `driverVersion=0x6802063`, `apiVersion=1.3.358`). The DXVK/NFS process exited
after about 13 seconds and no DXVK error was captured, so the game result is **inconclusive**.

**L3 — application:** pending. See the Winlator repository for the game test.

## Raw evidence

Store logs next to the release, not in git history. For each row keep:

```text
<version>/vulkaninfo-summary.txt
<version>/logcat.txt
<version>/dmesg-mali.txt
<version>/driver-sha256.txt
<version>/container-settings.txt   # Winlator / ARMSX2
```

Do not paste a driver binary into the repository; releases carry the binaries and SHA-256.

## How a row is promoted

1. L0: `panvk-run vulkaninfo --summary` lists the Mali-G72 and exits 0.
2. L1: a compute dispatch completes, readback matches, no GPU fault in `dmesg`.
3. L2: a swapchain presents at least 60 frames without `VK_ERROR_DEVICE_LOST`.
4. L3: the named app renders a scene; record resolution, FPS range and visible corruption.

A regression moves the row back. Do not leave a stale "works" claim.

## Known-good fallback

The vendor Vulkan driver (`/vendor/lib64/hw/vulkan.universal9611.so`) is untouched. Removing the
imported PanVK driver or selecting "System Vulkan driver" returns the app to the vendor driver.
