import re, sys
from pathlib import Path
STOP = set("the a an of to and or for in on at is are be it its this that with as by "
           "not no do does you your we our than then so but if when from into only".split())
def toks(s): return {w for w in re.findall(r"[a-z0-9_./-]+", s.lower()) if len(w) > 2 and w not in STOP}
def canon(p): 
    t=set()
    for l in Path(p).read_text().splitlines():
        if l.startswith("#"): continue
        t|=toks(l)
    return t
B="/tmp/fix4rev5/before/"; A="/tmp/fix4rev5/after/"
cb=canon(B+"AGENTS.md"); ca=canon(A+"AGENTS.md")
PAIRS=[
 ("R1 subagents", "refs/memory-subagents.md", "that is the parallelism control, so put genuinely", True),
 ("R2 never-block","refs/memory-never-block.md", "in its own message", True),
 ("R3 flow", "refs/memory-flow.md", "which is why repo work starts there and chat does not", True),
 ("R4 harness-home pi exception","refs/memory-harness-home.md", "pi is the one authorized case, because it cannot", True),
 ("R5 harness-home forms","refs/memory-harness-home.md", "An inline repeat, only where the harness has no import", False),
]
for tag, rel, needle, expect_gone in PAIRS:
    before=(Path(B)/rel).read_text(); after=(Path(A)/rel).read_text()
    line=[l.strip() for l in before.splitlines() if needle in l]
    s=line[0] if line else ""
    score=len(toks(s)&cb)/len(toks(s)) if toks(s) else 0
    gone = needle not in after
    print(f"{tag:30} union_before={score:.2f} present_before={bool(line)} removed_after={gone}")
