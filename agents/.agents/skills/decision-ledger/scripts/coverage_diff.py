#!/usr/bin/env python3
"""Coverage gate helper: find options in source texts that the ledger never mentions.

Usage: coverage_diff.py --ledger ledger.md --source man.txt [--source defaults.conf ...]
Sources are plain text (man page, --help output, default config, DeepWiki answer).
Prints, per source, option-like tokens absent from the ledger, and tokens found
in only some sources. Exit 1 if any gap. Heuristic. Measured on real data: sshd_config man page, top-level directive recall
145/145 over 5 seeded-miss runs; curl --help all, flag recall 100% (251 flags);
about 4 recurring false positives per run (prose words). Lowercase sub-values and
bare words without -- or = are not detected. A gap is a lead to check; a clean
run is not proof of completeness.
"""
import argparse, re, sys

PATTERNS = [
    r"(?<![\w-])--([A-Za-z0-9][\w-]+)",              # --long-flag
    r"\b([A-Za-z][A-Za-z0-9_.-]{2,})=",               # key=value options (PAM, env, ini)
    r"^#?([A-Z][a-z0-9]+[A-Za-z0-9]*)[ \t]+\S",      # column-0 CamelCase config directive (sshd_config style)
    r"^#?([a-z][a-z0-9_.-]{3,})[ \t]*=",              # column-0 lowercase key = value (ini/conf)
    r"^[ \t]{1,8}([A-Z][A-Za-z0-9]{3,})[ \t]*$",     # man-page style: keyword alone on an indented line
]

def norm(t):
    return re.sub(r"[-_.]", "", t.lower())

def tokens(text):
    found = set()
    for pat in PATTERNS:
        for m in re.finditer(pat, text, re.M):
            found.add(norm(m.group(1)))
    return found

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ledger", required=True)
    ap.add_argument("--source", action="append", required=True)
    a = ap.parse_args()
    ledger = {norm(w) for w in re.findall(r"[A-Za-z0-9_.-]+", open(a.ledger, errors="ignore").read())}
    per = {s: tokens(open(s, errors="ignore").read()) for s in a.source}
    gaps = False
    for s, toks in per.items():
        missing = sorted(t for t in toks if t not in ledger)
        print(f"[{s}] options found: {len(toks)}, not in ledger: {len(missing)}")
        for t in missing:
            print(f"  GAP  {t}")
        gaps |= bool(missing)
    if len(per) > 1:
        allt = set().union(*per.values())
        for t in sorted(allt):
            where = [s for s, toks in per.items() if t in toks]
            if len(where) < len(per):
                print(f"  ONLY-IN {', '.join(where)}: {t}")
    if len(per) == 1:
        print("SINGLE-SOURCE: coverage cannot be called COMPLETE")
    sys.exit(1 if gaps else 0)

if __name__ == "__main__":
    main()
