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

### 0003 — robust indexed-indirect range, copy-shader guard, validation (v0.03)

```text
Purpose:     clamp firstIndex/indexCount of batched indexed indirect draws to the bound index
             buffer; vk_meta buffer-to-image copy drops fragments with negative coordinates;
             PANVK_VALIDATE covers fragment jobs, varyings, texture surface tables, copy-desc
             sets and dumps the stopped batches' draws and shaders
Symptom:     unbounded index reads; wrapped 32-bit copy offsets read ~4 GiB past a buffer
Tested:      Mali-G72 MP3 r0p1, kbase r38p1, Android 16
Base commit: d896b0a9c10b92f0f9d53ef3373006b79ed709e8
Validation:  Termux compute + triangle; Eden
```

### 0004 — Mali-G72 (v6) compiler fixes, per-atom fault reports (v0.03)

```text
Purpose:     jm-v7 103 (ballot from CLPER_OLD, no WMASK on v6), 095 (old CLPER for
             read_invocation on G71/G72/G31), 102 (32-bit texture offset packing on v6);
             kbase walks a failed atom's job chain and saves the faulting shader
Symptom:     INSTR_INVALID_ENC (0x51) on compute shaders using subgroup ballot/vote; Eden's
             3D world black
Tested:      as 0003
Validation:  Eden / Zelda: Echoes of Wisdom renders in-game with 0 faults
```

### 0005 — AFBC header init, phone-sized heap, BC emulation off in Switch emulators (v0.03)

```text
Purpose:     zero AFBC headers at bind; 40% of RAM as the heap on kbase (PANVK_HEAP_PERCENT);
             no BC emulation by default in Eden/yuzu/Citron/Sudachi/Suyu/Torzu/Strato
Symptom:     MMU faults preloading never-written AFBC images; Eden sized its cache for 4 GiB and
             thrashed swap; BC emulation's extra copies got Eden killed by the LMK
Tested:      as 0003
Validation:  Eden 6-7.5 FPS steady, 0 faults, no LMK kill
```
