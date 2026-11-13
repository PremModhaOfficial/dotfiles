#!/usr/bin/env python3
"""How a skill is named in prose on this host: one token grammar, four positions.

pi registers a skill as `/skill:<name>`; a card that says "invoke /caveman" names
a command pi does not have. `skills-activation.py` rewrites the installed cards
after a sync, and `overlay-lib.sh` must recognise its own text both before and
after the rewrite. Both import this file, so they cannot disagree.

THE RULE (round 3, attempt 7)
-----------------------------
Do not guess "path or command" from the words around a slash. A slash is
rewritten in exactly four positions, and nowhere else:

  P1 line start   the first visible character of the line is the slash, after
                  optional indentation: `  /brag --tone chaotic`.
  P2 marker       the slash follows a list or heading marker and the token ends
                  that marker's run: `- /brag`, `* /brag`, `+ /brag`, `# /brag`,
                  `## /brag`, `1. /brag`, `1) /brag` (one or more spaces or tabs
                  between marker and slash).
  P3 label        the slash starts the value of a `Trigger:`, `Use when:`,
                  `Use for:`, `Activate:` or `Invoke:` label on the same line,
                  with or without a space after the colon: `Trigger: /brag` and
                  `Trigger:/brag` both rewrite; `Trigger: see /brag` does not.
  P4 code span    a single-backtick span whose entire content is slash + the
                  name, no whitespace inside: `` `/brag` ``.
                  Not `` `/brag --x` ``, not ``` ``/brag`` ```.

Everything else is left byte-identical, always - no exclusion list, no
neighbouring-word check, no command list. `cat "/brag"`, `cd /brag`,
`[x](/brag)`, `<output-dir>/brag.mp4`, `|/brag|`, `**/brag**`, `run /brag!` and
`x /brag-` are all left exactly as written, and each is counted by
`skills-lint.py` under one reason.

THE TOKEN
---------
A candidate is `/` + exactly an installed directory name. The name must not be
continued by another name character (`/bragx`, `/brag-x`, `/brag_x` are not
tokens for `brag`), and the character after the name must end the token: end of
line, space, tab, `)`, `"`, `'`, backtick, or one of `,` `;` `:` `.` `!` `?`
`|` `*` followed by end of line, a space, a tab, a closing quote/paren or a
backtick. That is what keeps `/brag.md`, `/brag/x`, `/brag@2x.png`, `/brag{x,y}`
and `/brag,:` whole without any path reasoning: the token simply does not end
there.

WHY FOUR AND NOT THE WHOLE LINE
-------------------------------
Four attempts decided "path or command" from neighbouring words and each one
lost a new shape (the last rewrote `cat "/brag"`). The positions above are
enumerated shapes a card uses to *name* a command; a path is not written in any
of them in this tree, and the measured claim is only what the rule says: zero
bare names in P1-P4, every other slash token counted with a reason.

Run this file directly for the self-check (`python3 skill_slash.py`): the table
below fails if an edit widens the rule onto a path or narrows it off a command.
"""
import glob
import os
import re
import sys

ROOTS = (
    os.path.expanduser("~/.agents/skills"),
    os.path.expanduser("~/.pi/agent/skills"),
) + tuple(sorted(
    glob.glob(os.path.expanduser("~/.pi/agent/npm/node_modules/*/skills"))
    + glob.glob(os.path.expanduser("~/.pi/agent/git/github.com/*/*/skills"))
))

# <end>: one named alternative per character, no complement. A separator only
# ends the token when a boundary follows it, so `/brag.md` and `/brag,x` cannot
# match. `!`, `?`, `|` and `*` are here so `run /brag!` is *seen* and can be
# classified and left, instead of falling out of every count.
TAIL_CHARS = ",;:.!?|*"      # each only ends the token when a boundary follows
CLOSERS = ")\"'`"

# Anything that glues a name into a longer word, so `/bragx` is not `brag`.
NAME_CONTINUES = frozenset(
    "abcdefghijklmnopqrstuvwxyz0123456789-_"
    + "ABCDEFGHIJKLMNOPQRSTUVWXYZ")

LABELS = ("trigger", "use when", "use for", "activate", "invoke")
LABEL_TAIL = re.compile(
    r"(?<![A-Za-z])(?P<label>" + "|".join(LABELS) + r"):[ \t]*$",
    re.I)
MARKER = re.compile(r"^[ \t]*(?:[-*+]|#{1,6}|\d{1,9}[.)])[ \t]+$")


def skill_files(roots=ROOTS):
    seen, files = set(), []
    for root in roots:
        for path in sorted(glob.glob(os.path.join(root, "*", "SKILL.md"))):
            real = os.path.realpath(path)
            if real in seen:
                continue
            seen.add(real)
            files.append(path)
    return files


def skill_names(files=None):
    """The installed skill directory names - what pi will answer to."""
    return {os.path.basename(os.path.dirname(path))
            for path in (skill_files() if files is None else files)}


def position(line, start, end):
    """The name of the position holding this token, or None.

    `start` is the index of the slash, `end` the index just past the name. The
    four tests are disjoint by construction: P1 needs nothing but blanks before
    the slash, P2 needs a marker run, P3 needs a label ending at the colon, P4
    needs the backtick pair.
    """
    # P4: a single-backtick span whose whole content is `/name`.
    if (start and line[start - 1] == "`" and end < len(line)
            and line[end] == "`"
            and (start < 2 or line[start - 2] != "`")
            and (end + 1 >= len(line) or line[end + 1] != "`")):
        return "code-span"
    head = line[:start]
    # P3: the token starts the value of one of the five labels.
    if LABEL_TAIL.search(head):
        return "label"
    # P2: the token ends a list or heading marker's run.
    if MARKER.match(head):
        return "marker"
    # P1: nothing but indentation before the slash.
    if head.strip(" \t") == "":
        return "line-start"
    return None


def end_ok(line, i):
    """True when line[i:] begins a legal token end."""
    if i >= len(line):
        return True
    c = line[i]
    if c in " \t" or c in CLOSERS:
        return True
    if c in TAIL_CHARS:
        return i + 1 >= len(line) or line[i + 1] in " \t" or line[i + 1] in CLOSERS
    return False


def name_at(line, i):
    """The name-shaped run at i (a lowercase first letter, then digits and
    hyphens), or None. Every installed name starts with a letter, so a run like
    `/4mg` is not a name at all."""
    j = i
    while (j < len(line) and line[j] in NAME_CONTINUES and line[j] not in "_"
           and not line[j].isupper()):
        j += 1
    run = line[i:j]
    return run if run and run[0] in "abcdefghijklmnopqrstuvwxyz" else None


def token_at(line, i, names):
    """Classify the slash at line[i]: (bucket, name) - one bucket per slash.

    The buckets are total and mutually exclusive, in this order:
      rewritten      `/skill:<installed>`; or a token this rule rewrites
      prefixed-tail  `/skill:<installed>` with a path tail after the name
      unknown-name   `/skill:<x>` where x is not installed
      not-name       the slash is not followed by a lowercase name at all
      name-continues an installed name is a strict prefix of the run (/bragx)
      token-suffix   installed name, but the next character does not end a token
      position       installed name, whole token, but not in P1-P4
      safe-bare      installed name, whole token, in P1-P4 (a violation)
    """
    if line.startswith("/skill:", i):
        name = name_at(line, i + 7)
        if name in names:
            tail = i + 7 + len(name)
            return ("rewritten" if end_ok(line, tail) else "prefixed-tail"), name
        return "unknown-name", name or ""
    name = name_at(line, i + 1)
    if not name or name in ("", "-"):
        return "not-name", ""
    tail = i + 1 + len(name)
    if name not in names:
        # An installed name that is a strict prefix of the run is glued on.
        if any(name.startswith(n) and name != n for n in names):
            return "name-continues", name
        return "unknown-name", name
    if not end_ok(line, tail):
        return "token-suffix", name
    if position(line, i, tail) is None:
        return "position", name
    return "safe-bare", name


def buckets(line, names):
    """[(index, bucket, name)] - one entry for every slash character."""
    out, i = [], 0
    while True:
        i = line.find("/", i)
        if i < 0:
            return out
        bucket, name = token_at(line, i, names)
        out.append((i, bucket, name))
        i += 1


def rewrite_line(line, names):
    """One line in, one line out. Only P1-P4 tokens change; the rest is bytes."""
    body, cr = (line[:-1], "\r") if line.endswith("\r") else (line, "")
    out, pos = [], 0
    for start, bucket, name in buckets(body, names):
        if bucket != "safe-bare":
            continue
        out.append(body[pos:start])
        out.append("/skill:" + name)
        pos = start + 1 + len(name)
    out.append(body[pos:])
    return "".join(out) + cr


def normalize(text, names):
    """Rewrite every line; unmatched lines keep their bytes."""
    return "\n".join(rewrite_line(line, names) for line in text.split("\n"))


def scan(text, names):
    """[(line_number, name)] for every token this rule rewrites, in order."""
    hits = []
    for lineno, line in enumerate(text.split("\n"), 1):
        body = line[:-1] if line.endswith("\r") else line
        for _i, bucket, name in buckets(body, names):
            if bucket == "safe-bare":
                hits.append((lineno, name))
    return hits


# (line, expected rewrite) with NAMES = {"brag"}. Expectations were written from
# the rule before the run: the first block is left byte-identical, the second is
# rewritten.
NAMES = {"brag"}
CASES = (
    # --- left: a path or a shape that is not one of the four positions -------
    ('cat "/brag"\n', 'cat "/brag"\n'),
    ("cd /brag\n", "cd /brag\n"),
    ("[x](/brag)\n", "[x](/brag)\n"),
    ("<output-dir>/brag.mp4\n", "<output-dir>/brag.mp4\n"),
    ("|/brag|\n", "|/brag|\n"),
    ("**/brag**\n", "**/brag**\n"),
    ("run /brag!\n", "run /brag!\n"),
    ("x /brag-\n", "x /brag-\n"),
    ("then run /brag\n", "then run /brag\n"),
    ("mkdir /brag\n", "mkdir /brag\n"),
    ("[ ](/brag)\n", "[ ](/brag)\n"),
    ("- cd /brag\n", "- cd /brag\n"),
    ("Trigger: see /brag\n", "Trigger: see /brag\n"),
    ("/brag.md\n", "/brag.md\n"),
    ("/brag/x\n", "/brag/x\n"),
    ("/brag@2x.png\n", "/brag@2x.png\n"),
    ("/usr/bin/brag\n", "/usr/bin/brag\n"),
    ("/bragx\n", "/bragx\n"),
    ("/tmp/brag\n", "/tmp/brag\n"),
    ("use `/brag --x`\n", "use `/brag --x`\n"),
    ("a/brag\n", "a/brag\n"),
    ("~/brag\n", "~/brag\n"),
    ("./brag\n", "./brag\n"),
    # --- P1 line start ------------------------------------------------------
    ("/brag\n", "/skill:brag\n"),
    ("    /brag\n", "    /skill:brag\n"),
    ("/brag --tone chaotic\n", "/skill:brag --tone chaotic\n"),
    ("/brag!\n", "/skill:brag!\n"),
    ("`/brag`\n", "`/skill:brag`\n"),
    # --- P2 marker ----------------------------------------------------------
    ("- /brag\n", "- /skill:brag\n"),
    ("* /brag\n", "* /skill:brag\n"),
    ("+ /brag\n", "+ /skill:brag\n"),
    ("  - /brag\n", "  - /skill:brag\n"),
    ("# /brag\n", "# /skill:brag\n"),
    ("### /brag\n", "### /skill:brag\n"),
    ("1. /brag\n", "1. /skill:brag\n"),
    ("12) /brag\n", "12) /skill:brag\n"),
    ("-   /brag --x\n", "-   /skill:brag --x\n"),
    # --- P3 label -----------------------------------------------------------
    ("Trigger: /brag\n", "Trigger: /skill:brag\n"),
    ("Trigger:/brag\n", "Trigger:/skill:brag\n"),
    ("Use when:/brag, x\n", "Use when:/skill:brag, x\n"),
    ("  Use for: /brag.\n", "  Use for: /skill:brag.\n"),
    ("Activate: /brag\n", "Activate: /skill:brag\n"),
    ("Invoke: /brag\n", "Invoke: /skill:brag\n"),
    ('description: "Use when: /brag, x"\n',
     'description: "Use when: /skill:brag, x"\n'),
    # --- P4 code span -------------------------------------------------------
    ("use `/brag`\n", "use `/skill:brag`\n"),
    ("say `/brag`.\n", "say `/skill:brag`.\n"),
    ("`/brag`, `/brag`\n", "`/skill:brag`, `/skill:brag`\n"),
    # --- idempotent ---------------------------------------------------------
    ("/skill:brag\n", "/skill:brag\n"),
    ("Trigger: /skill:brag\n", "Trigger: /skill:brag\n"),
)


def selfcheck():
    """True when the rule still refuses these paths and still rewrites P1-P4."""
    bad = []
    for text, want in CASES:
        got = normalize(text, NAMES)
        if got != want:
            bad.append("%r -> %r (want %r)" % (text, got, want))
    for msg in bad:
        print("SELF-CHECK FAIL " + msg, file=sys.stderr)
    return not bad


if __name__ == "__main__":
    sys.exit(0 if selfcheck() else 1)
