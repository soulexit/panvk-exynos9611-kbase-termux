# Vulkan CTS on the phone

How the per-extension results in `docs/CTS-RESULTS.md` were produced: Khronos VK-GL-CTS
`vulkan-cts-1.4.7.1`, built as an Android executable and run inside Termux against the test
driver through Termux's own Vulkan loader (which honours `VK_ICD_FILENAMES`).

## Build deqp-vk (on the PC)

```sh
git clone --branch vulkan-cts-1.4.7.1 https://github.com/KhronosGroup/VK-GL-CTS.git cts
cd cts && python3 external/fetch_sources.py
NDK=/opt/android-sdk/android-ndk-r30
cmake -B build-android -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-31 -DANDROID_NDK_PATH=$NDK \
  -DDEQP_TARGET=android -DDEQP_ANDROID_EXE=ON \
  -DDE_OS=DE_OS_ANDROID -DDE_CPU=DE_CPU_ARM_64 -DDE_COMPILER=DE_COMPILER_CLANG \
  -DDE_ANDROID_API=31 -DCMAKE_BUILD_TYPE=Release
ninja -C build-android deqp-vk
$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip \
  -o deqp-vk.stripped build-android/external/vulkancts/modules/vulkan/deqp-vk
```

Without the explicit `DE_OS`/`DE_CPU` flags the build detects the host (Unix/x86-64).

## Install (in Termux)

- `~/cts/deqp-vk` and the CTS data (`external/vulkancts/data/vulkan` → `~/cts/vulkan`).
- `~/cts/lib/` holding only a copy of Termux's `libvulkan.so.1` (also as `libvulkan.so`).
  deqp-vk resolves `libEGL` too, and Termux's `LD_LIBRARY_PATH` would hand it Termux's EGL,
  which does not have the symbols it wants.
- The driver under test: `~/panvk-test/d896/libvulkan_panfrost.so` and an `icd.json` that names
  it. `install-test.sh [path/to/libvulkan_panfrost.so]` pushes a build there.

## Run

`tx.sh` runs a command as the Termux app user (root via `adb shell su`). Set `ANDROID_SERIAL` if
the phone is on both USB and wireless adb.

```sh
python3 runcts.py all                 # every list in lists/, results/<ext>.csv (resumes)
python3 runcts.py KHR_synchronization2 EXT_robustness2
python3 quick.py some-cases.txt       # ad hoc: counts and every non-passing case
./one.sh dEQP-VK.some.case            # one case, its qpa in /tmp/one.qpa
```

`runcts.py` runs 200 cases per deqp-vk process with a 15-minute timeout and, when the process
dies, records the case it was in as `Crash` and carries on with the next one. deqp-vk refuses a
case list with duplicate entries, so `quick.py` deduplicates its input.

## Case lists

`lists.tgz` holds the exact lists behind the published results (130 extensions, 93,255 cases).
`mklists.py <cts checkout>` builds comparable ones from the `vk-default` mustpass: per extension
the cases whose names match its patterns in `extmap.py`, without the groups panvk does not expose
on Bifrost (shader objects, descriptor buffers and heaps, video, ray tracing, mesh shaders,
cooperative matrices, tensors, data graphs, device-generated commands), pipeline-library variants
only for the pipeline-library extensions, at most 1500 per extension. An extension with no
dedicated tests is covered by its API/info tests only.
