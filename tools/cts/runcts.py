#!/usr/bin/env python3
"""Run sampled dEQP-VK case lists on the phone, one extension at a time, resuming after crashes.

usage: runcts.py <ext> [<ext> ...]   (or "all")
Results: results/<ext>.csv  (case,status)  and  results/<ext>.log (crash/timeout notes)
"""
import os, re, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
TX = os.environ.get("PANVK_TX", os.path.join(HERE, "tx.sh"))
CHUNK = 200
CHUNK_TIMEOUT = 900  # seconds for one chunk on the device
DEV_DIR = "cts"      # under the Termux home

STATUS_RE = re.compile(r'<Result StatusCode="([A-Za-z]+)"')
CASE_RE = re.compile(r'#beginTestCaseResult (\S+)')


def adb(*args, **kw):
    return subprocess.run(["adb", *args], capture_output=True, text=True, **kw)


def tx(cmd, timeout):
    return subprocess.run([TX, cmd], capture_output=True, text=True, timeout=timeout)


def parse_qpa(text):
    """Return ordered [(case, status)] for every case that finished in the log, plus the case
    that was started but never finished (a crash), or None."""
    done, started = [], None
    for block in text.split("#beginTestCaseResult ")[1:]:
        name = block.split("\n", 1)[0].strip()
        if "#endTestCaseResult" in block or "#terminateTestCaseResult" in block:
            m = STATUS_RE.search(block)
            status = m.group(1) if m else ("Timeout" if "#terminateTestCaseResult" in block else "Unknown")
            if "#terminateTestCaseResult" in block and not m:
                status = block.split("#terminateTestCaseResult", 1)[1].split("\n", 1)[0].strip() or "Terminated"
            done.append((name, status))
        else:
            started = name
    return done, started


def run_chunk(cases, tag):
    lst = f"/data/local/tmp/cts-{tag}.txt"
    with open(f"/tmp/cts-{tag}.txt", "w") as f:
        f.write("\n".join(cases) + "\n")
    adb("push", f"/tmp/cts-{tag}.txt", lst)
    adb("shell", f"su -c 'chmod 644 {lst}'")
    qpa = f"{DEV_DIR}/{tag}.qpa"
    cmd = (f"cd {DEV_DIR} && rm -f {tag}.qpa && LD_LIBRARY_PATH=$HOME/{DEV_DIR}/lib VK_ICD_FILENAMES=$HOME/panvk-test/d896/icd.json "
           f"timeout {CHUNK_TIMEOUT} ./deqp-vk --deqp-caselist-file={lst} --deqp-log-filename={tag}.qpa "
           f"--deqp-log-images=disable --deqp-log-shader-sources=disable --deqp-watchdog=enable "
           f"--deqp-archive-dir=. --deqp-surface-type=pbuffer >/dev/null 2>&1; echo rc=$?")
    try:
        out = tx(cmd, CHUNK_TIMEOUT + 120).stdout
    except subprocess.TimeoutExpired:
        out = "rc=host-timeout"
    text = tx(f"cat {qpa} 2>/dev/null", 300).stdout
    return parse_qpa(text), out.strip().splitlines()[-1] if out.strip() else "rc=?"


def run_ext(ext):
    cases = [c for c in open(os.path.join(HERE, "lists", f"{ext}.txt")).read().split("\n") if c]
    os.makedirs(os.path.join(HERE, "results"), exist_ok=True)
    csv_path = os.path.join(HERE, "results", f"{ext}.csv")
    log = open(os.path.join(HERE, "results", f"{ext}.log"), "a")
    have = {}
    if os.path.exists(csv_path):
        for line in open(csv_path):
            c, s = line.rstrip("\n").rsplit(",", 1)
            have[c] = s
    todo = [c for c in cases if c not in have]
    out = open(csv_path, "a")
    t0 = time.time()
    while todo:
        chunk = todo[:CHUNK]
        (done, started), rc = run_chunk(chunk, "chunk")
        finished = {c for c, _ in done}
        for c, s in done:
            out.write(f"{c},{s}\n")
            have[c] = s
        if started is None and len(finished) < len(chunk):
            # deqp-vk died before starting the next case (or between cases).
            nxt = next((c for c in chunk if c not in finished), None)
            started = nxt
        if started and started not in finished:
            status = "Crash" if "host-timeout" not in rc and "rc=124" not in rc else "Timeout"
            out.write(f"{started},{status}\n")
            have[started] = status
            log.write(f"{time.strftime('%H:%M:%S')} {status} {started} ({rc})\n")
            log.flush()
        out.flush()
        todo = [c for c in todo if c not in have]
        if not done and not started:
            log.write(f"no progress on chunk starting {chunk[0]} ({rc}); skipping it\n")
            for c in chunk:
                out.write(f"{c},NoResult\n")
                have[c] = "NoResult"
            todo = [c for c in todo if c not in have]
    out.close()
    counts = {}
    for c in cases:
        counts[have.get(c, "NoResult")] = counts.get(have.get(c, "NoResult"), 0) + 1
    print(f"{ext}: {len(cases)} cases in {time.time()-t0:.0f}s -> " +
          ", ".join(f"{k} {v}" for k, v in sorted(counts.items(), key=lambda x: -x[1])), flush=True)


if __name__ == "__main__":
    exts = sys.argv[1:]
    if exts == ["all"]:
        exts = sorted(f[:-4] for f in os.listdir(os.path.join(HERE, "lists")))
    for e in exts:
        run_ext(e)
