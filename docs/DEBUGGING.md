# Debugging

## First response to any failure

```sh
# 1. Which device did the driver see?
cat /sys/class/misc/mali0/device/gpuinfo

# 2. What does the loader/driver say?
PANVK_DEBUG=startup vulkaninfo --summary 2>&1 | tee /tmp/startup.log
logcat -d -s panvk:* Mesa:* AndroidRuntime:E > /tmp/logcat.txt

# 3. Did the GPU fault?
dmesg | grep -iE 'mali|kbase|gpu|fault|mmu' | tail -100
```

Run `scripts/collect-logs.sh` to bundle all of it.

## Runtime switches

| Variable | Effect |
|---|---|
| `PANVK_DEBUG=startup` | Device-creation diagnostics |
| `PANVK_DEBUG=trace` | Verbose submission/queue tracing |
| `PANVK_DEBUG=coherent_before_cached` | Cache coherency workaround for debugging |
| `PANVK_FORCE_IDVS=1` | Re-enable index-driven vertex shading (off on Bifrost by default) |
| `MESA_LOG=stderr` | Mesa logs to stderr instead of logcat |
| `MESA_SHADER_CACHE_DISABLE=1` | Disable the on-disk shader cache |
| `MESA_SHADER_CACHE_DIR=/tmp/panvk-cache` | Use a writable cache directory |

`PANVK_DEBUG` values are checked in the driver source; an unknown value is ignored.

## Failure classes

### `Unknown gpu_id (0x...) or variant (0x...)`

The kbase GPU properties did not match a Mesa model row. The base tree forces `gpu_variant = 0`
for kbase. On this device the expected id is `0x6221` (G72, variant 0). If the A51 reports a
different id, capture `gpuinfo` and the `PANVK_DEBUG=startup` output and add a model row or a
variant-ignore patch.

### `MEM_JIT_INIT` / `ENOMEM` during device creation

The Bifrost kbase path does not need JIT and the base tree skips `KBASE_IOCTL_MEM_JIT_INIT` on JM.
If a log shows JIT being called, the tree or patch set is wrong. Tiler/varying heaps use
`GROW_ON_GPF` instead.

### `JOB_CONFIG_FAULT`, `EINVAL` on submit, or an immediate device loss

The most likely cause on a new kbase is the **atom stride/layout**. The base tree submits a fixed
64-byte `base_jd_atom` (`u64 seq_nr` followed by `base_jd_atom_v2`). Other kbase builds accept 56
or 72 bytes. Symptoms:

- `KBASE_IOCTL_JOB_SUBMIT` returns `EINVAL`;
- `dmesg` reports `JOB_CONFIG_FAULT`;
- every job fails but enumeration works.

Capture the first submit error and the kbase version. A stride probe may need to be added as a
local patch. Do not guess: try 64, then 56, then 72, one at a time, with a dependency-only atom
before testing a real draw.

### `VK_ERROR_DEVICE_LOST`

A GPU fault occurred. Check `dmesg` for `fault`, `MMU`, `AS_FAULT`, `TRANSLATION_FAULT` or a
`JS` reset. Force-stop the app; if kbase remains wedged, reboot the phone. Then reproduce with the
smallest possible workload (enumeration → compute → one triangle).

### Swapchain works but the screen is black

- Confirm the container/emulator is actually using the imported driver, not the system Vulkan.
- Check gralloc errors: the driver needs a working `libgralloctypes`/gralloc mapper. On Android 16
  the vendor gralloc may allocate AFBC in a layout PanVK cannot import; image AHardwareBuffers ask
  for linear, but the swapchain path still depends on the app's usage flags.
- Try `MALI_GRALLOC_USAGE_NO_AFBC`-style flags through the app if it exposes them.

### App crashes when the driver is loaded

- `minApi` of the driver is 31. Android 12+ only.
- Check `logcat` for `dlopen` failures and missing symbols.
- Termux: use `panvk-run`, not a raw `VK_ICD_FILENAMES` pointing at a missing path.
- Winlator/ARMSX2: make sure the zip layout matches that app's importer (see those repos).

## kbase state

```sh
ls -l /dev/mali0
cat /sys/class/misc/mali0/device/core_mask
cat /sys/class/misc/mali0/device/dvfs_governor
cat /sys/class/misc/mali0/device/clock
```

`core_mask 0x7` means all three G72 cores are available. A mask of `0x0` or a stuck clock usually
means the GPU is wedged; reboot.

## Log tags

| Tag | Source |
|---|---|
| `panvk` | PanVK driver |
| `Mesa` | Mesa common code |
| `mali` | kbase kernel messages (dmesg) |
| `kbase` | kbase kernel messages (dmesg) |
| `AndroidRuntime` | Java crash |

## Shader cache

On Android the driver may keep a disk shader cache in the app's cache directory. If a pipeline
change produces corrupt output after replacing the driver, clear the app's cache (or the emulator's
"clear shader cache" option) before filing a bug.

## Safety

The driver runs in the app process and submits raw GPU jobs. A malformed job can hang the GPU or
corrupt the app's GPU memory. Test with apps whose data you can lose, keep the vendor Vulkan driver
available, and reboot if the GPU stops responding.
