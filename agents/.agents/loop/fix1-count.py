#!/usr/bin/env python3
"""FIX-1 word counter.

catalog  = skills whose description is loaded into every request, i.e. every
           SKILL.md WITHOUT `disable-model-invocation: true`.
raw      = every description, including manual-only skills (not in context).

pi has no catalog-wide budget (docs/skills.md:81, dist/core/skills.js:279 emits
every visible skill), so the only enforced limit is the per-description one:
1024 characters. Words are printed for information and gate nothing.

usage: python3 ~/.agents/loop/fix1-count.py          # totals
       python3 ~/.agents/loop/fix1-count.py --top    # biggest descriptions
"""
import os
import re
import sys

ROOT = os.path.expanduser("~/.agents/skills")


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    return m.group(1) if m else ""


def description(fm):
    """Return the description text as one line, for plain and block scalars."""
    m = re.search(r"^description:\s*(.*)$", fm, re.M)
    if not m:
        return ""
    first = m.group(1).strip()
    if first in ("|", ">", "|-", ">-", "|+", ">+"):
        lines = []
        for line in fm[m.end():].split("\n"):
            if not line.strip():
                continue
            if not line.startswith((" ", "\t")):
                break
            lines.append(line.strip())
        return " ".join(lines)
    return first.strip("\"'")


def main():
    rows = []
    for name in sorted(os.listdir(ROOT)):
        path = os.path.join(ROOT, name, "SKILL.md")
        if not os.path.isfile(path):
            continue
        fm = frontmatter(read(path))
        desc = description(fm)
        manual = re.search(r"^disable-model-invocation:\s*true\s*$", fm, re.M) is not None
        rows.append((name, len(desc.split()), len(desc), manual))

    raw = sum(w for _, w, _, _ in rows)
    catalog = sum(w for _, w, _, m in rows if not m)
    manual_n = sum(1 for _, _, _, m in rows if m)
    over = [(n, c) for n, _, c, _ in rows if c > 1024]

    print(f"skills total       : {len(rows)}")
    print(f"in catalog (auto)  : {len(rows) - manual_n}")
    print(f"manual-only        : {manual_n}")
    print(f"CATALOG words      : {catalog}")
    print(f"raw words (all)    : {raw}")
    print(f"longest description: {max(c for _, _, c, _ in rows)} chars")
    print(f"target             : <=1024 chars each -> {'PASS' if not over else 'FAIL'}")
    for name, chars in over:
        print(f"  OVER {chars} chars: {name}")
    if "--top" in sys.argv:
        for name, w, _, m in sorted(rows, key=lambda r: -r[1])[:20]:
            print(f"{w:5d} {'manual' if m else 'cat   '} {name}")
    return 0 if not over else 1


if __name__ == "__main__":
    sys.exit(main())
