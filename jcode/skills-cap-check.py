#!/usr/bin/env python3
"""Fail when a skill description exceeds the catalogue cap.

Independent of the transform on purpose: it reads the cap from
skills-cap.py --print-cap, re-measures the descriptions pi would load, and exits
non-zero on any over-cap description or any routing term the transform recorded
but the installed description no longer contains. update-all.sh runs it right
after the transform, so a sync that reverts a shortened description (an upstream
pull, a wipe by hand) fails the update instead of quietly costing prompt bytes.

Usage:
  skills-cap-check.py            # check the installed skill trees
  skills-cap-check.py --root DIR # check a copy (repeatable)
"""

import argparse
import glob
import os
import re
import subprocess
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
ROOTS = (
    os.path.expanduser("~/.agents/skills"),
    os.path.expanduser("~/.pi/agent/skills"),
) + tuple(sorted(
    glob.glob(os.path.expanduser("~/.pi/agent/npm/node_modules/*/skills"))
    + glob.glob(os.path.expanduser("~/.pi/agent/git/github.com/*/*/skills"))
))
LEDGER = os.path.expanduser("~/.jcode/state/skill-catalogue-terms.tsv")


def escape(s):
    """Same escaping pi applies before the description reaches the prompt."""
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
             .replace('"', "&quot;").replace("'", "&apos;"))


def description(path):
    m = re.match(r"^---\n(.*?)\n---\n", open(path, encoding="utf-8").read(), re.S)
    if not m:
        return None
    desc = (yaml.safe_load(m.group(1)) or {}).get("description")
    return " ".join(desc.split()) if isinstance(desc, str) else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", action="append")
    ap.add_argument("--ledger", default=LEDGER)
    args = ap.parse_args()
    roots = args.root or ROOTS
    cap = int(subprocess.run([sys.executable, os.path.join(HERE, "skills-cap.py"), "--print-cap"],
                             capture_output=True, text=True, check=True).stdout)

    checked, over, biggest = 0, [], (0, "")
    seen = set()
    for root in roots:
        for path in sorted(glob.glob(os.path.join(root, "*", "SKILL.md"))):
            real = os.path.realpath(path)
            if real in seen:  # ~/.pi/agent/skills is symlinks into ~/.agents/skills
                continue
            seen.add(real)
            desc = description(path)
            if desc is None:
                # pi skips a skill whose description is missing or empty, so the
                # entry silently disappears from the catalogue: that is a failure,
                # not a file to skip.
                over.append((0, os.path.basename(os.path.dirname(path)), path))
                continue
            checked += 1
            size = len(escape(desc).encode())
            name = os.path.basename(os.path.dirname(path))
            biggest = max(biggest, (size, name))
            if size > cap:
                over.append((size, name, path))

    lost = []
    if args.ledger and os.path.exists(args.ledger):
        wanted = {}
        for line in open(args.ledger, encoding="utf-8"):
            name, _, term = line.rstrip("\n").partition("\t")
            wanted.setdefault(name, []).append(term)
        on_disk = {}
        for root in roots:
            for path in glob.glob(os.path.join(root, "*", "SKILL.md")):
                on_disk.setdefault(
                    os.path.basename(os.path.dirname(path)), []).append(path)
        for name, terms in sorted(wanted.items()):
            if name not in on_disk:
                continue
            # A skill can be installed twice (an upstream copy under
            # ~/.agents/skills and a host copy under ~/.pi/agent/skills) with
            # different wording, and the ledger records the terms of both. The
            # term is lost only when neither installed copy carries it.
            descs = ((description(path) or "").lower() for path in on_disk[name])
            haystack = "\n".join(descs)
            for term in terms:
                if term.lower() not in haystack:
                    lost.append((name, term))

    print(f"skills-cap-check: {checked} descriptions, cap {cap} B "
          f"(escaped, as loaded), largest {biggest[1]} at {biggest[0]} B")
    for size, name, path in over:
        if size == 0:
            print(f"FAIL no description: {name} ({path})", file=sys.stderr)
        else:
            print(f"FAIL over cap: {name} {size} B > {cap} B ({path})", file=sys.stderr)
    for name, term in lost:
        print(f"FAIL routing term gone: {name}: {term!r}", file=sys.stderr)
    if over or lost:
        print(f"skills-cap-check: {len(over)} over cap, {len(lost)} routing terms lost",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
