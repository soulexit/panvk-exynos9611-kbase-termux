#!/usr/bin/env python3
"""quick.py <caselist-file> [tag]: run the cases (in chunks) and print status counts + non-pass cases."""
import sys, collections
sys.path.insert(0, __import__("os").path.dirname(__file__))
from runcts import run_chunk
cases = list(dict.fromkeys(c for c in open(sys.argv[1]).read().split() if c))  # deqp rejects duplicates
res = {}
while True:
    todo = [c for c in cases if c not in res]
    if not todo: break
    (done, started), rc = run_chunk(todo[:200], "quick")
    for c, s in done: res[c] = s
    if started and started not in res: res[started] = "Crash"
    if not done and not started:
        for c in todo[:200]: res[c] = "NoResult"
print(collections.Counter(res.values()))
for c in cases:
    if res[c] not in ("Pass", "NotSupported"): print(res[c], c)
