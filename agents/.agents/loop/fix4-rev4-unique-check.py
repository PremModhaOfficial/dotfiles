#!/usr/bin/env python3
"""Every remaining reference must carry at least one sentence the inline file
does not say (token coverage < 70% against ~/.agents/AGENTS.md)."""
import re
import sys
from pathlib import Path

inline = (Path.home() / ".agents" / "AGENTS.md").read_text()
itoks = {w for w in re.findall(r"[a-z0-9_./-]+", inline.lower()) if len(w) > 2}
STOP = set("the a an of to and or for in on at is are be it its this that with as by "
           "not no do does you your we our than then so but if when from into only".split())


def toks(s):
    return {w for w in re.findall(r"[a-z0-9_./-]+", s.lower()) if len(w) > 2 and w not in STOP}


def sents(text):
    out = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        out += [p.strip() for p in re.split(r"(?<=[.!?])\s+", line) if p.strip()]
    return out


rc = 0
for ref in sorted((Path.home() / ".agents" / "references").glob("*.md")):
    unique = []
    for s in sents(ref.read_text()):
        t = toks(s)
        if t and len(t & itoks) / len(t) < 0.70:
            unique.append(s)
    status = "OK" if unique else "FAIL - fully duplicated"
    rc += 0 if unique else 1
    print(f"{status:26} {ref.name:28} unique sentences={len(unique)}")
    print(f"    e.g. {unique[0][:110] if unique else '(none)'}")
sys.exit(rc)
