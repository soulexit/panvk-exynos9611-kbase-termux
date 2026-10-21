# Building

There are three supported ways to build. The host build is the reference; the proot build is for
people who only have the phone; the Termux path builds the host tools and is useful for quick
patches, but the full driver is memory-hungry on a 6 GB phone.

## 1. Linux host with the Android NDK (reference)

Tested on Ubuntu 24.04 x86_64 with:

| Tool | Tested version |
|---|---|
| Android NDK | r30 (`/opt/android-sdk/android-ndk-r30`) |
| Meson | 1.4+ |
| Ninja | 1.13 |
| Python | 3.12 + mako, packaging, pyyaml |
| glslangValidator | 15.1.0 |
| LLVM / clang / libclc / libLLVMSPIRVLib | 20.1 |

### Packages

Ubuntu 24.04:

```sh
sudo apt install build-essential meson ninja-build pkg-config python3 \
  python3-mako python3-packaging python3-yaml glslang-tools \
  llvm-20-dev libclang-20-dev clang-20 libclc-20-dev libllvmspirvlib-20-dev
```

Ubuntu 26.04 usually has a newer default LLVM. Either install the matching `-20` packages or use
the default set, as long as **clang, libclc and libLLVMSPIRVLib are the same major version**:

```sh
sudo apt install build-essential meson ninja-build pkg-config python3 \
  python3-mako python3-packaging python3-yaml glslang-tools \
  llvm-dev libclang-dev clang libclc-dev libllvmspirvlib-dev
llvm-config --version
```

### NDK

Download from <https://developer.android.com/ndk/downloads> and unpack somewhere stable:

```sh
export ANDROID_NDK_HOME=$HOME/android-ndk-r30
```

The build needs `aarch64-linux-android31-clang` in
`$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin`.

### Build

```sh
git clone https://github.com/soulexit/panvk-exynos9611-kbase-termux.git
cd panvk-exynos9611-kbase-termux
./scripts/fetch-source.sh
./scripts/build.sh "$ANDROID_NDK_HOME"
./scripts/package.sh
```

`fetch-source.sh` clones the pinned base tree (blobless), checks out
`fb3b49d016544c19d83e558462f2d29470e77c28`, and applies `patches/*.patch` in filename order.
`build.sh` runs the base tree's two-stage build with `BUILD_DIR` pointed at this repository's
`build/android`.

First configure downloads libdrm, zlib and Expat through Meson subprojects. If the machine has no
network, pre-populate `subprojects/packagecache/` in the source checkout.

### Output

```text
build/android/libvulkan_panfrost.so
dist/libvulkan_panfrost.so
dist/panvk-exynos9611-termux-v0.01.zip
```

## 2. Inside proot Ubuntu (phone only)

Termux's `proot-distro` container is slow but self-contained. The container and Termux share
`/data/data/com.termux/files/home`.

```sh
proot-distro login ubuntu -- bash -lc '
  cd /data/data/com.termux/files/home/panvk-exynos9611-kbase-termux &&
  ./scripts/build-in-proot.sh --install-deps'
```

The script installs the packages listed above and looks for the NDK in `$HOME/android-ndk-r30`,
`/root/android-ndk-r30` and `/opt/android-ndk-r30`. If it is missing, download it inside the
container:

```sh
curl -LO https://dl.google.com/android/repository/android-ndk-r30-linux.zip
unzip android-ndk-r30-linux.zip -d "$HOME"
export ANDROID_NDK_HOME="$HOME/android-ndk-r30"
```

Then rerun `build-in-proot.sh` without `--install-deps`. Builds can take a long time on the phone;
run them with the charger connected and the screen on if Android is aggressive about background
processes.

## 3. Host tools in Termux

The first build stage (`mesa_clc`, `vtn_bindgen2`, `panfrost_compile`) is plain host code. Termux
has clang, meson, ninja, python and glslang, so it can build those tools natively:

```sh
pkg install clang meson ninja python python-pip glslang
pip install mako packaging pyyaml
```

The driver stage still needs an Android NDK sysroot and is best done on a host or in proot. If you
cross-compile from Termux with an NDK unpacked in Termux home, run the same `scripts/build.sh`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `no API 31 arm64 compiler` | NDK is too old or the path is wrong; use r29+ and check `toolchains/llvm/prebuilt/*/bin` |
| Meson cannot find LLVM | Install the `-dev` packages and make sure `llvm-config` is on `PATH` |
| `libclc` / `libLLVMSPIRVLib` version mismatch | Use one LLVM major version for clang, libclc and the SPIR-V translator |
| `glslangValidator not found` | Install `glslang-tools` (Ubuntu) or `glslang` (Termux) |
| Subproject download fails | Check network; remove `build/src/mali-panvk/subprojects/packagecache` only if it is corrupt |
| OOM during `ninja` | Close apps, add swap, or build in proot/host; do not run the full build in Termux on 6 GB |
| `install-termux.sh: unzip not found` | `pkg install unzip` |

## Reproducibility

`BUILD-INFO.txt` in every release records the base commit, patch count, Mesa version, build time,
git commit and driver SHA-256. `sources.lock`-style pinning is intentional: the base is a commit,
not a branch. If a patch changes, the release version changes.
