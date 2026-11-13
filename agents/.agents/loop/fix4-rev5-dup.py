#!/usr/bin/env python3
"""FIX-4 rev5 duplication measurement -- continuation of the reviewer's metric.

One metric, one cutoff, every file measured the same way.

Method:
  * sentence = one line of body text split again on [.!?] + whitespace.
    Markdown headings and blank lines are not sentences.
  * tokens   = lowercase [a-z0-9_./-] runs longer than 2 chars, minus STOP.
  * A sentence is DUPLICATE when >= CUTOFF of its tokens also appear in the
    text it is compared against (token containment, the rev4/reviewer rule).
  * Percentage is byte-weighted: duplicate sentence bytes / total sentence bytes.

Two comparison modes, both printed because they answer different questions:
  union  - tokens of the whole comparison file (the reviewer's 0.65 -> 8.4%).
           Says "this wording already exists somewhere in the canonical file".
  best   - tokens of the single closest sentence in the comparison file.
           Says "this sentence restates that sentence". The five paraphrase
           restatements live below the cutoff in both modes; they are listed by
           `--nearmiss` so they are visible instead of hidden.

Usage:
  rev5-dup.py <set-dir> [--with-pi] [--nearmiss N]
    <set-dir>/AGENTS.md       canonical text every reference is compared against
    <set-dir>/refs/*.md       reference rows
    <set-dir>/pi-AGENTS.md    pi copy, denominator only with --with-pi
"""
import re
import sys
from pathlib import Path

CUTOFF = 0.65
STOP = set("the a an of to and or for in on at is are be it its this that with as by "
           "not no do does you your we our than then so but if when from into only".split())


def toks(s):
    return {w for w in re.findall(r"[a-z0-9_./-]+", s.lower()) if len(w) > 2 and w not in STOP}


def sentences(path):
    out = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        out += [p.strip() for p in re.split(r"(?<=[.!?])\s+", line) if p.strip()]
    return out


def load(path):
    return [(s, toks(s)) for s in sentences(path)]


def score(sent_tokens, other_text_tokens, other_sentences):
    if not sent_tokens:
        return 0.0, 0.0
    union = len(sent_tokens & other_text_tokens) / len(sent_tokens)
    best = max((len(sent_tokens & t) / len(sent_tokens)
                for _, t in other_sentences if t), default=0.0)
    return union, best


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    set_dir = Path(args[0] if args else Path.home() / ".agents")
    with_pi = "--with-pi" in sys.argv
    nearmiss = 0
    if "--nearmiss" in sys.argv:
        nearmiss = int(sys.argv[sys.argv.index("--nearmiss") + 1])

    canon_sents = load(set_dir / "AGENTS.md")
    canon_text = set()
    for _, t in canon_sents:
        canon_text |= t
    refs = set_dir / "refs"
    if not refs.is_dir():
        refs = set_dir / "references"
    targets = [(p, load(p)) for p in sorted(refs.glob("*.md"))]
    pi_path = set_dir / "pi-AGENTS.md"
    if with_pi and pi_path.exists():
        targets.append((pi_path, load(pi_path)))

    print(f"set: {set_dir}   cutoff: {CUTOFF:.2f}")
    print(f"comparison text: AGENTS.md ({sum(len(s) for s,_ in canon_sents)} sentence bytes)\n")
    print(f"{'file':34} {'sbytes':>7} {'dupB':>6} {'dup%':>6}  {'union':>6} {'best':>6}")
    rows = []
    for path, sents in targets:
        total = dupB = dupN = 0
        misses = []
        for s, t in sents:
            u, b = score(t, canon_text, canon_sents)
            total += len(s)
            if u >= CUTOFF:
                dupB += len(s)
                dupN += 1
            misses.append((u, b, s))
        rows.append((path.name, total, dupB))
        pct = 100.0 * dupB / total if total else 0.0
        print(f"{path.name:34} {total:7} {dupB:6} {pct:5.1f}% {dupN:6} {'':6}")
        if nearmiss and path.suffix == ".md" and path.parent.name in ("refs", "references"):
            for u, b, s in misses:
                if u < CUTOFF and b >= 0.20:
                    print(f"    near miss union={u:.2f} best={b:.2f}  {s[:88]}")

    den = sum(t for _, t, _ in rows)
    num = sum(d for _, _, d in rows)
    label = "WITH pi copy" if with_pi else "WITHOUT pi copy"
    print(f"\n{label:14} duplicated {num} B of {den} B = {100.0*num/den:.1f}%")


if __name__ == "__main__":
    main()
