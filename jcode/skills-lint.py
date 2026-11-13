#!/usr/bin/env python3
"""Independent checker for the activation rewrite: written from the rule, not
from the matcher, and never imported by it.

The rule, restated in this checker's own words (skill_slash.py's docstring is
the same prose, but this file shares no code with it and does not import it):

  A slash is rewritten in exactly four positions and nowhere else:
    P1 line start   only blanks before the slash on the line;
    P2 marker       a list or heading marker, then blanks, then the slash, then
                    the token ending that run: `- `, `* `, `+ `, `#` (up to six),
                    `1. `, `1) `;
    P3 label        `Trigger:`, `Use when:`, `Use for:`, `Activate:`, `Invoke:`
                    ending at the colon immediately before the token, with or
                    without blanks after it;
    P4 code span    one single backtick, then slash + name, then one backtick,
                    with nothing else inside the backticks.
  A token is `/` + exactly an installed name, not continued by another name
  character. The character after the name must end the token: end of line,
  space, tab, `)`, `"`, `'`, backtick, or `,` `;` `:` `.` `!` `?` `|` `*`
  followed by end of line, a blank or a closing quote/paren/backtick.

  Every slash character in a file gets exactly one bucket, and this file counts
  them by bucket:
    rewritten       `/skill:<installed>`, or a token the rule rewrites
    prefixed-tail   `/skill:<installed>` with a path tail (/skill:brag.md)
    unknown-name    a name this host does not install (/clear, /tmp)
    not-name        the slash is not followed by a lowercase name (/Usr, / x)
    name-continues  an installed name is a strict prefix of the run (/bragx)
    token-suffix    installed name, but the next character does not end a token
    position        installed name, whole token, but not in P1-P4
    safe-bare       installed name, whole token, in P1-P4 - the only violation

  `audit()` returns `(problems, counts, total)`; `total` is every slash character
  in the input and `sum(counts.values()) == total` is asserted here, so a token
  cannot fall out of the ledger the way `/brag-` once did.

The checker's answers:
  * `expect_line(orig, names)` - its own rewrite of a line, by hand scanning.
    If the matcher disagrees with this, the transform refuses to write.
  * `check_change(orig, new, names)` - empty list means the pair is legal.
  * `tree_assert(text, names)` - problems in one file's text; empty means clean.
"""
import sys

# --- the rule's character sets, one character at a time -----------------------
TAIL_CHARS = ",;:.!?|*"
CLOSERS = ")\"'`"
BLANKS = " \t"
NAME_GLUE = frozenset(
    "abcdefghijklmnopqrstuvwxyz" "0123456789-_"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
LOWER = frozenset(chr(c) for c in range(ord("a"), ord("z") + 1))
DIGITS = frozenset(chr(c) for c in range(ord("0"), ord("9") + 1))
LABELS = ("trigger", "use when", "use for", "activate", "invoke")
MARKERS = "-*+"
HEADINGS = "#"

BUCKETS = ("rewritten", "prefixed-tail", "unknown-name", "not-name",
           "name-continues", "token-suffix", "position", "safe-bare")
LEFT_REASONS = ("prefixed-tail", "unknown-name", "not-name", "name-continues",
                "token-suffix", "position")
VIOLATION_REASONS = ("safe-bare",)


def _is_name_char(c):
    return c in LOWER or c in DIGITS or c == "-"


def _run(line, i):
    """The name-shaped run starting at i (lowercase, digits, hyphens)."""
    j = i
    while j < len(line) and _is_name_char(line[j]):
        j += 1
    return line[i:j]


def _name_at(line, i):
    """The name-shaped run at i, None when it is empty or not a name."""
    run = _run(line, i)
    if not run or run[0] not in LOWER:
        return None
    return run


def _end_ok(line, i):
    """True when one legal token end begins at line[i]."""
    if i >= len(line):
        return True
    c = line[i]
    if c in BLANKS or c in CLOSERS:
        return True
    if c in TAIL_CHARS:
        if i + 1 >= len(line):
            return True
        nxt = line[i + 1]
        return nxt in BLANKS or nxt in CLOSERS
    return False


def _label_before(line, colon):
    """The label word(s) ending at line[colon], lowercased, or None."""
    j = colon - 1
    while j >= 0 and line[j] in BLANKS:
        j -= 1
    word, start = "", j
    while j >= 0 and (line[j].isalpha() or line[j] in BLANKS):
        j -= 1
    word = line[j + 1:start + 1].strip().lower()
    if not word or not word.replace(" ", "").isalpha():
        return None
    return word


def _marker_ends_at(line, start):
    """True when a list or heading marker run, plus blanks, ends at `start`."""
    i = 0
    while i < len(line) and line[i] in BLANKS:
        i += 1
    if i >= len(line):
        return False
    c = line[i]
    if c in MARKERS:
        i += 1
    elif c in HEADINGS:
        n = 0
        while i < len(line) and line[i] in HEADINGS and n < 6:
            i += 1
            n += 1
    elif c in DIGITS:
        while i < len(line) and line[i] in DIGITS:
            i += 1
        if i >= len(line) or line[i] not in ".)":
            return False
        i += 1
    else:
        return False
    blanks = 0
    while i < len(line) and line[i] in BLANKS:
        i += 1
        blanks += 1
    return blanks > 0 and i == start


def _code_span(line, start, end):
    """True when `/name` is the whole of a single-backtick code span."""
    if start == 0 or line[start - 1] != "`" or end >= len(line):
        return False
    if line[end] != "`":
        return False
    if start >= 2 and line[start - 2] == "`":
        return False
    if end + 1 < len(line) and line[end + 1] == "`":
        return False
    return True


def position(line, start, end):
    """The P1-P4 name holding this token, or None. Disjoint by construction."""
    if _code_span(line, start, end):
        return "code-span"
    # P3: the colon immediately before the token (blanks allowed) ends a label.
    j = start - 1
    while j >= 0 and line[j] in BLANKS:
        j -= 1
    if j >= 0 and line[j] == ":":
        label = _label_before(line, j)
        if label in LABELS:
            return "label"
    if _marker_ends_at(line, start):
        return "marker"
    for c in line[:start]:
        if c not in BLANKS:
            return None
    return "line-start"


def _prefix_installed(line, i, names):
    """(name, tail_index) for `/skill:<installed>` at i, or None."""
    tag = "/skill:"
    if not line.startswith(tag, i):
        return None
    name = _name_at(line, i + len(tag))
    if name is None or name not in names:
        return None
    return name, i + len(tag) + len(name)


def _glued(name, names):
    """True when an installed name is a strict prefix of this run."""
    for known in names:
        if name != known and name.startswith(known):
            return True
    return False


def classify(line, i, names):
    """One bucket for the slash at line[i]: (bucket, name). Total, exclusive."""
    pref = _prefix_installed(line, i, names)
    if pref is not None:
        name, tail = pref
        return ("rewritten" if _end_ok(line, tail) else "prefixed-tail"), name
    if line.startswith("/skill:", i):
        return "unknown-name", (_name_at(line, i + 7) or "")
    name = _name_at(line, i + 1)
    if name is None:
        return "not-name", ""
    tail = i + 1 + len(name)
    if name not in names:
        return ("name-continues" if _glued(name, names) else "unknown-name"), name
    if not _end_ok(line, tail):
        return "token-suffix", name
    if position(line, i, tail) is None:
        return "position", name
    return "safe-bare", name


def tokens(line, names):
    """[(start, end, bucket, name)] - one entry for every slash character."""
    out, i = [], 0
    while True:
        i = line.find("/", i)
        if i < 0:
            return out
        bucket, name = classify(line, i, names)
        end = i + (len("/skill:") if line.startswith("/skill:", i) else 1) + len(name)
        out.append((i, end, bucket, name))
        i += 1


def count_slashes(text):
    """Every slash character in the text: the independent total to assert to."""
    n = 0
    for line in text.split("\n"):
        n += line.count("/")
    return n


def audit(text, names):
    """(problems, counts, total) over one file: one bucket per slash character."""
    counts = dict((key, 0) for key in BUCKETS)
    problems = []
    total = 0
    for lineno, line in enumerate(text.split("\n"), 1):
        body = line[:-1] if line.endswith("\r") else line
        for start, _end, bucket, name in tokens(body, names):
            total += 1
            counts[bucket] += 1
            if bucket in VIOLATION_REASONS:
                problems.append("line %d: bare /%s in a safe position (%s)"
                                % (lineno, name, position(
                                    body, start, start + 1 + len(name))))
    counted = sum(counts.values())
    if counted != total:
        problems.append("ledger books %d tokens but the file has %d slashes"
                        % (counted, total))
    if total != count_slashes(text):
        problems.append("scan saw %d slashes, the text has %d"
                        % (total, count_slashes(text)))
    return problems, counts, total


def tree_assert(text, names):
    """Problems anywhere in one file's text; empty list means it is clean."""
    return audit(text, names)[0]


def expect_line(orig, names):
    """This checker's own rewrite of one line, by hand scanning."""
    out, pos = [], 0
    for start, end, bucket, name in tokens(orig, names):
        if bucket != "safe-bare":
            continue
        out.append(orig[pos:start])
        out.append("/skill:" + name)
        pos = end
    out.append(orig[pos:])
    return "".join(out)


def check_change(orig, new, names):
    """Problems with one changed line; empty list means the pair is legal."""
    if new == orig:
        return []                      # an unchanged line is never a rewrite
    expected = expect_line(orig, names)
    if new != expected:
        return ["matcher/lint split: %r -> %r (this checker: %r)"
                % (orig, new, expected)]
    return []


def selfcheck():
    """This checker must pass P1-P4 and must not flag any of the left shapes."""
    bad = []
    names = {"brag"}
    rewrites = (
        ("/brag", "/skill:brag"),
        ("    /brag --tone x", "    /skill:brag --tone x"),
        ("- /brag", "- /skill:brag"),
        ("# /brag", "# /skill:brag"),
        ("1. /brag", "1. /skill:brag"),
        ("1) /brag", "1) /skill:brag"),
        ("Trigger: /brag.", "Trigger: /skill:brag."),
        ("Trigger:/brag", "Trigger:/skill:brag"),
        ("Use when:/brag, x", "Use when:/skill:brag, x"),
        ("Use for: /brag", "Use for: /skill:brag"),
        ("Activate: /brag", "Activate: /skill:brag"),
        ("Invoke: /brag", "Invoke: /skill:brag"),
        (r'description: "Use when: /brag, x"',
         r'description: "Use when: /skill:brag, x"'),
        ("use `/brag`.", "use `/skill:brag`."),
    )
    for orig, want in rewrites:
        got = expect_line(orig, names)
        if got != want:
            bad.append("checker rewrite %r -> %r (want %r)" % (orig, got, want))
    lefts = (
        ('cat "/brag"', "position"),
        ("cd /brag", "position"),
        ("[x](/brag)", "position"),
        ("<output-dir>/brag.mp4", "token-suffix"),
        ("|/brag|", "position"),
        ("**/brag**", "token-suffix"),
        ("run /brag!", "position"),
        ("x /brag-", "name-continues"),
        ("then run /brag", "position"),
        ("/brag.md", "token-suffix"),
        ("/brag/x", "token-suffix"),
        ("/brag@2x.png", "token-suffix"),
        ("/brag{1,2}", "token-suffix"),
        ("/brag,: ", "token-suffix"),
        ("Trigger: see /brag", "position"),
        ("use `/brag --x`", "position"),
        ("/bragx", "name-continues"),
        ("/clear", "unknown-name"),
        ("/usr/bin/brag", "position"),
        ("/Applications/Google Chrome.app", "not-name"),
        ("/", "not-name"),
        ("// byok", "not-name"),
        ("/skill:brag.md", "prefixed-tail"),
    )
    for text, want in lefts:
        problems, counts, total = audit(text, names)
        got = [b for _s, _e, b, _n in tokens(text, names) if b != "rewritten"]
        if problems or want not in got:
            bad.append("checker misread %r: want %r in %r, problems %r"
                       % (text, want, got, problems))
        if sum(counts.values()) != total:
            bad.append("ledger total wrong on %r" % text)
    for text in ("/brag", "/brag!", "Trigger:/brag"):
        problems, counts, _t = audit(text, names)
        if not problems or counts["safe-bare"] != 1:
            bad.append("checker passed a safe-position bare token: %r %r"
                       % (text, counts))
    if audit("/skill:brag", names)[1]["rewritten"] != 1:
        bad.append("checker did not count a rewritten token")
    for msg in bad:
        print("LINT SELF-CHECK FAIL " + msg)
    return not bad


def tree_report(paths):
    """Print the two headline numbers and a count per reason, then the sum.

    Exit 1 only when a slash sits bare in one of the four safe positions; a
    token left anywhere else is a counted fact, not a failure.
    """
    counts = dict((key, 0) for key in BUCKETS)
    problems, total = [], 0
    for path in paths:
        file_problems, file_counts, file_total = audit(
            open(path, encoding="utf-8").read(), _tree_names(paths))
        problems.extend("%s: %s" % (path, p) for p in file_problems)
        total += file_total
        for key, value in file_counts.items():
            counts[key] += value
    left = sum(counts[key] for key in LEFT_REASONS)
    print("skills-lint: safe-bare=%d left=%d %s sum=%d/%d"
          % (counts["safe-bare"], left,
             " ".join("%s=%d" % (key, counts[key]) for key in LEFT_REASONS
                      + ("rewritten",)),
             sum(counts.values()), total))
    for problem in problems:
        print(problem, file=sys.stderr)
    return 1 if problems or sum(counts.values()) != total else 0


def _tree_names(paths):
    return set(path.rsplit("/", 2)[-2] for path in paths)


def main(argv):
    """`skills-lint.py` self-checks; `skills-lint.py DIR...` reports on cards."""
    if len(argv) < 2:
        return 0 if selfcheck() else 1
    return tree_report(argv[1:])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
