#!/usr/bin/env python3
"""Fail when a pi-condense purge marker leaks into a tool call argument.

pi-condense replaces pruned tool output with a purge tag (see MARKER_RE). Its
issue #33 counted 1,094 calls sending such a tag as an argument and 77 edits
writing one into a file, so a tag inside an argument is a defect: the model is
echoing the stub back as input. Keep this file tag-free so it never trips itself.

Exit 0: no new leak. Exit 1: leak found. Exit 2: a session file was unreadable.

Usage:
  prune-leak-check.py                 # only lines written after the baseline
  prune-leak-check.py <file>...       # named sessions, baselined too
  prune-leak-check.py --all           # every line of every session
  prune-leak-check.py --rebaseline    # treat everything written so far as history
  prune-leak-check.py --selftest      # prove the checks fire

The baseline records the line count of every existing session on first run, so
sessions that predate the check (including this checker's own source, which
mentions the marker) do not fail it. Only appended lines are judged. The very
first run scans everything anyway: a baseline written before the first scan
would bless any leak that already existed.
"""

import glob
import json
import os
import re
import sys

SESSIONS = os.path.expanduser("~/.pi/agent/sessions")
BASELINE = os.path.expanduser("~/.pi/agent/prune-leak-baseline.json")

# JSON-escaped quotes are tolerated: arguments arrive as a json.dumps string.
MARKER_RE = re.compile(r'<purged-(?:errored-)?args size=\\?"\d+\\?"')


def count_lines(path):
    try:
        with open(path, encoding="utf8", errors="ignore") as handle:
            return sum(1 for _ in handle)
    except OSError:
        return None


def load_baseline(reset=False):
    """Return (counts, created). created means no usable baseline existed yet."""
    if not reset:
        try:
            with open(BASELINE, encoding="utf8") as handle:
                return json.load(handle), False
        except (OSError, json.JSONDecodeError):
            pass
    counts = {}
    for path in glob.glob(os.path.join(SESSIONS, "*", "*.jsonl")):
        lines = count_lines(path)
        if lines is not None:
            counts[path] = lines
    with open(BASELINE, "w", encoding="utf8") as handle:
        json.dump(counts, handle, indent=1)
    print(f"baseline written: {BASELINE} ({len(counts)} sessions)", file=sys.stderr)
    return counts, True


def tool_calls(record):
    """Yield (tool_name, arguments_text) for assistant tool calls in one record."""
    message = record.get("message") or {}
    if message.get("role") != "assistant":
        return
    content = message.get("content")
    if not isinstance(content, list):
        return
    for block in content:
        if isinstance(block, dict) and block.get("type") == "toolCall":
            yield block.get("name") or "?", json.dumps(block.get("arguments") or {})


def scan(path, skip_lines=0):
    leaks = []
    try:
        handle = open(path, encoding="utf8", errors="ignore")
    except OSError as error:
        print(f"cannot read {path}: {error}", file=sys.stderr)
        return None
    with handle:
        for number, line in enumerate(handle, 1):
            if number <= skip_lines or not MARKER_RE.search(line):
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            for name, arguments in tool_calls(record):
                hit = MARKER_RE.search(arguments)
                if hit is None:
                    continue
                at = hit.start()
                leaks.append(
                    (path, number, name, hit.group(0), arguments[max(0, at - 40) : at + 80])
                )
    return leaks


def selftest():
    import tempfile

    def call(name, **arguments):
        return json.dumps(
            {
                "type": "message",
                "message": {
                    "role": "assistant",
                    "content": [{"type": "toolCall", "name": name, "arguments": arguments}],
                },
            }
        )

    # Split so this file never contains a contiguous marker of its own.
    plain = "<purged-" + 'args size="12" ref="abc"/>'
    errored = "<purged-" + 'errored-args size="34"/>'
    with tempfile.TemporaryDirectory() as tmp:
        leaky = os.path.join(tmp, "leaky.jsonl")
        clean = os.path.join(tmp, "clean.jsonl")
        with open(leaky, "w", encoding="utf8") as handle:
            handle.write(call("edit", newText="keep") + "\n")
            handle.write(call("edit", newText="x " + plain + " y") + "\n")
            handle.write(call("bash", command="echo " + errored) + "\n")
        with open(clean, "w", encoding="utf8") as handle:
            handle.write(call("edit", newText="keep") + "\n")
            handle.write(json.dumps({"type": "session"}) + "\n")

        found = scan(leaky)
        assert len(found) == 2, f"selftest: expected 2 leaks, got {len(found)}"
        assert any("errored-args" in leak[3] for leak in found), "selftest: errored variant missed"
        assert not scan(clean), "selftest: false positive"
        assert len(scan(leaky, skip_lines=2)) == 1, "selftest: baseline not honoured"
        assert not scan(leaky, skip_lines=3), "selftest: skip past the end failed"
    print("selftest ok")
    return 0


def main(argv):
    if "--selftest" in argv:
        return selftest()
    if "--rebaseline" in argv:
        load_baseline(reset=True)
        return 0

    named = [a for a in argv[1:] if not a.startswith("-")]
    everything = "--all" in argv
    counts, created = ({}, False) if everything else load_baseline()
    targets = named or glob.glob(os.path.join(SESSIONS, "*", "*.jsonl"))
    total = 0
    unreadable = 0
    for target in targets:
        # Named files are baselined too; the first run and --all judge every line.
        skip = 0 if (everything or created) else counts.get(target, 0)
        found = scan(target, skip_lines=skip)
        if found is None:
            unreadable += 1
            continue
        for path, number, name, marker, snippet in found:
            print(f"{path}:{number}: {name} carries {marker} in an argument: {snippet}")
        total += len(found)
    print(f"scanned {len(targets)} file(s): {total} leak(s), {unreadable} unreadable")
    return 1 if total else (2 if unreadable else 0)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
