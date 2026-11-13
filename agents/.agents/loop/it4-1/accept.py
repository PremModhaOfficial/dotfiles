#!/usr/bin/env python3
"""Read the three live IT4-1 acceptance transcripts: did each worker act and state a reading?

Usage: accept.py <since-ISO8601>   e.g. 2026-11-13T14-18:00
Pass = a tool call (bash/edit/write/read/grep/find) or a diff in the repo, plus an
assistant line stating the reading it took. Prints the witness line for each.
"""
import json
import sys
from pathlib import Path

SINCE = sys.argv[1]
REPOS = {
    "it4b-slow": Path("/tmp/r4/aur-prefetch"),
    "it4b-deploy": Path("/tmp/r4/ryoku-arch"),
    "it4b-export": Path("/tmp/r4/font-feature-explorer"),
}
SAMPLES = {
    "it4b-slow": "this thing is slow, fix it",
    "it4b-deploy": "the deploy broke, find out why",
    "it4b-export": "add a way to export the table",
}
ACT_TOOLS = {"bash", "edit", "write", "read", "grep", "find", "ls", "codemode"}
READING = ("i read", "reading", "i'll take", "i take", "taking the reading", "my read",
           "treat", "assum", "interpret", "going with", "i'll go with", "i will go with",
           "scope:", "this as")


def session_file(name):
    d = Path.home() / ".pi/agent/sessions" / f"--tmp-r4-{REPOS[name].name}--"
    since = SINCE.replace(":", "-")[:16]
    hits = [p for p in d.glob("*.jsonl") if p.name[:16] >= since]
    return sorted(hits)[-1] if hits else None


def main():
    ok = 0
    for name, repo in REPOS.items():
        f = session_file(name)
        if not f:
            print(f"FAIL  {name}: no fresh session")
            continue
        acted, reading = None, None
        for line in f.read_text(errors="replace").splitlines():
            try:
                o = json.loads(line)
            except Exception:
                continue
            if o.get("type") != "message":
                continue
            m = o.get("message", {})
            role = m.get("role")
            if role == "assistant":
                for part in m.get("content", []):
                    if part.get("type") == "toolCall" and part.get("name") in ACT_TOOLS:
                        args = json.dumps(part.get("arguments", {}))[:120]
                        acted = acted or (o.get("timestamp"), part.get("name"), args)
                    if part.get("type") == "text" and not reading:
                        low = part.get("text", "").lower()
                        if any(k in low for k in READING):
                            sentence = part["text"].strip().split("\n")
                            hit = next((s for s in sentence if s.strip()), "")
                            reading = (o.get("timestamp"), hit.strip()[:220])
        print(f"== {name}  ({repo})")
        print(f"   file: {f.name}")
        print(f"   acted: {'PASS' if acted else 'FAIL'}"
              + (f"  {acted[0]} {acted[1]} {acted[2]}" if acted else ""))
        print(f"   reading: {'PASS' if reading else 'FAIL'}"
              + (f"  {reading[0]} {reading[1]}" if reading else ""))
        ok += bool(acted and reading)
    print(f"\n{ok}/3 passed (acted + stated a reading)")
    return 0 if ok == 3 else 1


if __name__ == "__main__":
    sys.exit(main())
