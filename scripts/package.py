#!/usr/bin/env python3
"""Build the Termux release zip for the Exynos 9611 PanVK driver.

usage: package.py <libvulkan_panfrost.so> <output-dir>

The zip is self-contained: the installer only needs Termux, unzip and the files in the archive.
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def git(*args):
    try:
        return subprocess.run(
            ["git", "-C", ROOT, *args], check=True, capture_output=True, text=True
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return ""


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    so, out_dir = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
    if not os.path.isfile(so):
        sys.exit("error: %s not found" % so)

    version = read(os.path.join(ROOT, "VERSION")).strip()
    name = "panvk-exynos9611-termux-v%s" % version
    stage = tempfile.mkdtemp(prefix="panvk-pkg-")
    try:
        shutil.copy2(so, os.path.join(stage, "libvulkan_panfrost.so"))
        shutil.copy2(os.path.join(ROOT, "scripts", "install-termux.sh"),
                     os.path.join(stage, "install-termux.sh"))
        shutil.copy2(os.path.join(ROOT, "NOTICE.md"), os.path.join(stage, "NOTICE.txt"))
        shutil.copy2(os.path.join(ROOT, "LICENSE"), os.path.join(stage, "LICENSE"))

        icd = read(os.path.join(ROOT, "icd", "panvk-exynos9611.json.in"))
        with open(os.path.join(stage, "panvk-exynos9611.json"), "w", encoding="utf-8") as f:
            f.write(icd)

        source_info = ""
        info_path = os.path.join(ROOT, "build", "source-info.txt")
        if os.path.isfile(info_path):
            source_info = read(info_path)

        build_info = [
            "package=%s" % name,
            "version=%s" % version,
            "built_utc=%s" % subprocess.run(
                ["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"], capture_output=True, text=True
            ).stdout.strip(),
            "git_commit=%s" % (git("rev-parse", "HEAD") or "unknown"),
            "git_dirty=%s" % ("yes" if git("status", "--porcelain") else "no"),
            "driver_sha256=%s" % sha256(so),
            "driver_bytes=%d" % os.path.getsize(so),
        ]
        if source_info:
            build_info.append("")
            build_info.append("[source]")
            build_info.append(source_info.rstrip())
        with open(os.path.join(stage, "BUILD-INFO.txt"), "w", encoding="utf-8") as f:
            f.write("\n".join(build_info) + "\n")

        with open(os.path.join(stage, "README.txt"), "w", encoding="utf-8") as f:
            f.write(
                "PanVK for Exynos 9611 / Mali-G72 MP3 (Termux)\n"
                "=============================================\n\n"
                "Install inside Termux:\n"
                "  bash install-termux.sh\n\n"
                "Test:\n"
                "  panvk-run vulkaninfo --summary\n\n"
                "Uninstall:\n"
                "  bash install-termux.sh --uninstall\n\n"
                "This is an experimental debug build. See the repository for details.\n"
            )

        sums = []
        for entry in sorted(os.listdir(stage)):
            if entry == "SHA256SUMS":
                continue
            sums.append("%s  %s" % (sha256(os.path.join(stage, entry)), entry))
        with open(os.path.join(stage, "SHA256SUMS"), "w", encoding="utf-8") as f:
            f.write("\n".join(sums) + "\n")

        os.makedirs(out_dir, exist_ok=True)
        zip_path = os.path.join(out_dir, name + ".zip")
        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
            for entry in sorted(os.listdir(stage)):
                z.write(os.path.join(stage, entry), entry)
        print("packaged %s (%.1f MiB)" % (zip_path, os.path.getsize(zip_path) / (1 << 20)))
    finally:
        shutil.rmtree(stage, ignore_errors=True)


if __name__ == "__main__":
    main()
