#!/usr/bin/env python3
"""IT4-3: the reading is one visible line, and the fixed shape is stated once per file.

Fails if the shape is missing, if it is not tied to "before any tool call", if the shared
file outgrows 4096 B, or if the rule is restated (a second copy) beyond the pointers.
"""
import re
import sys
from pathlib import Path

HOME = Path.home()
SPEC = HOME / ".agents/references/memory-clarify.md"
SHARED = HOME / ".agents/AGENTS.md"
MACHINE = HOME / "AGENTS.md"
FLOW = HOME / ".agents/skills/flow/SKILL.md"
SHAPE = "`Reading: X, because Y`"

fails = []


def want(ok, msg):
    print(("OK: " if ok else "FAIL: ") + msg)
    if not ok:
        fails.append(msg)


spec = SPEC.read_text()
shared = SHARED.read_text()
machine = MACHINE.read_text()
flow = FLOW.read_text()

want("Reading: <" in spec and "because <" in spec, "spec carries the reading shape")
want("Visible" in spec or "visible" in spec, "spec says the line is visible output")
want("never reasoning" in spec.lower() or "not reasoning" in spec.lower(),
     "spec excludes reasoning")
want("first visible line" in spec and "any tool call" in spec,
     "spec puts the line before any tool call")
want(SHAPE in shared, "shared block carries the shape")
want("tool call" in shared, "shared block keeps the before-any-tool-call trigger")
want(len(SHARED.read_bytes()) <= 4096, f"shared AGENTS.md under 4096 B ({len(SHARED.read_bytes())})")
for p, t in ((MACHINE, machine), (FLOW, flow)):
    want(SHAPE in t and "memory-clarify.md" in t, f"{p.name} points at the spec with the shape")

# One copy: the shape appears once per file, and the spec is the only place with the long form.
want(spec.count("Reading: <") == 1, "spec states the rule once")
for p, t in ((SHARED, shared), (MACHINE, machine), (FLOW, flow)):
    want(t.count(SHAPE) == 1, f"{p.name} states the shape once")
want(not re.search(r"^##+ .*reading.*visible.*$", machine, re.I | re.M),
     "no second copy of the section in the machine pointer")

print(f"\n{'FAIL ' + str(len(fails)) if fails else 'OK:'} "
      f"{'checks failed' if fails else 'one visible reading line, no duplicate copy'}")
sys.exit(1 if fails else 0)
