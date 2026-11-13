#!/usr/bin/env python3
"""Tests for the activation transform: the four safe positions, the token tail,
the total bucket ledger, the refusal path and the tree-baseline gate.

Run: python3 skills-activation.test.py
Exit 0 when every check passed. Every row states its expected result as data
before the run, so a failure says what the rule was, not only what happened.

The rule under test (round 3, attempt 7): a slash is rewritten in exactly four
positions - line start, a list/heading marker, a Trigger:/Use when:/Use for:/
Activate:/Invoke: label, a whole-name code span - and nowhere else. Everything
else is left byte-identical and counted.
"""
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
TRANSFORM = os.path.join(HERE, "skills-activation.py")


def _load(name, filename):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, filename))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


ss = _load("skill_slash", "skill_slash.py")
lint = _load("skills_lint", "skills-lint.py")

FAILS = []
NAMES = {"brag"}


def check(label, expected, actual):
    if expected == actual:
        print("PASS %s" % label)
    else:
        print("FAIL %s\n  expected: %r\n  actual:   %r" % (label, expected, actual))
        FAILS.append(label)


# --- 1. the table, expectation stated before the run -------------------------
# (label, input, expected output, expected bucket for the /brag token, why).
# Rows 1-8 are review D's falsifications; the rest are the four positions and
# the shapes the review said the old rule left bare.
TABLE = (
    # --- review D: a path that must never be rewritten ----------------------
    ("quoted path argument", 'cat "/brag"', 'cat "/brag"', "position",
     "review D: cat \"/brag\" was rewritten"),
    ("cd argument", "cd /brag", "cd /brag", "position",
     "review D: path argument"),
    ("markdown link", "[x](/brag)", "[x](/brag)", "position",
     "review D: link target"),
    ("output file", "<output-dir>/brag.mp4", "<output-dir>/brag.mp4",
     "token-suffix", "review D: <output-dir>/brag.mp4"),
    ("dir command not in a list", "mkdir /brag", "mkdir /brag", "position",
     "review D: unlisted command is no longer guessed at"),
    ("vim", "vim /brag", "vim /brag", "position", "review D: unlisted command"),
    ("sort", "sort /brag", "sort /brag", "position", "review D: unlisted command"),
    ("python", "python3 /brag", "python3 /brag", "position",
     "review D: unlisted command"),
    ("windows dir", "dir /brag", "dir /brag", "position",
     "review D: windows path command"),
    ("quoted single", "cat '/brag'", "cat '/brag'", "position",
     "review D: single-quoted path"),
    ("quoted in cd", 'cd "/brag"', 'cd "/brag"', "position",
     "review D: quoted path"),
    ("list item with a command", "- cd /brag", "- cd /brag", "position",
     "review D: the marker's value is a command, the token is not the value"),
    # --- review D: shapes that were left bare and uncounted ----------------
    ("table cell", "|/brag|", "|/brag|", "position",
     "review D: pipe shape, not one of the four"),
    ("bold", "**/brag**", "**/brag**", "token-suffix",
     "review D: asterisk shape, not one of the four"),
    ("bang", "run /brag!", "run /brag!", "position",
     "review D: bang shape, not one of the four"),
    ("bang in a marker", "- /brag!", "- /skill:brag!", "safe-bare",
     "the bang shape rewrites when it sits in a position"),
    ("star in a marker", "* /brag*", "* /skill:brag*", "safe-bare",
     "the asterisk shape rewrites when it sits in a position"),
    ("pipe after a label", "Trigger: |/brag|", "Trigger: |/brag|", "position",
     "a pipe token does not start the label's value, so it is left"),
    ("bare trigger without space", "Trigger:/brag", "Trigger:/skill:brag",
     "safe-bare", "the label position is enumerated, colon spacing is free"),
    ("prefix run", "x /brag-", "x /brag-", "name-continues",
     "review D: /brag- was counted in no bucket"),
    ("prefix run at start", "/brag-x", "/brag-x", "name-continues",
     "the run is glued onto an installed name"),
    ("prose", "then run /brag", "then run /brag", "position",
     "prose after a space is not a safe position"),
    ("prose in parens", "(run /brag)", "(run /brag)", "position",
     "prose in parens is not a safe position"),
    ("label with prose", "Trigger: see /brag", "Trigger: see /brag",
     "position", "the token does not start the label's value"),
    # --- the tail rule: paths stay whole without path reasoning -------------
    ("extension", "/brag.md", "/brag.md", "token-suffix", "file extension"),
    ("segment", "/brag/x", "/brag/x", "token-suffix", "further segment"),
    ("retina", "/brag@2x.png", "/brag@2x.png", "token-suffix", "file name"),
    ("query", "/brag?tab=x", "/brag?tab=x", "token-suffix", "query, no boundary"),
    ("fragment", "/brag#x", "/brag#x", "token-suffix", "fragment"),
    ("brace glob", "/brag{x,y}", "/brag{x,y}", "token-suffix", "glob"),
    ("error code", "/brag,: ", "/brag,: ", "token-suffix",
     "two separators, no boundary: the old lint refused this whole"),
    ("unknown command", "/clear", "/clear", "unknown-name", "not installed"),
    ("not a name", "/ x", "/ x", "not-name", "no name after the slash"),
    ("prefixed path", "/skill:brag.md", "/skill:brag.md", "prefixed-tail",
     "an already rewritten token with a path tail is left and counted"),
    # --- P1 line start ------------------------------------------------------
    ("P1 bare", "/brag", "/skill:brag", "safe-bare", "line start"),
    ("P1 indented", "    /brag", "    /skill:brag", "safe-bare", "indented"),
    ("P1 with args", "/brag --tone chaotic", "/skill:brag --tone chaotic",
     "safe-bare", "line start, arguments after the token"),
    ("P1 bang", "/brag!", "/skill:brag!", "safe-bare",
     "the bang shape rewrites when it sits in a position"),
    ("P1 code span", "`/brag`", "`/skill:brag`", "safe-bare",
     "a whole-name code span at line start"),
    # --- P2 marker ----------------------------------------------------------
    ("P2 dash", "- /brag", "- /skill:brag", "safe-bare", "dash bullet"),
    ("P2 star", "* /brag", "* /skill:brag", "safe-bare", "star bullet"),
    ("P2 plus", "+ /brag", "+ /skill:brag", "safe-bare", "plus bullet"),
    ("P2 indented", "  - /brag", "  - /skill:brag", "safe-bare",
     "indented bullet"),
    ("P2 heading", "### /brag", "### /skill:brag", "safe-bare", "heading"),
    ("P2 numbered", "1. /brag", "1. /skill:brag", "safe-bare", "ordered list"),
    ("P2 numbered paren", "12) /brag", "12) /skill:brag", "safe-bare",
     "ordered list, paren form"),
    ("P2 spaces", "-   /brag --x", "-   /skill:brag --x", "safe-bare",
     "the token still ends the marker's run"),
    # --- P3 label -----------------------------------------------------------
    ("P3 trigger", "Trigger: /brag", "Trigger: /skill:brag", "safe-bare",
     "trigger label with a space"),
    ("P3 trigger no space", "Trigger:/brag", "Trigger:/skill:brag",
     "safe-bare", "the label form is enumerated"),
    ("P3 use when", "Use when:/brag, x", "Use when:/skill:brag, x",
     "safe-bare", "no space after the colon"),
    ("P3 use for", "  Use for: /brag.", "  Use for: /skill:brag.",
     "safe-bare", "dot is a token end"),
    ("P3 activate", "Activate: /brag", "Activate: /skill:brag", "safe-bare",
     "activate label"),
    ("P3 invoke", "Invoke: /brag", "Invoke: /skill:brag", "safe-bare",
     "invoke label"),
    ("P3 frontmatter", 'description: "Use when: /brag, x"',
     'description: "Use when: /skill:brag, x"', "safe-bare",
     "the label is inside a quoted frontmatter value"),
    # --- P4 code span -------------------------------------------------------
    ("P4 span", "use `/brag`", "use `/skill:brag`", "safe-bare",
     "the whole span is the name"),
    ("P4 span then dot", "say `/brag`.", "say `/skill:brag`.",
     "safe-bare", "text after the closing backtick"),
    ("P4 two spans", "`/brag`, `/brag`", "`/skill:brag`, `/skill:brag`",
     "safe-bare", "two spans, two rewrites"),
    # --- idempotent ---------------------------------------------------------
    ("already rewritten", "/skill:brag", "/skill:brag", "rewritten",
     "the transform is idempotent"),
    ("label rewritten", "Trigger: /skill:brag", "Trigger: /skill:brag",
     "rewritten", "label, already rewritten"),
)


def test_table():
    for label, text, want, want_bucket, why in TABLE:
        got = ss.normalize(text, NAMES)
        check("table/%s (%s)" % (label, why), want, got)
        # the independent checker must produce the same line, byte for byte
        check("lint-agrees/%s" % label, [], lint.check_change(text, got, NAMES))
        # and the bucket for the /brag token is the predicted one
        buckets = [b for _s, _e, b, _n in lint.tokens(text, NAMES)]
        check("bucket/%s (%s)" % (label, why), True, want_bucket in buckets)
        # idempotence: a second pass changes nothing
        check("idempotent/%s" % label, got, ss.normalize(got, NAMES))


# --- 2. the bucket ledger is total over slash characters ---------------------
LEDGER_CORPUS = "\n".join([
    "/brag",                                  # safe-bare
    "- /brag",                                # safe-bare
    "Trigger:/brag",                          # safe-bare
    "use `/brag`",                            # safe-bare
    "cat \"/brag\"",                          # position
    "|/brag|",                                # position
    "**/brag**",                              # token-suffix
    "run /brag!",                             # position
    "x /brag-",                               # name-continues
    "/brag.md",                               # token-suffix
    "/clear",                                 # unknown-name
    "/ x",                                    # not-name
    "/skill:brag",                            # rewritten
    "/skill:brag.md",                         # prefixed-tail
    "https://example.dev/brag",               # position (URL segment)
])


def test_bucket_ledger():
    problems, counts, total = lint.audit(LEDGER_CORPUS, NAMES)
    check("ledger/sum equals slash total", total, sum(counts.values()))
    check("ledger/slashes counted", lint.count_slashes(LEDGER_CORPUS), total)
    check("ledger/total", 17, total)
    check("ledger/safe-bare", 4, counts["safe-bare"])
    check("ledger/position", 4, counts["position"])
    check("ledger/token-suffix", 2, counts["token-suffix"])
    check("ledger/name-continues", 1, counts["name-continues"])
    check("ledger/unknown-name", 2, counts["unknown-name"])
    check("ledger/not-name", 2, counts["not-name"])
    check("ledger/rewritten", 1, counts["rewritten"])
    check("ledger/prefixed-tail", 1, counts["prefixed-tail"])
    # the reviewer's hole, named: /brag- used to land in no bucket at all
    check("ledger/the /brag- hole is counted", 1, counts["name-continues"])
    # the runner's four safe-bare rows are the problems, nothing else is
    check("ledger/problems are the safe-position rows", 4, len(problems))
    # after the rewrite the same corpus has the same total and zero safe-bare
    new = ss.normalize(LEDGER_CORPUS, NAMES)
    problems, counts, total = lint.audit(new, NAMES)
    check("ledger/after sum equals slash total", total, sum(counts.values()))
    check("ledger/after has no safe-bare", 0, counts["safe-bare"])
    check("ledger/after has the same total", 17, total)
    check("ledger/after has no problems", [], problems)


# --- 3. the four positions are positions, not a widened opener --------------
def test_positions_are_what_is_rewritten():
    """The same token, inside a position and outside it, both outcomes."""
    for want_in, want_out, token, label in (
            ("/brag", "x /brag", "line start", "P1"),
            ("- /brag", "- x /brag", "marker", "P2"),
            ("Trigger: /brag", "Trigger: x /brag", "label", "P3"),
            ("`/brag`", "`x /brag`", "code span", "P4")):
        check("position/%s rewrites" % label, want_in.replace("/brag", "/skill:brag")
              if label != "P4" else "`/skill:brag`", ss.normalize(want_in, NAMES))
        check("position/%s leaves the same token outside" % label,
              want_out, ss.normalize(want_out, NAMES))


# --- 4. one card with every shape ------------------------------------------
CARD = (
    "# brag\n"
    "\n"
    "then run /brag stays bare; Trigger: /brag rewrites.\n"
    "cat \"/brag\" stays; [x](/brag) stays; <output-dir>/brag.mp4 stays.\n"
    "Trigger:/brag rewrites too, and `/brag` rewrites, `/brag --x` does not.\n"
    "- /brag is a bullet; 1. /brag is a list; |/brag| and **/brag** stay.\n"
    "/clear is not ours.\n"
)
CARD_WANT = (
    "# brag\n"
    "\n"
    "then run /brag stays bare; Trigger: /skill:brag rewrites.\n"
    "cat \"/brag\" stays; [x](/brag) stays; <output-dir>/brag.mp4 stays.\n"
    "Trigger:/skill:brag rewrites too, and `/skill:brag` rewrites, `/brag --x` does not.\n"
    "- /skill:brag is a bullet; 1. /brag is a list; |/brag| and **/brag** stay.\n"
    "/clear is not ours.\n"
)


def test_card_shapes():
    tmp = tempfile.mkdtemp(prefix="card-")
    try:
        home = os.path.join(tmp, "home")
        skills = _fake_tree(home, 145, {"brag": CARD})
        r = _run(home)
        got = open(os.path.join(skills, "brag", "SKILL.md"), encoding="utf-8").read()
        check("card/exits 0 with a bare token outside a position", 0, r.returncode)
        check("card/rewrites only the safe positions", CARD_WANT, got)
        check("card/reports zero safe-bare", True, "safe-bare=0" in r.stdout)
        check("card/reports four rewrites", True,
              "rewritten=4" in r.stdout)
        check("card/reports the after state", True,
              "0 bare in a safe position, 9 left" in r.stdout)
        check("card/reports the before state", True,
              "safe-bare=4" in r.stdout)
        check("card/counts the position bucket", True, "position=6" in r.stdout)
        check("card/asserts the bucket sum", True, "sum=13/13" in r.stdout)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


# --- 5. an already-prefixed path is left byte-identical, not refused --------
def test_prefixed_path_is_left():
    tmp = tempfile.mkdtemp(prefix="prefixed-")
    try:
        home = os.path.join(tmp, "home")
        body = "see `/skill:wizard/x` for the path\n/brag\n"
        skills = _fake_tree(home, 145, {"wizard": body, "brag": "# brag\n/brag\n"})
        r = _run(home)
        got = open(os.path.join(skills, "wizard", "SKILL.md"), encoding="utf-8").read()
        check("prefixed/exit 0", 0, r.returncode)
        check("prefixed/left byte-identical", body.replace("/brag", "/skill:brag")
              .replace("/skill:skill:", "/skill:"), got)
        check("prefixed/counted as prefixed-tail", True,
              "prefixed-tail=1" in r.stdout)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


# --- 6. a check that cannot fail is proven to fail at least once ------------
# The round-3 matcher (any opener, any tail that is not a path character, a
# block rule of neighbouring words) and its corruption check shared the blind
# spot: both called `cat "/brag"` clean and rewrote it.
OLD_BARE = re.compile(
    r"(?:^|(?<=[\s\"'`]))"
    r"/([a-z][a-z0-9]*(?:-[a-z0-9]+)*)"
    r"(?![\w/-])(?!\.[A-Za-z0-9])", re.M)


def _old_normalize(text, names):
    return OLD_BARE.sub(
        lambda m: "/skill:" + m.group(1) if m.group(1) in names else m.group(0), text)


def test_checks_can_fail():
    # the old matcher rewrites rows the new rule must leave: the table has teeth
    bad = [label for label, text, want, _b, _w in TABLE
           if _old_normalize(text, NAMES) != want]
    check("old-matcher fails the table", True, bool(bad))
    check("old-matcher rewrote the quoted path", 'cat "/skill:brag"',
          _old_normalize('cat "/brag"', NAMES))
    check("old-matcher left the bracket link alone", "[x](/brag)",
          _old_normalize("[x](/brag)", NAMES))
    check("old-matcher left /brag- alone", "x /brag-",
          _old_normalize("x /brag-", NAMES))
    # ... and the old lint dropped /brag- from every count; reproduce that hole
    old_lint_name = lambda run: None if run.endswith("-") else run   # noqa: E731
    check("old lint booked no bucket for /brag-", None,
          old_lint_name("brag-"))
    check("new ledger books exactly one bucket for /brag-", 1,
          lint.audit("x /brag-", NAMES)[1]["name-continues"])
    # the lint itself refuses a bare token in a position
    check("lint refuses a bare line-start token", True,
          bool(lint.audit("/brag", NAMES)[0]))
    check("lint refuses a bare trigger field", True,
          bool(lint.audit("Trigger:/brag", NAMES)[0]))
    check("lint leaves a bare prose token and counts it",
          (0, {"position": 1}),
          (len(lint.audit("then run /brag", NAMES)[0]),
           {"position": lint.audit("then run /brag", NAMES)[1]["position"]}))
    # the pair check rejects a rewrite the matcher should not have made
    check("pair check rejects a rewritten path", True,
          bool(lint.check_change("[x](/brag)", "[x](/skill:brag)", NAMES)))
    check("pair check accepts a legal rewrite", [],
          lint.check_change("/brag and `/brag`", "/skill:brag and `/skill:brag`",
                            NAMES))
    check("pair check rejects a rewrite of prose", True,
          bool(lint.check_change("then run /brag", "then run /skill:brag", NAMES)))
    # and the two implementations agree on the whole live tree
    files = ss.skill_files()
    names = ss.skill_names(files)
    split = []
    for path in files:
        text = open(path, encoding="utf-8").read()
        for lineno, (old, new) in enumerate(
                zip(text.split("\n"), ss.normalize(text, names).split("\n")), 1):
            if old != new:
                for problem in lint.check_change(old, new, names):
                    split.append("%s:%d %s" % (path, lineno, problem))
    check("matcher and lint agree on every live line", [], split)


# --- 7. the tree baseline: first run no floor, then shrink only ------------
STATE_REL = os.path.join(".jcode", "state", "skills-activation.json")


def _state_path(home):
    return os.path.join(home, STATE_REL)


def test_baseline():
    tmp = tempfile.mkdtemp(prefix="baseline-")
    try:
        # 1. empty tree, no state file: no floor, exit 0, baseline recorded
        home = os.path.join(tmp, "empty")
        os.makedirs(home, exist_ok=True)
        r = _run(home)
        check("baseline/empty-tree-no-state exits 0", 0, r.returncode)
        state = json.load(open(_state_path(home), encoding="utf-8"))
        check("baseline/empty-tree records count 0", 0, state["count"])
        check("baseline/empty-tree is not a refusal", False, "REFUSED" in r.stderr)

        # 2. full tree, no state: no floor either, baseline 145
        home = os.path.join(tmp, "full")
        _fake_tree(home, 145)
        r = _run(home)
        check("baseline/full-tree-no-state exits 0", 0, r.returncode)
        state = json.load(open(_state_path(home), encoding="utf-8"))
        check("baseline/full-tree records count 145", 145, state["count"])
        first_fingerprint = state["fingerprint"]

        # 3. unchanged tree, state present: quiet 0, no warning
        r = _run(home)
        check("baseline/unchanged exits 0", 0, r.returncode)
        check("baseline/unchanged is quiet", "", r.stderr)

        # 4. the tree loses 20 files to a bug: refused, state untouched
        for i in range(20):
            shutil.rmtree(os.path.join(home, ".agents", "skills", "skill-%03d" % i))
        r = _run(home)
        check("baseline/shrink-by-20 exits 1", 1, r.returncode)
        check("baseline/shrink-by-20 says REFUSED", True, "REFUSED" in r.stderr)
        check("baseline/shrink-by-20 names both counts", True,
              "125 skill files found, 145 at the last successful run" in r.stderr)
        check("baseline/shrink-by-20 names the escape hatch", True,
              "--rebaseline" in r.stderr)
        check("baseline/shrink does not move the baseline", 145,
              json.load(open(_state_path(home), encoding="utf-8"))["count"])

        # 5. a deliberate removal is one warning, and the baseline follows
        r = _run(home, "--rebaseline")
        check("baseline/deliberate-shrink exits 0", 0, r.returncode)
        check("baseline/deliberate-shrink warns once", 1, r.stderr.count("WARN:"))
        check("baseline/deliberate-shrink re-baselines", 125,
              json.load(open(_state_path(home), encoding="utf-8"))["count"])
        r = _run(home)
        check("baseline/after rebaseline is quiet", (0, ""), (r.returncode, r.stderr))

        # 6. the tree comes back: one warning, exit 0, state updated. The
        #    restored cards are byte-identical to the ones recorded before the
        #    shrink, so only a real content change may move the fingerprint.
        _fake_tree(home, 20)
        r = _run(home)
        check("baseline/growth exits 0", 0, r.returncode)
        check("baseline/growth warns once", 1, r.stderr.count("WARN:"))
        state = json.load(open(_state_path(home), encoding="utf-8"))
        check("baseline/growth re-baselines", 145, state["count"])
        check("baseline/growth keeps the fingerprint for identical bytes",
              first_fingerprint, state["fingerprint"])
        _fake_tree(home, 1, {"skill-003": "# skill-003\n\nedited card\n"})
        r = _run(home)
        check("baseline/edited card exits 0", 0, r.returncode)
        check("baseline/edited card moves the fingerprint", True,
              json.load(open(_state_path(home), encoding="utf-8"))["fingerprint"]
              != first_fingerprint)

        # 7. a corrupt state file is no state, never a bricked sync
        with open(_state_path(home), "w", encoding="utf-8") as fh:
            fh.write("{not json")
        r = _run(home)
        check("baseline/corrupt-state exits 0", 0, r.returncode)
        check("baseline/corrupt-state is rewritten", 145,
              json.load(open(_state_path(home), encoding="utf-8"))["count"])

        # 8. dry-run reads the baseline but never writes one
        os.unlink(_state_path(home))
        r = _run(home, "--dry-run")
        check("baseline/dry-run exits 0", 0, r.returncode)
        check("baseline/dry-run writes no state", False,
              os.path.exists(_state_path(home)))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def _fake_tree(home, count, extra=None):
    skills = os.path.join(home, ".agents", "skills")
    os.makedirs(skills, exist_ok=True)
    for i in range(count):
        name = "skill-%03d" % i
        _write_card(skills, name, "# %s\n\nplain card\n" % name)
    for name, body in (extra or {}).items():
        _write_card(skills, name, body)
    return skills


def _write_card(skills, name, body):
    d = os.path.join(skills, name)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "SKILL.md"), "w", encoding="utf-8") as fh:
        fh.write(body)


def _run(home, *args):
    return subprocess.run(
        [sys.executable, TRANSFORM] + list(args),
        capture_output=True, text=True,
        env=dict(os.environ, HOME=home))


def main():
    test_table()
    test_bucket_ledger()
    test_positions_are_what_is_rewritten()
    test_card_shapes()
    test_prefixed_path_is_left()
    test_checks_can_fail()
    test_baseline()
    print("\n%d checks failed" % len(FAILS) if FAILS else "\nall checks passed")
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
