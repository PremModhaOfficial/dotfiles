#!/usr/bin/env python3
"""Point every skill that activates itself at the form this harness accepts.

pi registers skills as `/skill:<name>` (docs/skills.md), and a bare `/caveman`
is not a command pi knows. 74 installed cards carried the bare form - mostly in
frontmatter `Trigger:` lines and mode tables - because they are copied verbatim
from upstreams that target a harness where `/name` works, and hand edits are
reverted by the next sync. So the rewrite is a post-sync transform, run by
apply_skill_activation() in ~/dotfiles/jcode/update-all.sh.

The grammar lives in skill_slash.py, shared with overlay-lib.sh. The second
opinion lives in skills-lint.py and imports nothing from the matcher: it is
written from the spec and parses the same lines its own way. This file obeys
three rules, all from the round-3 review:

  1. A tree smaller than the last successful run is an error, not a clean
     tree. "0 skills scanned, 0 corruptions" must never print with exit 0 for
     a tree that used to be whole. The expected count is read from a state file
     this transform writes (STATE below), never a constant in this file: a
     constant floor made a cold machine - and a deliberately emptied tree -
     impossible to sync at all, and blamed the transform for a correct run.
  2. Every file is read and checked before the first byte is written: the pair
     check on each changed line, and the output assertion over the whole
     post-write tree. A mixed tree (a bare hit in one file, a pre-existing
     corruption in another that has no hit) is refused whole, not half-written.
  3. Matcher and lint must agree; if they disagree anywhere, nothing is
     written. Agreement on the real tree is evidence because the two are
     different code, not because they share a regex.
  4. No silent zero. The rewrite touches only four positions (line start, a
     list/heading marker, a Trigger:/Use when:/Use for:/Activate:/Invoke:
     label, a whole-name code span) and the lint gives every slash character in
     the tree exactly one bucket. The run prints two numbers - bare tokens in a
     safe position, and left tokens with a per-reason split - plus the bucket
     sum against the slash total, and asserts the two are equal. A token left
     outside the four positions is counted, not silently skipped: "0 bare in a
     safe position" is a measurement, not an absence.

Usage: skills-activation.py [--dry-run] [--rebaseline] [--report FILE]
Exit: 0 clean, 1 refusal / bare left / corruption.
"""
import argparse
import hashlib
import importlib.util
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))


def _load(name, filename):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, filename))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


ss = _load("skill_slash", "skill_slash.py")
lint = _load("skills_lint", "skills-lint.py")

# What the previous successful run saw. First run: absent, so no floor at all -
# a new machine and a deliberately emptied tree must sync to completion. After
# that: one recorded count plus a content fingerprint, and only a shrink (files
# the state recorded that the tree no longer has) is a defect. Growth and edited
# cards are what an upgrade, a fresh checkout or an overlay looks like, so they
# warn once and re-baseline; a missing or corrupt state file is no state.
STATE = os.path.expanduser("~/.jcode/state/skills-activation.json")
HOME = os.path.expanduser("~")


def _rel(path):
    """State paths are machine-relative, so a moved HOME still compares."""
    real = os.path.realpath(path)
    return os.path.relpath(real, HOME) if real.startswith(HOME + os.sep) else real


def _fingerprint(files):
    """One digest over every skill file's path and bytes, not only its count."""
    h = hashlib.sha256()
    for path in files:
        h.update(_rel(path).encode() + b"\0")
        with open(path, "rb") as fh:
            h.update(hashlib.sha256(fh.read()).digest())
    return h.hexdigest()


def _read_state():
    try:
        with open(STATE, encoding="utf-8") as fh:
            state = json.load(fh)
    except (OSError, ValueError):
        return None
    return state if isinstance(state, dict) and isinstance(state.get("count"), int) else None


def _write_state(files):
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    record = {
        "version": 1,
        "count": len(files),
        "fingerprint": _fingerprint(files),
        "files": sorted(_rel(p) for p in files),
        "when": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }
    tmp = STATE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(record, fh, indent=1, sort_keys=True)
        fh.write("\n")
    # rename, so an interrupted run cannot leave a half-written baseline that
    # the next run would read as a shrink.
    os.replace(tmp, STATE)


def _state_gate(files, rebaseline):
    """Return 0 when the tree may be processed, 1 when it shrank."""
    state = _read_state()
    if state is None:
        return 0
    count, expected = len(files), state["count"]
    if count < expected:
        lost = sorted(set(state.get("files") or []) - {_rel(p) for p in files})
        if not rebaseline:
            print("skills-activation: REFUSED: %d skill files found, %d at the last "
                  "successful run (%s); %d recorded file(s) are gone: %s"
                  % (count, expected, str(state.get("fingerprint"))[:12], len(lost),
                     ", ".join(os.path.basename(os.path.dirname(p)) for p in lost[:10])
                     or "unknown"),
                  file=sys.stderr)
            print("skills-activation: nothing written; if the removal is intended, "
                  "rerun with --rebaseline", file=sys.stderr)
            return 1
        print("skills-activation: WARN: re-baselining a deliberate shrink %d -> %d "
              "skill files (%d removed)" % (expected, count, len(lost)),
              file=sys.stderr)
    elif count > expected:
        print("skills-activation: WARN: tree grew %d -> %d skill files since the last "
              "successful run; re-baselining" % (expected, count), file=sys.stderr)
    return 0


def _ledger(counts, total):
    """The two headline numbers, then a count for every bucket, zeroes shown."""
    parts = ["safe-bare=%d" % counts.get("safe-bare", 0),
             "left=%d" % sum(counts.get(k, 0) for k in lint.LEFT_REASONS)]
    parts += ["%s=%d" % (key, counts.get(key, 0))
              for key in lint.LEFT_REASONS]
    parts += ["rewritten=%d" % counts.get("rewritten", 0),
              "sum=%d/%d" % (sum(counts.values()), total)]
    return ", ".join(parts)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--rebaseline", action="store_true",
                    help="accept a smaller tree than the recorded one")
    ap.add_argument("--report", help="TSV of file, line, bare skill reference")
    args = ap.parse_args()

    if not ss.selfcheck():
        print("skills-activation: matcher self-check failed, nothing written",
              file=sys.stderr)
        return 1
    if not lint.selfcheck():
        print("skills-activation: lint self-check failed, nothing written",
              file=sys.stderr)
        return 1

    files = ss.skill_files()
    if _state_gate(files, args.rebaseline):
        return 1

    names = ss.skill_names(files)
    planned, rows, total, bad = {}, [], 0, 0

    # Read the whole tree, compute every proposed line, and check both ways
    # before anything is written.
    for path in files:
        text = open(path, encoding="utf-8").read()
        hits = ss.scan(text, names)
        new = ss.normalize(text, names) if hits else text
        total += len(hits)
        rows.extend((path, lineno, term) for lineno, term in hits)
        planned[path] = (text, new)

    for path, (text, new) in planned.items():
        if new == text:
            continue
        for lineno, (old_line, new_line) in enumerate(
                zip(text.split("\n"), new.split("\n")), 1):
            if old_line == new_line:
                continue
            for problem in lint.check_change(old_line, new_line, names):
                print("ERROR %s:%d matcher/lint disagree: %s"
                      % (path, lineno, problem), file=sys.stderr)
                bad += 1

    # Every slash token in the tree as it would stand after the write gets a
    # verdict: rewritten, intentionally left (with a reason), or a violation.
    # The output assertion runs on the whole tree, including files with no hit:
    # a pre-existing corruption in an untouched file is still this run's refusal.
    before, after = {}, {}
    before_total = after_total = 0
    for path, (text, new) in planned.items():
        problems, counts, total_slashes = lint.audit(text, names)
        before_total += total_slashes
        for key, value in counts.items():
            before[key] = before.get(key, 0) + value
        problems, counts, total_slashes = lint.audit(new, names)
        after_total += total_slashes
        for key, value in counts.items():
            after[key] = after.get(key, 0) + value
        for problem in problems:
            print("ERROR %s: %s" % (path, problem), file=sys.stderr)
        bad += len(problems)

    if sum(before.values()) != before_total or sum(after.values()) != after_total:
        print("skills-activation: REFUSED: the bucket sum does not equal the "
              "slash total (before %d/%d, after %d/%d)"
              % (sum(before.values()), before_total,
                 sum(after.values()), after_total), file=sys.stderr)
        bad += 1

    print("skills-activation: token ledger before: %s"
          % _ledger(before, before_total))
    print("skills-activation: token ledger after:  %s"
          % _ledger(after, after_total))
    if bad:
        print("skills-activation: REFUSED: %d problem(s) in the whole-tree scan; "
              "nothing written" % bad, file=sys.stderr)
        return 1

    changed_files = sum(1 for text, new in planned.values() if new != text)
    rewritten = total
    if not args.dry_run:
        for path, (text, new) in planned.items():
            if new != text:
                with open(path, "w", encoding="utf-8") as fh:
                    fh.write(new)

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            for path, lineno, term in rows:
                fh.write("%s\t%d\t/%s\n" % (path, lineno, term))

    print("skills-activation: %d skills scanned, %d files changed, "
          "%d bare in a safe position, %d left with a reason, %d problems"
          % (len(files), changed_files, after.get("safe-bare", 0),
             sum(after.get(k, 0) for k in lint.LEFT_REASONS), bad))
    if args.dry_run:
        print("dry-run: no file written, state unchanged")
        return 0
    if bad:
        return 1
    _write_state(files)
    return 0


if __name__ == "__main__":
    sys.exit(main())
