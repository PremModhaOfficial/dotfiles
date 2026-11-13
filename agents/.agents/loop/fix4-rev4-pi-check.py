#!/usr/bin/env python3
"""pi stand-alone test: reads ~/.pi/agent/AGENTS.md ONLY and reports topic coverage.

Topic is COVERED only if its own imperative/defining text is in the file, not a
pointer. Each probe is one regex that must match a rule sentence, not a path.
"""
import re
import sys
from pathlib import Path

pi = Path.home() / ".pi" / "agent" / "AGENTS.md"
text = pi.read_text()
lines = [l.strip() for l in text.splitlines()]

TOPICS = {
    "1 clarify": r"Score each prompt 0-10",
    "2 harness-home": r"harness-agnostic home",
    "3 never-block": r"Never block on an agent",
    "4 code-lookup": r"If `graft` exists",
    "5 subagents": r"the native `agent` tool",
    "6 tool-economy": r"Batch independent reads",
    "7 web-access": r"Never retry a denied built-in call",
    "8 order": r"starts with the `flow` skill",
    "9 EGM": r"/skill:egm-\*",
}
extra = {
    "A herdr/hc": r"Never spawn an agent through `hc`",
    "B clarify scale": r"Scale: 0 = one reading",
    "C long definition": r"Long means builds, tests, watchers, servers",
    "D graft is conditional": r"if `graft` exists|If `graft` exists",
    "E no unconditional 'Use `graft`'": None,  # inverted check below
}

ok = 0
for name, pat in TOPICS.items():
    hit = bool(re.search(pat, text))
    ok += hit
    print(f"{'COVERED' if hit else 'MISSING':8} {name:18} probe={pat}")
print(f"\ntopics covered: {ok}/9")
for name, pat in extra.items():
    if pat is None:
        continue
    hit = bool(re.search(pat, text))
    print(f"{'COVERED' if hit else 'MISSING':8} {name:18} probe={pat}")

# graft must never be asserted unconditionally
bad = [l for l in lines if re.search(r"^- (Use|Run) `graft`", l)]
print(f"\nunconditional graft assertions: {len(bad)} {bad or '(none)'}")

# every shared inline rule must be present in pi (pi cannot import it)
shared = (Path.home() / ".agents" / "AGENTS.md").read_text().splitlines()
section, missing = "", []
for l in shared:
    if l.startswith("## "):
        section = l
    if l.startswith("- ") and section != "## References":
        if l.strip() not in lines:
            missing.append(l.strip()[:70])
print(f"shared rules missing from pi: {len(missing)}")
for m in missing:
    print("  MISSING:", m)

sys.exit(0 if ok == 9 and not bad and not missing else 1)
