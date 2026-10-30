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

## 0006–0017: Vulkan CTS fixes (unreleased)

Found by running the Khronos CTS per advertised extension on the phone (`tools/cts`,
`docs/CTS-RESULTS.md`). Every patch: Mali-G72 MP3 r0p1 (0x6221), kbase r38p1, Linux 4.14.364,
Android 16, base `d896b0a9c10b92f0f9d53ef3373006b79ed709e8`, validated with VK-GL-CTS 1.4.7.1.

### 0006 — A4R4G4B4 swizzle on v6

```text
Purpose:     the v6 swizzle of the RGBA4 format behind B4G4R4A4_UNORM_PACK16 was inverted
Symptom:     wrong colours sampling B4G4R4A4 (custom border colour, 4444 sampler cases)
Validation:  custom_border_color 5 -> 0 failures; 121 B4G4R4A4/A4R4G4B4 sampler cases pass
```

### 0007 — Storage images in vertex shaders

```text
Purpose:     the vertex shader's image attribute buffer offset was passed in bytes where the
             descriptor copy expects an index
Symptom:     every storage image or image texel buffer in a vertex shader read and wrote the
             wrong descriptor
Validation:  synchronization2.op.single_queue 64 -> 0 failures
```

### 0008 / 0011 — External handles kbase cannot export

```text
Purpose:     on kbase, external memory is dma-buf import only, and fences/semaphores are sync
             fd only: kbase memory has no fd to export and its syncobjs live in the process
Symptom:     getMemoryFdKHR / getFenceFdKHR / getSemaphoreFdKHR failed (OUT_OF_DEVICE_MEMORY,
             UNKNOWN) and the cross-instance tests crashed
Validation:  synchronization2 cross_instance/signal_order: NotSupported instead of 170
             crashes and resource errors; api.external.fence/semaphore 54 -> 0 failures
```

### 0009 — Null descriptors and out-of-bounds texel loads

```text
Purpose:     imageSize/textureSize of a null descriptor return 0 (sizes are minus-one fields);
             null image and texel buffer loads, and robustBufferAccess2 out-of-bounds texel
             buffer loads of formats with alpha, return (0,0,0,0) instead of the hardware's
             out-of-bounds (0,0,0,1)
Validation:  EXT_robustness2 sample 175 -> 8 failures (left: vertex fetch out of bounds, a 3D
             null texture, null dynamic UBOs)
```

### 0010 — Adjacency topologies without a geometry shader

```text
Purpose:     an internal geometry shader drops the adjacent vertices (the tiler has no
             adjacency modes); line width follows the primitive the tiler draws; primitive
             restart is unrolled for list topologies too
Symptom:     UNREACHABLE in translate_prim (undefined behaviour in release builds)
Validation:  82 adjacency / restart failures -> 0 (rasterization, input_assembly,
             index_type_uint8, pipeline libraries, draw)
```

### 0012 — Null index buffer (maintenance6)

```text
Purpose:     a null index buffer reads zeroes from the null descriptors' 4 KiB
Symptom:     indexed draws with a null index buffer read address 0
Validation:  draw.*.indexed_draw *_nulldescriptor_maintenance6: 64 -> 0 failures
```

### 0013 — Zero-initialized memory

```text
Purpose:     clear VK_MEMORY_ALLOCATE_ZERO_INITIALIZE_BIT_EXT allocations on kbase, which
             recycles a process's freed pages without clearing them
Validation:  zero_initialize_device_memory 211 -> 16 failures (BC1, which is emulated)
```

### 0014 — 16-bit varyings in the geometry shader emulation

```text
Purpose:     widen 16-bit outputs to the emulation's 32-bit layout; step inputs by their size
Symptom:     16-bit outputs of geometry and tessellation shaders were dropped
Validation:  16bit_storage input_output 271 -> 0 failures
```

### 0015 — Geometry shaders that emit nothing

```text
Purpose:     a geometry shader with max_vertices 0 gets one (incomplete) tiler index; the fault
             dumper no longer reads a wrapped address for fault address 0
Symptom:     job TERMINATED, then a SIGSEGV in the fault dumper
Validation:  geometry.emit 23/23 pass
```

### 0016 — Layered rendering with geometry shaders

```text
Purpose:     replay a draw per layer only when a stage writes gl_Layer (or for multiview);
             the geometry shader emulation drops other layers' primitives in each pass; an
             empty vertex shader in front of a geometry shader keeps its draw
Symptom:     draws into a layered framebuffer landed on every layer; empty-VS geometry draws
             were skipped
Validation:  geometry.layered 100 -> 8 failures; no regressions over 2,240 renderpass, clear,
             copy/blit, multiview, dynamic rendering and transform feedback cases
```

### 0017 — Multisampled render to single-sampled AHB images; D32_S8 resolves

```text
Purpose:     create the multisampled images of an imported AHardwareBuffer image when it is
             initialized from the AHB, each with memory of its own; no direct depth resolve to a
             view without a depth plane
Symptom:     SIGSEGV (NULL view) in CmdBeginRendering for msrtss AHB attachments and 8x D32_S8
             depth resolves
Validation:  0 crashes over 4,291 msrtss / depth_stencil_resolve / external_memory /
             image_compression_control / device_memory_report cases (27 before)
```
