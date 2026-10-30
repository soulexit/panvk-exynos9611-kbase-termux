#!/usr/bin/env python3
"""summarize.py [results dir]: a markdown table of results/<ext>.csv, then the totals over unique
cases (an extension's list overlaps others')."""
import collections, glob, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
BAD = ("Fail", "Crash", "DeviceLost", "Timeout", "ResourceError", "InternalError", "NoResult")


def main():
    rdir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "results")
    unique = {}
    print("| Extension | Cases | Pass | Not supported | Fail | Crash / other |")
    print("|---|---:|---:|---:|---:|---:|")
    for path in sorted(glob.glob(os.path.join(rdir, "*.csv"))):
        counts = collections.Counter()
        for line in open(path):
            case, status = line.rstrip("\n").rsplit(",", 1)
            counts[status] += 1
            unique[case] = status
        total = sum(counts.values())
        if not total:
            continue
        other = sum(v for k, v in counts.items() if k in BAD and k != "Fail")
        print(f"| {os.path.basename(path)[:-4]} | {total} | {counts['Pass']} | "
              f"{counts['NotSupported']} | {counts['Fail']} | {other} |")
    totals = collections.Counter(unique.values())
    print()
    print(f"Unique cases: {len(unique)} — " +
          ", ".join(f"{k} {v}" for k, v in totals.most_common()))


if __name__ == "__main__":
    main()
