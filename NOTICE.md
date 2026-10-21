# Notices and attribution

This repository packages and patches an experimental Vulkan driver. Almost all of the driver code
comes from other projects; the license of each file is kept in its header.

## Mesa / Panfrost / PanVK

The driver is built from Mesa, mostly MIT-licensed. The generated release package contains
`NOTICE.txt` with the notices for every file compiled into the driver, as produced by the base tree.
Mesa's license text is in `LICENSES/` of the Mesa source tree.

- Project: https://mesa3d.org/
- Panfrost/PanVK: https://docs.mesa3d.org/drivers/panfrost.html
- License: MIT and other per-file licenses (see the source headers)

## JimVulkan/mali-panvk

The pinned base tree:

- Project: https://github.com/JimVulkan/mali-panvk
- Commit: `fb3b49d016544c19d83e558462f2d29470e77c28`
- License: MIT for the changes; Mesa per-file licenses for Mesa files

It provides the Bifrost kbase Job Manager backend, the 64-byte `base_jd_atom` layout, the
GROW_ON_GPF heap policy, robustness2/null-descriptor emulation, compute-based geometry shader,
tessellation and transform-feedback paths, and the Android gralloc/AHardwareBuffer integration that
this port builds on.

## Reference projects

These were read for architecture and packaging ideas. No code is copied from unlicensed projects.

- `LukeValen/panvk-mali-g52` — Mali-G52 / Bifrost kbase bring-up notes and packaging.
- `zenithblue-oss/panvk-kbase-android` — kbase profiles, release/test methodology, v6/v7 research.
- `FristOneRR-Admin/FristOneRR-Panvk-Source` — public PanVK/kbase source reference.

## Trademarks

Arm and Mali are trademarks of Arm Limited. Samsung, Galaxy and Exynos are trademarks of Samsung
Electronics. Android is a trademark of Google LLC. All other trademarks belong to their owners.

This project is not affiliated with or endorsed by any of the above.
