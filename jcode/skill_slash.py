#!/usr/bin/env python3
"""One rule, two consumers: how a skill is named in prose on this host.

pi registers a skill as `/skill:<name>`. A card that says "invoke /caveman" names
a command pi does not have. Two things need that rule and must agree or they
fight: `skills-activation.py` (rewrites every installed card after a sync) and
`overlay-lib.sh` (patches cards, and must recognise its own text both before and
after the rewrite, or a second update-all run reports every overlay as drift).

The matcher is built by construction: a rewrite needs a slash token that starts a
word and ends at a name that is an installed skill directory. A slash inside a
path is reached through a path character (`~/x`, `a/b`, `<dir>/brag.mp4`), so it
can never be in a position this matches, and a name followed by `.ext` or
`/segment` is a file, not a command. `/tmp`, `/clear`, `/plugin` never match at
all: no installed skill is called tmp, clear or plugin.

Run this file directly for the self-check (`python3 skill_slash.py`): the fixture
cases below fail the build if an edit widens the matcher back onto a path.
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

# A bare slash command. Position: start of line, whitespace, a quote or a
# backtick before the slash - a bullet and a heading prefix are whitespace, and a
# path character (letter, digit, `/`, `.`, `~`, `>`, ...) is none of these. Tail:
# the token ends at the name, so `[\w/-]` (word continues, further segment) and
# `.` + alnum (an extension) refuse.
BARE = re.compile(
    r"(?:^|(?<=[\s\"'`]))"
    r"/([a-z][a-z0-9]*(?:-[a-z0-9]+)*)"
    r"(?![\w/-])(?!\.[A-Za-z0-9])",
    re.M)

# Characters that make the slash part of a path instead of a word.
PATH = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
           "/\\.:~$><=_-")
NAME = re.compile(r"^name:\s*(\S+)", re.M)
REWRITE = re.compile(r"/skill:[a-z][a-z0-9-]*")


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
    """The installed skill directory names - what `pi` will answer to.

    Directory name only: skills-audit fails any card whose frontmatter name
    disagrees with its directory, so one name is the whole set.
    """
    return {os.path.basename(os.path.dirname(path))
            for path in (skill_files() if files is None else files)}


def scan(text, names):
    """[(line_number, name)] for every bare skill reference in text."""
    hits = []
    for lineno, line in enumerate(text.split("\n"), 1):
        for m in BARE.finditer(line):
            if m.group(1) in names:
                hits.append((lineno, m.group(1)))
    return hits


def normalize(text, names):
    return BARE.sub(lambda m: "/skill:" + m.group(1) if m.group(1) in names else m.group(0), text)


def corrupt_paths(text):
    """[(line, token)] where a /skill: rewrite landed inside a path.

    True when the rewritten slash is glued to a path character, or the name runs
    on into `.ext` or `/segment`. A sentence-final `.` is punctuation, not an
    extension, so it is not flagged.
    """
    out = []
    for m in REWRITE.finditer(text):
        before = text[m.start() - 1] if m.start() else ""
        after = text[m.end():m.end() + 2]
        if (before in PATH or after[:1] == "/" or after[:1] in "_-"
                or after[:1].isalnum()
                or (after[:1] == "." and after[1:2].isalnum())):
            out.append((text.count("\n", 0, m.start()) + 1, m.group(0)))
    return out


# (input, expected normalize(input)) with NAMES = {"brag"}; the first group must
# not change - that is the brag/SKILL.md:130 regression, verbatim.
CASES = (
    ("<output-dir>/brag.mp4\n", "<output-dir>/brag.mp4\n"),
    ("poster `<output-dir>/brag.jpg`\n", "poster `<output-dir>/brag.jpg`\n"),
    ("rm /brag/x and ./brag and ~/brag and a/brag\n",
     "rm /brag/x and ./brag and ~/brag and a/brag\n"),
    ("opts /tmp /clear /plugin /brag.md\n", "opts /tmp /clear /plugin /brag.md\n"),
    ("/skill:brag stays\n", "/skill:brag stays\n"),
    ("# /brag\n", "# /skill:brag\n"),
    ("- /brag\n", "- /skill:brag\n"),
    ('say "/brag"\n', 'say "/skill:brag"\n'),
    ("use `/brag`\n", "use `/skill:brag`\n"),
    ("Trigger: /brag.\n", "Trigger: /skill:brag.\n"),
)
NAMES = {"brag"}


def selfcheck():
    """True when the matcher still refuses paths and still rewrites commands."""
    bad = []
    for text, want in CASES:
        got = normalize(text, NAMES)
        if got != want:
            bad.append("matcher: %r -> %r (want %r)" % (text, got, want))
    for text in ("<output-dir>/skill:brag.mp4", "a/skill:brag", "/skill:brag/x"):
        if not corrupt_paths(text):
            bad.append("corruption not detected: %r" % text)
    for text in ("/skill:brag is its own workflow.", "x `/skill:brag`"):
        if corrupt_paths(text):
            bad.append("false corruption: %r" % text)
    for msg in bad:
        print("SELF-CHECK FAIL " + msg, file=sys.stderr)
    return not bad


if __name__ == "__main__":
    sys.exit(0 if selfcheck() else 1)
