# Vulkan CTS results

Khronos VK-GL-CTS `vulkan-cts-1.4.7.1` (`deqp-vk`), run on the Galaxy A51 (Mali-G72 MP3, kbase
r38p1, Android 16) inside Termux, one sampled case list per advertised extension: at most 1500
cases each, 93,255 in all (89,530 unique). How to reproduce: [`tools/cts`](../tools/cts/README.md).

Most cases are **NotSupported**: they need formats, features or limits this GPU does not have
(no exclusive compute queue, no ASTC 3D, no `robustImageAccess2`, …). The numbers that matter
are **Fail** and **Crash**.

## Before and after the CTS fixes (patches 0006–0016)

| Driver | Pass | Fail | Crash | DeviceLost |
|---|---:|---:|---:|---:|
| v0.03 + 0006–0009 (first full run) | 32,556 | 816 | 147 | 3 |
| mali-panvk `4570467` (patches 0001–0016) | **33,218** | **100** | 147 | 3 |
| + patch 0017, deqp-vk for API 34 (the 147 crash cases re-run) | 113 of 147 pass / NotSupported | 7 | **0** | — |

**The 147 crashes, re-run with a deqp-vk built for API 34:** 113 were the CTS itself, not the
driver: an API 31 build aborts in its own `android_hardware_buffer` helper on Android 13 and
newer (`vktExternalMemoryAndroidHardwareBufferUtil.cpp:87`). Built for API 34 they pass or report
NotSupported. The other 27 were driver crashes (rendering to multisampled-render-to-single-sampled
AHB images, 8x D32_S8 depth resolves) and are fixed by patch 0017: **0 crashes** over the
`multisampled_render_to_single_sampled`, `depth_stencil_resolve`, `external_memory`,
`image_compression_control` and `device_memory_report` lists (4,291 cases). 7 AHB cases still
fail (RGBA16F AHB format features, RGB888 AHB import, a memory-report object id).

## Known failures

| Area | Cases | Notes |
|---|---:|---|
| BC1 after `ZERO_INITIALIZED` layout | 16 | BC formats are emulated; the emulated image reads (0,0,0,0) where a zeroed BC1 block decodes to opaque black |
| Robust vertex fetch / index access | ~20 | out-of-bounds vertex attributes of 4-component formats read (0,0,0,1), partially in-bounds elements are read |
| Robustness2 leftovers | 7 | 3D null textures, null dynamic UBOs |
| Transform feedback | ~17 | fuzz tests, queries with GPL, `depth_clip_control` |
| `map_memory_placed` | 9 | placed mappings of kbase memory |
| Multiview + queries | ~10 | including 3 DeviceLost |
| Pipeline library interface matching | 8 | |
| Line rasterization | 3 | one near-vertical line on a pixel boundary in default mode |
| Global priority, memory budget, ycbcr, BC blits | ~10 | |

Core groups outside the extension lists were sampled too: of 800 `geometry`/`tessellation` cases,
106 failed before the fixes and 12 after (tessellation winding/spacing, layered readback with cube
arrays, triangle strips with adjacency into a geometry shader).

## Per extension

| Extension | Cases | Pass | Not supported | Fail | Crash / other |
|---|---:|---:|---:|---:|---:|
| EXT_4444_formats | 1500 | 622 | 878 | 0 | 0 |
| EXT_attachment_feedback_loop_dynamic_state | 1500 | 1279 | 221 | 0 | 0 |
| EXT_attachment_feedback_loop_layout | 1500 | 1279 | 221 | 0 | 0 |
| EXT_border_color_swizzle | 1500 | 618 | 882 | 0 | 0 |
| EXT_buffer_device_address | 1500 | 652 | 848 | 0 | 0 |
| EXT_color_write_enable | 605 | 605 | 0 | 0 | 0 |
| EXT_custom_border_color | 1500 | 594 | 906 | 0 | 0 |
| EXT_depth_bias_control | 1500 | 538 | 962 | 0 | 0 |
| EXT_depth_clamp_control | 2 | 2 | 0 | 0 | 0 |
| EXT_depth_clamp_zero_one | 2 | 2 | 0 | 0 | 0 |
| EXT_depth_clip_control | 89 | 68 | 18 | 3 | 0 |
| EXT_depth_clip_enable | 25 | 25 | 0 | 0 | 0 |
| EXT_device_address_binding_report | 43 | 43 | 0 | 0 | 0 |
| EXT_device_memory_report | 45 | 44 | 0 | 0 | 1 |
| EXT_dynamic_rendering_unused_attachments | 1500 | 892 | 608 | 0 | 0 |
| EXT_extended_dynamic_state | 1500 | 1036 | 464 | 0 | 0 |
| EXT_extended_dynamic_state2 | 121 | 72 | 49 | 0 | 0 |
| EXT_extended_dynamic_state3 | 5 | 5 | 0 | 0 | 0 |
| EXT_external_memory_dma_buf | 1500 | 3 | 1497 | 0 | 0 |
| EXT_global_priority | 402 | 4 | 396 | 2 | 0 |
| EXT_global_priority_query | 402 | 4 | 396 | 2 | 0 |
| EXT_graphics_pipeline_library | 1500 | 850 | 646 | 3 | 1 |
| EXT_host_image_copy | 1500 | 753 | 747 | 0 | 0 |
| EXT_host_query_reset | 1500 | 0 | 1500 | 0 | 0 |
| EXT_image_2d_view_of_3d | 2 | 2 | 0 | 0 | 0 |
| EXT_image_compression_control | 924 | 449 | 431 | 0 | 44 |
| EXT_image_drm_format_modifier | 1500 | 124 | 1376 | 0 | 0 |
| EXT_image_robustness | 1500 | 486 | 1013 | 1 | 0 |
| EXT_image_sliced_view_of_3d | 158 | 158 | 0 | 0 | 0 |
| EXT_image_view_min_lod | 114 | 42 | 72 | 0 | 0 |
| EXT_index_type_uint8 | 331 | 62 | 269 | 0 | 0 |
| EXT_inline_uniform_block | 58 | 32 | 26 | 0 | 0 |
| EXT_legacy_dithering | 2 | 2 | 0 | 0 | 0 |
| EXT_line_rasterization | 801 | 209 | 589 | 3 | 0 |
| EXT_load_store_op_none | 273 | 213 | 60 | 0 | 0 |
| EXT_map_memory_placed | 15 | 6 | 0 | 9 | 0 |
| EXT_memory_budget | 2 | 1 | 0 | 1 | 0 |
| EXT_multisampled_render_to_single_sampled | 1500 | 443 | 1013 | 0 | 44 |
| EXT_non_seamless_cube_map | 1500 | 546 | 954 | 0 | 0 |
| EXT_pipeline_creation_cache_control | 20 | 20 | 0 | 0 | 0 |
| EXT_pipeline_creation_feedback | 22 | 22 | 0 | 0 | 0 |
| EXT_pipeline_robustness | 1500 | 493 | 990 | 17 | 0 |
| EXT_primitive_topology_list_restart | 2 | 2 | 0 | 0 | 0 |
| EXT_private_data | 132 | 42 | 90 | 0 | 0 |
| EXT_provoking_vertex | 88 | 29 | 59 | 0 | 0 |
| EXT_robustness2 | 1500 | 454 | 1038 | 8 | 0 |
| EXT_scalar_block_layout | 1500 | 1242 | 256 | 2 | 0 |
| EXT_separate_stencil_usage | 1308 | 478 | 830 | 0 | 0 |
| EXT_shader_atomic_float | 281 | 18 | 263 | 0 | 0 |
| EXT_shader_demote_to_helper_invocation | 60 | 52 | 8 | 0 | 0 |
| EXT_shader_module_identifier | 798 | 534 | 264 | 0 | 0 |
| EXT_shader_replicated_composites | 23 | 20 | 3 | 0 | 0 |
| EXT_shader_stencil_export | 84 | 3 | 81 | 0 | 0 |
| EXT_shader_subgroup_ballot | 1500 | 101 | 1399 | 0 | 0 |
| EXT_shader_subgroup_vote | 780 | 180 | 600 | 0 | 0 |
| EXT_shader_uniform_buffer_unsized_array | 1500 | 1350 | 150 | 0 | 0 |
| EXT_subgroup_size_control | 60 | 26 | 34 | 0 | 0 |
| EXT_texel_buffer_alignment | 2 | 2 | 0 | 0 | 0 |
| EXT_texture_compression_astc_hdr | 1500 | 383 | 1117 | 0 | 0 |
| EXT_transform_feedback | 1500 | 9 | 1477 | 14 | 0 |
| EXT_vertex_attribute_divisor | 1500 | 970 | 530 | 0 | 0 |
| EXT_vertex_input_dynamic_state | 10 | 10 | 0 | 0 | 0 |
| EXT_zero_initialize_device_memory | 498 | 458 | 24 | 16 | 0 |
| KHR_16bit_storage | 1500 | 1154 | 346 | 0 | 0 |
| KHR_8bit_storage | 439 | 439 | 0 | 0 | 0 |
| KHR_bind_memory2 | 1500 | 44 | 1456 | 0 | 0 |
| KHR_buffer_device_address | 1500 | 652 | 848 | 0 | 0 |
| KHR_copy_commands2 | 1500 | 552 | 944 | 4 | 0 |
| KHR_create_renderpass2 | 1500 | 293 | 1206 | 0 | 1 |
| KHR_dedicated_allocation | 1500 | 653 | 847 | 0 | 0 |
| KHR_depth_clamp_zero_one | 2 | 2 | 0 | 0 | 0 |
| KHR_depth_stencil_resolve | 1500 | 429 | 1063 | 0 | 8 |
| KHR_descriptor_update_template | 3 | 3 | 0 | 0 | 0 |
| KHR_device_group | 1500 | 7 | 1493 | 0 | 0 |
| KHR_dynamic_rendering | 1500 | 306 | 1194 | 0 | 0 |
| KHR_dynamic_rendering_local_read | 121 | 118 | 3 | 0 | 0 |
| KHR_external_fence | 91 | 16 | 75 | 0 | 0 |
| KHR_external_fence_fd | 45 | 14 | 31 | 0 | 0 |
| KHR_external_memory | 350 | 48 | 256 | 0 | 46 |
| KHR_external_memory_fd | 96 | 12 | 84 | 0 | 0 |
| KHR_external_semaphore | 108 | 19 | 89 | 0 | 0 |
| KHR_external_semaphore_fd | 44 | 15 | 29 | 0 | 0 |
| KHR_format_feature_flags2 | 184 | 184 | 0 | 0 | 0 |
| KHR_global_priority | 402 | 4 | 396 | 2 | 0 |
| KHR_imageless_framebuffer | 26 | 8 | 18 | 0 | 0 |
| KHR_index_type_uint8 | 331 | 62 | 269 | 0 | 0 |
| KHR_line_rasterization | 801 | 209 | 589 | 3 | 0 |
| KHR_load_store_op_none | 273 | 213 | 60 | 0 | 0 |
| KHR_maintenance1 | 1500 | 1 | 1499 | 0 | 0 |
| KHR_maintenance10 | 2 | 2 | 0 | 0 | 0 |
| KHR_maintenance11 | 3 | 3 | 0 | 0 | 0 |
| KHR_maintenance2 | 2 | 2 | 0 | 0 | 0 |
| KHR_maintenance3 | 178 | 2 | 176 | 0 | 0 |
| KHR_maintenance4 | 3 | 3 | 0 | 0 | 0 |
| KHR_maintenance5 | 107 | 89 | 18 | 0 | 0 |
| KHR_maintenance6 | 827 | 187 | 640 | 0 | 0 |
| KHR_maintenance7 | 6 | 4 | 2 | 0 | 0 |
| KHR_maintenance8 | 30 | 30 | 0 | 0 | 0 |
| KHR_maintenance9 | 1500 | 147 | 1353 | 0 | 0 |
| KHR_map_memory2 | 1500 | 1500 | 0 | 0 | 0 |
| KHR_multiview | 1500 | 50 | 1440 | 4 | 6 |
| KHR_pipeline_binary | 1500 | 211 | 1289 | 0 | 0 |
| KHR_pipeline_executable_properties | 19 | 19 | 0 | 0 | 0 |
| KHR_pipeline_library | 1500 | 825 | 670 | 5 | 0 |
| KHR_push_descriptor | 80 | 80 | 0 | 0 | 0 |
| KHR_robustness2 | 1500 | 454 | 1038 | 8 | 0 |
| KHR_sampler_mirror_clamp_to_edge | 1500 | 603 | 897 | 0 | 0 |
| KHR_sampler_ycbcr_conversion | 1500 | 382 | 1117 | 1 | 0 |
| KHR_separate_depth_stencil_layouts | 1500 | 806 | 694 | 0 | 0 |
| KHR_shader_clock | 14 | 14 | 0 | 0 | 0 |
| KHR_shader_draw_parameters | 1500 | 450 | 1042 | 8 | 0 |
| KHR_shader_expect_assume | 143 | 143 | 0 | 0 | 0 |
| KHR_shader_float16_int8 | 1500 | 170 | 1329 | 1 | 0 |
| KHR_shader_float_controls | 1500 | 451 | 1049 | 0 | 0 |
| KHR_shader_float_controls2 | 1500 | 562 | 938 | 0 | 0 |
| KHR_shader_integer_dot_product | 2 | 2 | 0 | 0 | 0 |
| KHR_shader_subgroup_extended_types | 1500 | 119 | 1381 | 0 | 0 |
| KHR_shader_subgroup_rotate | 1500 | 291 | 1209 | 0 | 0 |
| KHR_shader_terminate_invocation | 24 | 19 | 5 | 0 | 0 |
| KHR_spirv_1_4 | 198 | 182 | 16 | 0 | 0 |
| KHR_synchronization2 | 1500 | 394 | 1106 | 0 | 0 |
| KHR_timeline_semaphore | 1500 | 286 | 1214 | 0 | 0 |
| KHR_uniform_buffer_standard_layout | 1500 | 1123 | 377 | 0 | 0 |
| KHR_variable_pointers | 1500 | 323 | 1177 | 0 | 0 |
| KHR_vertex_attribute_divisor | 1500 | 970 | 530 | 0 | 0 |
| KHR_vulkan_memory_model | 1500 | 259 | 1241 | 0 | 0 |
| KHR_workgroup_memory_explicit_layout | 1500 | 922 | 578 | 0 | 0 |
| KHR_zero_initialize_workgroup_memory | 648 | 612 | 36 | 0 | 0 |

Unique cases: 89530 — NotSupported 56062, Pass 33218, Crash 147, Fail 100, DeviceLost 3
