#!/usr/bin/env python3
"""Shorten SKILL.md frontmatter descriptions to the catalogue cap.

Why a transform and not a hand edit: 108 of the 128 installed skills are synced
from upstream clones by update-all.sh, so a hand edit to a SKILL.md frontmatter
is reverted at the next pull. update-all.sh runs this after every skill sync and
fails the run if it cannot shorten, so the cap cannot be lost to a sync.

What it keeps: the routing text. Trigger clauses ("Use when ...", "Triggers: ...",
"Use for ...", "Also triggers ...", "Invoke with ...") are copied verbatim; only
scope/feature prose is dropped. Every quoted phrase, backticked term, slash
command and proper noun of the input is asserted to still appear in the output,
per skill; a lost term is a hard error, never a silent trim.

Usage:
  skills-cap.py                 # transform installed skills in place
  skills-cap.py --dry-run       # report, change nothing
  skills-cap.py --print-cap     # print the cap the check must enforce
  skills-cap.py --report FILE   # write the per-skill term proof table (tsv)
"""

import argparse
import glob
import json
import os
import re
import sys

# The cap is data-derived, not chosen. Floor = the longest routing vocabulary of
# any installed skill: openhilclimb at 266 B (five trigger phrases, the last one
# "keeping only improvements that raise the held-out test score"), then
# tiger-style at 205 B (twelve quoted triggers, /tiger-style, TigerBeetle, NASA
# rules). 270 B is the smallest round step above that floor, so no skill loses a
# routing word; forcing 200 B costs openhilclimb its test-score phrase and
# tiger-style its last triggers. A cap that hides trigger words is not a saving,
# so this constant moves only with the measurement behind it.
CAP = 270

# Every tree pi loads catalogue entries from that a package manager or git pull
# can overwrite: the synced tree, pi's host tree, and the npm/git package trees.
# A root left out is a description no sync will ever re-cap.
ROOTS = (
    os.path.expanduser("~/.agents/skills"),
    os.path.expanduser("~/.pi/agent/skills"),
) + tuple(sorted(
    glob.glob(os.path.expanduser("~/.pi/agent/npm/node_modules/*/skills"))
    + glob.glob(os.path.expanduser("~/.pi/agent/git/github.com/*/*/skills"))
))
LEDGER = os.path.expanduser("~/.jcode/state/skill-catalogue-terms.tsv")

# Every phrasing that marks the routing clause in the installed corpus: "use
# when" 57x, "use for" 20x, "use before/after/to" 5x, "triggers:" 8x, "invoke" 5x.
# A phrasing left out is a clause that never gets extracted, and its words are
# then dropped as prose without anything failing.
TRIGGER = re.compile(
    r"(?:^|[.;:]\s+)(?:use (?:only |this skill |it )?(?:when|for|to|on|before|after|during|in)|"
    r"triggers?|trigger when|also triggers|invokes?|invoke with)\b",
    re.I,
)
SCOPE_BUDGET = 70
USE_WHEN = "Use when: "

def escape(s):
    """Byte basis for the cap: what pi puts in the prompt, entities included."""
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
             .replace('"', "&quot;").replace("'", "&apos;"))


def clen(s):
    return len(escape(s).encode())


QUOTED = re.compile(r'"([^"]{2,60})"')
BACKTICK = re.compile(r"`([^`]{2,60})`")
# A slash command, optionally in the /skill:<name> form pi requires: without the
# optional prefix, the term recorded is "/skill" and shorten() then drops the
# name, so the card keeps a command that runs nothing - or none at all.
SLASH = re.compile(r"(?<![\w/])(/(?:skill:)?[a-z0-9][a-z0-9-]{1,40})")
PROPER = re.compile(r"[A-Z]{2,}|[a-z][A-Z]|\d")


def parse_frontmatter(text):
    """Return (frontmatter_text, body) or (None, text)."""
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    return (m.group(1), text[m.end():]) if m else (None, text)


def yaml_description(fm):
    """Description value as pi sees it (folded blocks resolved)."""
    try:
        import yaml
    except ImportError:
        sys.exit("skills-cap: PyYAML missing, cannot parse frontmatter safely")
    data = yaml.safe_load(fm) or {}
    desc = data.get("description")
    return desc if isinstance(desc, str) else None


def description_span(fm):
    """(start, end) character offsets of the description entry inside fm."""
    m = re.search(r"^description:[^\n]*", fm, re.M)
    if not m:
        return None
    end = m.end()
    for line in fm[m.end():].split("\n")[1:]:
        if line.strip() and not line[0].isspace():
            break
        end += len(line) + 1
        if end > len(fm):
            end = len(fm)
    return (m.start(), min(end, len(fm)))


SCAFFOLD = re.compile(
    r"^(?:(?:the user|someone|they|users?|you)\s+(?:says|asks|wants|needs|types)"
    r"(?: you)?(?: to)?|the user|you|to|also|and|or|invokes?|"
    r"when(?:ever)?|if|whether)\b[: ]*",
    re.I,
)


def split_items(seg):
    """Split on list commas / or / and, ignoring separators inside quotes or brackets.

    Without this, '"ponytail", "be lazy"' splits inside the quotes and the
    shortened text carries an unbalanced quote mark.
    """
    items, buf, depth, quote = [], [], 0, ""
    i = 0
    while i < len(seg):
        ch = seg[i]
        if quote:
            buf.append(ch)
            if ch == quote:
                quote = ""
            i += 1
            continue
        # An apostrophe inside a word ("module's") is not a quote: treating it as
        # one swallows the rest of the clause and the routing list with it.
        if ch in '"`\'' and not (ch == "'" and i > 0 and seg[i - 1].isalnum()):
            quote = ch
            buf.append(ch)
            i += 1
            continue
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth = max(0, depth - 1)
        if depth == 0:
            for sep in (" and ", " or ", ","):
                if seg.startswith(sep, i):
                    items.append("".join(buf))
                    buf, i = [], i + len(sep)
                    break
            else:
                buf.append(ch)
                i += 1
            continue
        buf.append(ch)
        i += 1
    items.append("".join(buf))
    return items


def trigger_items(desc):
    """Routing words: what a user would actually type or say to pick this skill.

    Only the trigger clauses contribute, and only up to the first colon inside
    them: what follows a colon in "Use when the user asks to change X: a, b, c"
    is the list of settings the skill touches, which is scope, not routing.
    """
    items = []
    for m in TRIGGER.finditer(desc):
        seg = desc[m.end():]
        owns_colon = re.match(r"\s*:", seg) is not None  # "Use when: a, b" form
        seg = seg.lstrip(": ")
        seg = re.split(r"(?<=[.!?])\s+(?=[A-Z0-9\"`(/])", seg, maxsplit=1)[0]
        if not owns_colon:
            seg = seg.split(":")[0]
        for item in split_items(seg):
            item = SCAFFOLD.sub("", item.strip().strip(".;:()"))
            item = item.strip()
            if len(item) > 1 and item[0] in "\"`'" and item[-1] == item[0]:
                item = item[1:-1]  # only an enclosing pair, never one unbalanced mark
            item = item.strip().rstrip(".;:")
            if 2 <= len(item) <= 70:
                items.append(item)
    return items


STOPWORDS = set(
    "a an the to in on for or and of is are be it this that when with you your my "
    "user says asks how what why do does not all any from by as at if then than so "
    "just use using via per into over".split()
)


def content_words(text):
    return {w for w in re.findall(r"[a-z0-9][a-z0-9_+.\-]*", text.lower()) if w not in STOPWORDS}


def trigger_terms(desc):
    """Words an agent matches this skill on, ordered by first appearance.

    Redundant terms are dropped: a term whose words all appear inside another
    kept term costs catalogue bytes and buys no matching surface, because the
    words themselves are still in the text.
    """
    found = []
    found += [t.strip() for t in QUOTED.findall(desc)]
    found += BACKTICK.findall(desc)
    found += SLASH.findall(desc)
    found += trigger_items(desc)
    for word in re.findall(r"[A-Za-z][A-Za-z0-9_+.\-]*[A-Za-z0-9]", desc):
        if PROPER.search(word) and len(word) > 2:
            found.append(word)
    out = []
    for term in found:
        low, words = term.lower(), content_words(term)
        if any(low == k.lower() for k in out):
            continue
        covered = False
        for other in found:
            if other is term or other.lower() == low:
                continue
            other_words = content_words(other)
            if words and words <= other_words and (
                len(other_words) > len(words) or len(other) < len(term)
            ):
                covered = True
                break
        if covered:
            continue
        out.append(term)
    return out


def split_sentences(desc):
    parts = re.split(r"(?<=[.!?])\s+(?=[A-Z0-9\"`(/])", desc)
    return [p.strip() for p in parts if p.strip()]


def scope_line(sentence):
    """First clause of the description, cut only at a clause boundary.

    A cut mid-clause reads as damage ("265 rules across 26."), so a sentence with
    no boundary inside the budget is not truncated at all: shorten() then either
    keeps it whole or drops it.
    """
    if len(sentence.encode()) <= SCOPE_BUDGET:
        return sentence
    cut = sentence.encode()[:SCOPE_BUDGET].decode("utf-8", "ignore")
    colon = cut.find(":")
    if colon >= SCOPE_BUDGET // 3:  # "preamble: list" cuts cleanly at the colon
        return cut[:colon].rstrip() + "."
    for sep in (",", ";", " —", " ("):
        idx = cut.rfind(sep)
        if idx >= SCOPE_BUDGET // 3:
            return cut[:idx].rstrip() + "."
    return ""


def hard_cut(sentence, cap):
    """Last resort for a description with no extractable routing terms.

    Such a description is all routing text: dropping it would remove the skill
    from the catalogue entirely (pi skips a skill with an empty description), so
    it is trimmed to the cap instead of being replaced by a term list.
    """
    words = sentence.split()
    while words and clen(" ".join(words) + ".") > cap:
        words.pop()
    return (" ".join(words).rstrip(" ,;:-—") + ".") if words else ""


def shorten(desc, cap=None):
    """Canonical form: one scope line, then every routing term, prose dropped.

    Terms already spelled out in the scope line are not repeated, so a term is
    only paid for once. A description whose first sentence is already the trigger
    clause gets no scope line: the skill name carries the scope. Idempotent: a
    second pass over the output reproduces it byte for byte.
    """
    cap = cap or CAP
    sentences = split_sentences(desc)
    if not sentences:
        return desc
    all_terms = trigger_terms(desc)

    def build(scope):
        terms = [t for t in all_terms if t.lower() not in scope.lower()]
        if not terms:
            return scope
        body = ", ".join(terms)
        return ((scope.rstrip(".") + ". " if scope else "") + USE_WHEN + body
                + ("" if body.endswith(".") else "."))

    scopes = [""] if TRIGGER.search(sentences[0]) else [sentences[0], scope_line(sentences[0]), ""]
    for scope in scopes:  # widest scope that still fits: no needless truncation
        out = build(scope)
        if out and clen(out) <= cap:
            return out
    return build("") or hard_cut(sentences[0], cap) or desc


def rewrite(text, new_desc):
    fm, body = parse_frontmatter(text)
    span = description_span(fm)
    if span is None:
        return None
    value = json.dumps(new_desc, ensure_ascii=False)  # valid YAML double-quoted
    return "---\n" + fm[: span[0]] + "description: " + value + fm[span[1]:] + "\n---\n" + body


def skill_files():
    seen, files = set(), []
    for root in ROOTS:
        for path in sorted(glob.glob(os.path.join(root, "*", "SKILL.md"))):
            real = os.path.realpath(path)
            if real in seen:
                continue
            seen.add(real)
            files.append(path)
    return files


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--print-cap", action="store_true")
    ap.add_argument("--report")
    ap.add_argument("--cap", type=int, default=CAP, help="measure against another cap")
    args = ap.parse_args()
    cap = args.cap
    if args.print_cap:
        print(CAP)
        return 0

    rows, errors, changed, before, after = [], [], 0, 0, 0
    for path in skill_files():
        text = open(path, encoding="utf-8").read()
        fm, _ = parse_frontmatter(text)
        if fm is None:
            continue
        desc = yaml_description(fm)
        if not desc:
            continue
        flat = " ".join(desc.split())
        terms = trigger_terms(flat)
        new = flat if clen(flat) <= cap else shorten(flat, cap)
        lost = [t for t in terms if t.lower() not in new.lower()]
        rows.append((os.path.basename(os.path.dirname(path)), len(flat.encode()), clen(new), terms, lost))
        before += len(flat.encode())
        after += len(new.encode())
        if clen(new) > cap:
            errors.append(f"{rows[-1][0]}: {clen(new)} B > cap {cap} even after shortening")
        if not new:
            errors.append(f"{rows[-1][0]}: description would be empty; pi drops such a skill")
        if lost:
            errors.append(f"{rows[-1][0]}: would lose routing terms {lost}")
        if new != flat:
            changed += 1
            if not args.dry_run:
                out = rewrite(text, new)
                if out is None:
                    errors.append(f"{rows[-1][0]}: no single description entry to rewrite")
                else:
                    open(path, "w", encoding="utf-8").write(out)

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            fh.write("skill\tbefore_bytes\tafter_bytes\tkept_terms\n")
            for name, b, a, terms, lost in sorted(rows):
                fh.write(f"{name}\t{b}\t{a}\t{'; '.join(terms)}\n")

    if not args.dry_run:
        os.makedirs(os.path.dirname(LEDGER), exist_ok=True)
        with open(LEDGER, "w", encoding="utf-8") as fh:
            for name, _, _, terms, _ in sorted(rows):
                for term in terms:
                    fh.write(f"{name}\t{term}\n")

    print(
        f"skills-cap: cap {cap} B, {len(rows)} skills with descriptions, "
        f"description bytes {before} -> {after} (-{before - after}), {changed} rewritten"
    )
    for err in errors:
        print("ERROR " + err, file=sys.stderr)
    if args.dry_run and changed:
        print("dry-run: no file written")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
