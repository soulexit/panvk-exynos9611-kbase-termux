# Testing

A build is only "working" for the level it has actually passed. Use the following levels and record
the level in [`TEST-RESULTS.md`](TEST-RESULTS.md).

| Level | What it proves | Command |
|---|---|---|
| **L0** | The loader can open the ICD and enumerate a physical device | `panvk-run vulkaninfo --summary` |
| **L1** | Device creation, memory allocation, compute/offscreen submission | a Vulkan compute or offscreen sample |
| **L2** | Swapchain and presentation through Android gralloc / X11 | `vkcube` in Winlator or Termux:X11 |
| **L3** | A real application renders frames | Winlator + DXVK game, ARMSX2 game |

Do not describe a build as "Vulkan works" from L0 alone.

## Termux smoke test

```sh
pkg install vulkan-tools
./scripts/test-termux.sh
```

The script:

1. verifies `$PREFIX/etc/vulkan/icd.d/panvk-exynos9611.json` exists;
2. exports `VK_ICD_FILENAMES` to that manifest only;
3. runs `vulkaninfo --summary`;
4. passes when the output contains a Mali-G72/PanVK device.

Manual equivalent:

```sh
export VK_ICD_FILENAMES=$PREFIX/etc/vulkan/icd.d/panvk-exynos9611.json
vulkaninfo --summary
```

## What good output looks like

`vulkaninfo --summary` should contain one physical device whose name includes `Mali-G72`, with
`driverName` from PanVK and a Mesa `26.3.0-devel` driver info string. The exact API version and
extension list are recorded per build; do not copy them into the README without a fresh dump.

If enumeration fails, run:

```sh
PANVK_DEBUG=startup vulkaninfo --summary 2>&1 | tee /tmp/panvk-startup.log
```

Common messages and what they mean are in [`DEBUGGING.md`](DEBUGGING.md).

## Offscreen / compute test

Offscreen rendering is the first test that exercises real submissions. Until a packaged sample is
added, use any Vulkan compute sample or Mesa's `vulkaninfo --summary` plus a small custom program.
The test must:

1. create a `VkDevice`;
2. allocate device-local memory;
3. submit a compute dispatch;
4. wait for a fence and read back a known pattern;
5. destroy everything without a GPU fault in `dmesg`.

If the app is killed, check `dmesg | grep -iE 'mali|kbase'` for `fault`, `0x...`, `JOB_CONFIG_FAULT`
or `MMU` lines.

## Winlator test

See the [Winlator repository](https://github.com/soulexit/panvk-exynos9611-kbase-winlator). The
short version:

1. import the driver zip;
2. create/select a container with DXVK enabled;
3. run `vkcube.exe` or a D3D9 game;
4. collect `logcat` and the Wine/DXVK log;
5. record FPS, resolution, container settings and the selected driver.

## ARMSX2 test

See the [ARMSX2 repository](https://github.com/soulexit/panvk-exynos9611-kbase-armsx2). ARMSX2
expects `libvulkan_freedreno.so` at the zip root, so use that package, not the Winlator one.

## Reproducing a report

Copy [`REPORT-TEMPLATE.md`](REPORT-TEMPLATE.md), fill it in, attach:

- `vulkaninfo --summary` output;
- `logcat -d -s panvk:* Mesa:* AndroidRuntime:E`;
- `dmesg | grep -iE 'mali|kbase|gpu'`;
- the app version, container settings and game/emulator settings;
- the driver zip name and SHA-256.

Never attach a full `logcat` without checking it for account names or file paths you do not want to
publish.
