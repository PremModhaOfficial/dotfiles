#!/usr/bin/env python3
"""FIX-4 rev5 verification. Runs from any cwd; every path is absolute.

Checks, each printed with PASS/FAIL and counted:
  1. every path written in the three memory files resolves from the current cwd
  2. no bare relative `references/...` path remains
  3. no pi-nonexistent tool name survives in the shared or pi file; in a
     reference it may appear only on a `commandcode:` line. The pi file alone is
     also held to pi's mcp.json: every MCP server it names must be configured
     there, because pi exposes only what that file lists.
  4. the reference index is set-equal to references/*.md (7 and 7)
  5. ~/.agents/AGENTS.md is under the 4096-byte cap
  6. the one duplication threshold (25% at the 0.65 cutoff) holds for every
     live reference file
  7. cmd's @-import target exists and carries the shared rules

Usage: python3 ~/.agents/loop/fix4-rev5-verify.py
Exit 0 only when every check passes.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
A = HOME / ".agents" / "AGENTS.md"
P = HOME / ".pi" / "agent" / "AGENTS.md"
C = HOME / ".commandcode" / "AGENTS.md"
REFS = HOME / ".agents" / "references"
FAKE = ["shell_output", "pubsub_fire", "run_in_background", "monitor_command",
        "shell_command", "agent_output", "native `agent` tool"]
# Registered in ~/.commandcode/mcp.json, absent in pi's: it may not be named in the
# pi inline. Scoped to the pi file because the shared file is read by cmd too.
PI_FAKE = ["donsetch"]
CAP = 4096
DUP_THRESHOLD = 25.0

fails = 0


def check(ok, label, detail=""):
    global fails
    fails += 0 if ok else 1
    print(f"{'PASS' if ok else 'FAIL'}  {label}{('  ' + detail) if detail else ''}")


# 1. every path in the three files resolves, whatever the cwd
print(f"cwd: {Path.cwd()}")
paths = []
for f in (A, P, C):
    for m in re.finditer(r"~/[A-Za-z0-9_./<>-]+|/home/[A-Za-z0-9_./-]+", f.read_text()):
        paths.append((f, m.group(0).rstrip(".,;):")))
for f, raw in paths:
    target = Path(raw.replace("~", str(HOME)))
    check(target.exists(), f"path resolves: {raw}",
          "(in " + str(f).replace(str(HOME) + "/", "~/") + ")")

# 2. no bare relative reference path survives
for f in (A, P, C):
    bad = [l for l in f.read_text().splitlines()
           if re.search(r"(?<!~/\.agents/)references/memory-", l)]
    check(not bad, "no relative references/ path in " + str(f).replace(str(HOME) + "/", "~/"),
          str(bad[:2]) if bad else "")

# 3. pi-nonexistent tool names
for f in (A, P):
    hits = [(n, i + 1) for i, l in enumerate(f.read_text().splitlines())
            for n in FAKE if n in l]
    check(not hits, "no pi-nonexistent tool in " + str(f).replace(str(HOME) + "/", "~/"),
          str(hits[:3]) if hits else "")
for ref in sorted(REFS.glob("*.md")):
    bad = [(n, i + 1) for i, l in enumerate(ref.read_text().splitlines())
           for n in FAKE if n in l and "commandcode" not in l]
    check(not bad, f"fake tool names only on commandcode lines: {ref.name}",
          str(bad[:3]) if bad else "")

# 3b. pi exposes only the MCP servers in its own mcp.json
hits = [(n, i + 1) for i, l in enumerate(P.read_text().splitlines())
        for n in PI_FAKE if n in l]
check(not hits, "no pi-nonexistent tool in " + str(P).replace(str(HOME) + "/", "~/"),
      str(hits[:3]) if hits else "")
servers = set(json.loads((HOME / ".pi" / "agent" / "mcp.json").read_text())["mcpServers"])
named = set(re.findall(r"`([a-z_]+)` MCP", P.read_text()))
check(named <= servers, "pi MCP servers named are configured in mcp.json",
      str(sorted(named)) if named - servers else "")

# 4. index set equality
index = re.findall(r"`~/\.agents/references/(memory-[a-z-]+\.md)`", A.read_text())
files = sorted(p.name for p in REFS.glob("*.md"))
check(len(index) == len(files) == 7, f"index set: {len(index)} entries, {len(files)} files")
check(sorted(index) == files, "index set equals references/*.md",
      str(set(index) ^ set(files)) if sorted(index) != files else "")

# 5. cap
size = len(A.read_bytes())
check(size <= CAP, f"shared file under cap: {size}/{CAP} B")

# 6. one duplication threshold, every live reference file
out = subprocess.run([sys.executable, str(HOME / ".agents/loop/fix4-rev5-dup.py"),
                      str(HOME / ".agents")], capture_output=True, text=True)
if out.returncode != 0:
    check(False, "duplication script ran", out.stderr[-200:])
else:
    for line in out.stdout.splitlines():
        m = re.match(r"(memory-[a-z-]+\.md)\s+\d+\s+\d+\s+([\d.]+)%", line.strip())
        if m:
            pct = float(m.group(2))
            check(pct < DUP_THRESHOLD,
                  f"under {DUP_THRESHOLD:.0f}% at 0.65: {m.group(1)}", f"{pct}%")

# 7. cmd's @-import target
cmd_text = C.read_text()
m = re.search(r"@(~/[A-Za-z0-9_./-]+)", cmd_text)
check(bool(m), "cmd has an @-import line")
if m:
    target = Path(m.group(1).replace("~", str(HOME)))
    check(target.exists(), f"@-import target resolves: {m.group(1)}")
    check(target.resolve() == A.resolve(), "@-import target is the canonical file")
    check("## HARD RULE: clarify until ambiguity <= 3" in target.read_text(),
          "@-import target carries the shared rules")

print(f"\nfailed checks: {fails}")
sys.exit(1 if fails else 0)
