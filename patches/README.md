# Local patch series

`scripts/fetch-source.sh` checks out the pinned base commit and applies every `*.patch` in this
directory in filename order with `git apply`. Keep the numeration (`0001-…`) and one logical change
per patch.

The base tree already contains the Bifrost v6 kbase path. This directory starts empty on purpose:
add a patch only after a device test shows it is needed, and document:

```text
Purpose:
Symptom before the patch:
Tested GPU + kbase:
Tested kernel / Android:
Base commit:
Validation:
```

Patch format is `git format-patch`-compatible. Do not reorder or rewrite a patch that has shipped in
a release; add the next number instead.

## Series

### 0001 — Eden crash and GPU faults on Mali-G72 (v0.02)

```text
Purpose:     size push descriptor storage for multi-slot combined samplers; give the Bifrost
             null texture a 256-entry surface table; panvk.env; fault dump on failed submission
Symptom:     Eden (Zelda: Echoes of Wisdom) SIGSEGV in meta_gfx_end (vkCmdClearAttachments);
             DATA_INVALID_FAULT 0x58 on a compute job whose null texture was sampled past
             its single surface
Tested:      Mali-G72 MP3 r0p1 (0x6221), kbase r38p1, Linux 4.14.364, Android 16
Base commit: d896b0a9c10b92f0f9d53ef3373006b79ed709e8
Validation:  Termux compute + triangle; ARMSX2 Kingdom Hearts; Eden title + menus with no GPU
             fault; Winlator NFS MW (DXVK D3D9) intro + title
```

### 0002 — kbase deferred frees and validation tooling (v0.02)

```text
Purpose:     keep BOs freed during an open JM submission until it completes (kbase holds no
             reference on job memory); PANVK_VALIDATE / PANVK_FORCE_ROBUST /
             PANVK_KBASE_GROW_COMMIT_MB debug switches
Symptom:     GPU translation faults after vkFreeMemory/vkDestroy* of memory still in use
Tested:      as 0001
Base commit: d896b0a9c10b92f0f9d53ef3373006b79ed709e8
Validation:  as 0001; the debug switches are off by default
```
