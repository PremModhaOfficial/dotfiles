#!/usr/bin/env python3
"""Point every skill that activates itself at the form this harness accepts.

A skill card that says "invoke /caveman" is wrong on pi: pi registers skills as
`/skill:<name>` (docs/skills.md: "a skill is forced with /skill:name"), and a
bare `/caveman` is not a command pi knows. 26 installed cards carried the bare
form - mostly in frontmatter `Trigger:` lines and mode tables - because they are
copied verbatim from upstreams that target a harness where `/name` works.

The cards cannot be hand-edited: 108 of 128 are re-synced from upstream clones
on every run and the edit is reverted. So the rewrite is a post-sync transform,
run by update_skills() in ~/dotfiles/jcode/update-all.sh.

The rule itself lives in skill_slash.py, shared with overlay-lib.sh: an overlay
patch and this rewrite must agree, or the next run sees text it does not
recognise and reports drift.

Exits 1 if any bare activation survives, so a new upstream card that adds one
turns the run red instead of quietly shipping a command that does nothing. Also
exits 1 on a path corruption: skill_slash.selfcheck() runs before anything is
written, and every proposed rewrite is refused if it would put /skill: inside a
path (`<output-dir>/brag.mp4` once became `<output-dir>/skill:brag.mp4`).

Usage: skills-activation.py [--dry-run] [--report FILE]
"""
import argparse
import importlib.util
import os
import sys

spec = importlib.util.spec_from_file_location(
    "skill_slash", os.path.join(os.path.dirname(os.path.abspath(__file__)), "skill_slash.py"))
ss = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ss)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--report", help="TSV of file, line, bare skill reference")
    args = ap.parse_args()

    if not ss.selfcheck():
        print("skills-activation: matcher self-check failed, nothing written", file=sys.stderr)
        return 1

    files = ss.skill_files()
    names = ss.skill_names(files)
    rows, pending, total, corrupt = [], [], 0, 0
    for path in files:
        text = open(path, encoding="utf-8").read()
        hits = ss.scan(text, names)
        if not hits:
            continue
        total += len(hits)
        rows.extend((path, lineno, term) for lineno, term in hits)
        new = ss.normalize(text, names)
        pending.append((path, new))
        for lineno, token in ss.corrupt_paths(new):
            print("ERROR %s:%d would corrupt a path: %s" % (path, lineno, token),
                  file=sys.stderr)
            corrupt += 1

    # Nothing is written when any rewrite would land inside a path: a half-written
    # tree is worse than a red run.
    if not args.dry_run and not corrupt:
        for path, new in pending:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(new)
    rewritten = len(pending)

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            for path, lineno, term in rows:
                fh.write("%s\t%d\t/%s\n" % (path, lineno, term))

    left = [] if args.dry_run else [
        (path, lineno, term) for path in files
        for lineno, term in ss.scan(open(path, encoding="utf-8").read(), names)]
    for path in files:
        for lineno, token in ss.corrupt_paths(open(path, encoding="utf-8").read()):
            print("ERROR %s:%d path corrupted: %s" % (path, lineno, token),
                  file=sys.stderr)
            corrupt += 1
    print("skills-activation: %d skills scanned, %d carried a bare activation, "
          "%d references rewritten to /skill:<name>, %d bare left, "
          "%d path corruptions"
          % (len(files), rewritten, total, len(left), corrupt))
    if args.dry_run:
        print("dry-run: no file written")
        return 0
    for path, lineno, term in left:
        print("ERROR %s:%d still bare: /%s" % (path, lineno, term), file=sys.stderr)
    return 1 if left or corrupt else 0


if __name__ == "__main__":
    sys.exit(main())
