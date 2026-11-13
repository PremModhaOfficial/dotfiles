#!/usr/bin/env python3
"""Duplicate measurement for FIX-4 rev4.

Method (reproducible, no fuzz):
  For each sentence in a reference file, take its content tokens
  (lowercase alnum words, len > 2). The sentence counts as DUPLICATE when
  >= 70% of those tokens also appear in ~/.agents/AGENTS.md (near-verbatim
  paraphrase threshold the rev3 reviewer used). Duplicate percentage is
  weighted by sentence byte length, so a duplicated long paragraph counts
  more than a duplicated bullet.

Usage: python3 fix4-rev4-dup.py [inline-file]
"""
import re
import sys
from pathlib import Path

REF_DIR = Path.home() / ".agents" / "references"
inline = Path(sys.argv[1] if len(sys.argv) > 1 else Path.home() / ".agents" / "AGENTS.md")

STOP = set("the a an of to and or for in on at is are be it its this that with as by "
           "not no do does you your we our than then so but if when from into only".split())


def toks(s):
    return {w for w in re.findall(r"[a-z0-9_./-]+", s.lower()) if len(w) > 2 and w not in STOP}


def sentences(text):
    # split on line breaks and sentence enders; markdown bullets stay whole
    out = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        for part in re.split(r"(?<=[.!?])\s+", line):
            if part.strip():
                out.append(part.strip())
    return out


inline_tokens = toks(inline.read_text())
print(f"inline file: {inline}  tokens={len(inline_tokens)}\n")
print(f"{'reference':32} {'bytes':>6} {'sents':>6} {'dup%':>6}")
rows = []
for ref in sorted(REF_DIR.glob("*.md")):
    text = ref.read_text()
    sents = sentences(text)
    dup_bytes = total = 0
    for s in sents:
        t = toks(s)
        total += len(s)
        if t and len(t & inline_tokens) / len(t) >= 0.70:
            dup_bytes += len(s)
    pct = 100.0 * dup_bytes / total if total else 0.0
    rows.append((ref.name, len(text), len(sents), pct))
    print(f"{ref.name:32} {len(text):6} {len(sents):6} {pct:5.1f}%")
tb = sum(r[1] for r in rows)
db = sum(r[1] * r[3] / 100 for r in rows)
print(f"{'OVERALL (byte-weighted)':32} {tb:6} {'':6} {100*db/tb:5.1f}%")
