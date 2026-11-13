#!/usr/bin/env python3
"""Generate ~/.pi/agent/AGENTS.md from ~/.agents/AGENTS.md plus pi's fragment.

pi has no `@` import for context files, so the shared rules have to be inlined; kept
by hand they drift (IT2-4: 42 diff lines against the shared file, and two of the
rewrites changed the instruction rather than adapting it). The fragment carries only
the six pi tool-form imperatives and the one override line: every other line in the
generated file comes from the shared file verbatim.

exit 0 = written or already current, 1 = the fragment no longer matches the shared file.
"""
import argparse
import os
import sys
import tempfile
from pathlib import Path

HOME = Path.home()


def parse_fragment(path):
    """-> (header lines, [{verb, anchor, lines}]). Lines before the first directive
    are the fragment's own comments and are ignored."""
    header, ops, cur = [], [], None
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if s == "@header":
            cur = {"verb": "header", "anchor": None, "lines": header}
            continue
        if s.startswith(("@replace ", "@after ")):
            verb, anchor = s[1:].split(" ", 1)
            cur = {"verb": verb, "anchor": anchor.strip(), "lines": []}
            ops.append(cur)
            continue
        if cur is None:
            continue
        cur["lines"].append(line)
    for block in [header] + [op["lines"] for op in ops]:
        while block and not block[-1].strip():
            block.pop()
    if not header:
        sys.exit("ERROR: fragment has no @header block")
    return header, ops


def render(shared_text, header, ops):
    lines = shared_text.splitlines()
    if not lines:
        sys.exit("ERROR: the shared rules file is empty")
    # The header replaces the shared title: two H1s would be its own ambiguity, and the
    # header is where this file says which file is canonical and why it is inlined.
    body = lines[1:]
    while body and not body[0].strip():
        body.pop(0)
    by_anchor = {op["anchor"]: op for op in ops if op["anchor"]}
    seen = {a: 0 for a in by_anchor}
    out = []
    for line in body:
        hits = [a for a in by_anchor if a in line]
        if len(hits) > 1:
            sys.exit(f"ERROR: fragments anchors {hits} both match: {line}")
        if not hits:
            out.append(line)
            continue
        op = by_anchor[hits[0]]
        if op["verb"] == "after":
            out.append(line)  # keep the shared line, insert below it
        out.extend(op["lines"])
        seen[hits[0]] += 1
    missing = [a for a, n in seen.items() if n == 0]
    if missing:
        sys.exit("ERROR: fragment anchor(s) matched no shared line, so the shared file "
                 "changed and this fragment is stale: " + "; ".join(missing))
    twice = [a for a, n in seen.items() if n > 1]
    if twice:
        sys.exit("ERROR: fragment anchor(s) match more than one shared line, so one rule "
                 "would be replaced twice: " + "; ".join(twice))
    text = "\n".join(header) + "\n\n" + "\n".join(out).rstrip("\n") + "\n"
    # Rule bullets must balance: a @replace is one bullet for one, an @after adds one.
    # A mismatch means a shared rule was dropped or duplicated on the way out.
    want = (sum(1 for l in body if l.startswith("- "))
            + sum(len(op["lines"]) for op in ops if op["verb"] == "after"))
    got = sum(1 for l in text.splitlines() if l.startswith("- "))
    if want != got:
        sys.exit(f"ERROR: rule bullets do not balance: expected {want}, wrote {got}")
    return text


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--shared", type=Path, default=HOME / ".agents/AGENTS.md")
    ap.add_argument("--fragment", type=Path,
                    default=Path(__file__).with_name("pi-agents.fragment.md"))
    ap.add_argument("--out", type=Path, default=HOME / ".pi/agent/AGENTS.md")
    args = ap.parse_args()
    for p in (args.shared, args.fragment):
        if not p.is_file():
            sys.exit(f"ERROR: missing {p}")
    header, ops = parse_fragment(args.fragment)
    text = render(args.shared.read_text(encoding="utf-8"), header, ops)
    rules = text.count("\n- ")
    old = args.out.read_text(encoding="utf-8") if args.out.is_file() else ""
    if old == text:
        print(f"OK: {args.out} already current ({len(text.encode())} B, {rules} rules)")
        return 0
    args.out.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=args.out.parent, prefix=".AGENTS.md.")
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(text)
    os.replace(tmp, args.out)
    print(f"OK: wrote {args.out} ({len(text.encode())} B, {rules} rules)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
