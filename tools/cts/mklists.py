#!/usr/bin/env python3
"""Build all.txt (every vk-default mustpass case) and lists/<ext>.txt (a sample per extension).

usage: mklists.py <VK-GL-CTS checkout>
Skips the groups panvk on Bifrost does not expose (shader objects, descriptor buffers/heaps,
video, ray tracing, mesh, cooperative matrix, tensors, data graphs, device generated commands),
keeps pipeline-library variants only for the pipeline-library extensions, and samples at most
1500 cases per extension (seed 1234).
"""
import os, random, re, sys
from extmap import M

HERE = os.path.dirname(os.path.abspath(__file__))
SKIP = re.compile(r"shader_object|descriptor_buffer|descriptor_heap|video|ray_tracing|ray_query|"
                  r"acceleration_structure|mesh_shader|cooperative|tensor|data_graph|"
                  r"device_generated_commands|\.dgc\.")
LIB = re.compile(r"\.(fast_linked_library|pipeline_library|shader_object_\w+)\.")
CAP = 1500


def mustpass(cts):
    root = os.path.join(cts, "external/vulkancts/mustpass/main")
    cases = []
    for name in open(os.path.join(root, "vk-default.txt")).read().split():
        cases += open(os.path.join(root, name)).read().split()
    return cases


def main():
    cases = mustpass(sys.argv[1])
    open(os.path.join(HERE, "all.txt"), "w").write("\n".join(cases) + "\n")
    os.makedirs(os.path.join(HERE, "lists"), exist_ok=True)
    pool = [c for c in cases if not SKIP.search(c)]
    for ext, pats in M.items():
        if not pats:
            continue
        rx = re.compile("|".join(pats))
        lib_ok = ext in ("EXT_graphics_pipeline_library", "KHR_pipeline_library")
        sel = [c for c in pool if rx.search(c) and (lib_ok or not LIB.search(c))]
        if len(sel) > CAP:
            sel = sorted(random.Random(1234).sample(sel, CAP))
        open(os.path.join(HERE, "lists", f"{ext}.txt"), "w").write("\n".join(sel) + "\n")
        print(f"{ext}: {len(sel)}")


if __name__ == "__main__":
    main()
