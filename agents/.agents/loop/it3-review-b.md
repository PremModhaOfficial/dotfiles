# IT3-3 blind antagonist review (round 3, second reviewer)

Read order: my own checks first (matcher constructions, refusal, independent grep,
F7), then `it3-review.md`, then `it3-3.md`. Read-only; nothing edited except this file.

## Verdict: REFUTED

Points 3 and 4 hold. Points 1 and 2 do not: the matcher still rewrites a class of
paths, the pre-write refusal cannot see that class (it exits 0 and writes), and the
check passes vacuously on a tree it cannot read. The `.mp4`/`.jpg` defect is
genuinely fixed; the *invariant* claimed around it is not.

## 1. Matcher still touches paths — REFUTED

`~/dotfiles/jcode/skill_slash.py:38-42`. The tail refuses only `[\w/-]` and
`.<alnum>`. Anything else glued to the name is accepted, so every one of these
changes (`/tmp/sst/probe.py`, `probe2.py`):

```
/brag@2x.png    -> /skill:brag@2x.png        (a file)
/brag?tab=readme-> /skill:brag?tab=readme    (root-relative URL)
/brag#install   -> /skill:brag#install       (root-relative URL)
/brag*          -> /skill:brag*              (glob)
/brag[0-9].png  -> /skill:brag[0-9].png      (glob)
/brag{x,y}      -> /skill:brag{x,y}          (brace glob)
/brag;param     -> /skill:brag;param         (path parameter)
/brag,x         -> /skill:brag,x             (path in a list)
"/brag"         -> "/skill:brag"             (quoted absolute path: their OWN
                                              fixture, skill_slash.py:116)
```

Safe, as claimed: `/brag/x`, `/brag.md`, `a/brag`, `./brag`, `~/brag`,
`https://h/brag`, `C:\brag`, `C:/brag`, `/brag/x` in a markdown link, `bragx`,
`/brag-x`, `</brag>`, `--root=/brag`, `dir=/brag`. Indented and fenced blocks
change, but those are not paths.

The docstring's justification (`skill_slash.py:10-15`, "a path can never match")
is about the character *before* the slash; the failing half is the character
*after* the name, which it never enumerates. `"` is allowed before the slash by
design, so a quoted absolute path is a rewrite target by construction.

## 2. The corruption check is not a refusal — REFUTED (two ways)

a. It shares the matcher's blind spot, so it is a tautology, not a guard.
`corrupt_paths` (`skill_slash.py:87-102`) flags only `before in PATH`, `/`,
`_`/`-`+alnum, alnum, `.`+alnum — exactly the shapes in `CASES`. Every construct in
§1 returns `corrupt_paths(...) == []`. Live proof, current files, `/tmp` tree:

```
python3 /tmp/rtest/cur/act.py
skills-activation: 2 skills scanned, 2 carried, 3 references rewritten,
                   0 bare left, 0 path corruptions
rc=0
cat tree/brag/SKILL.md -> see /skill:brag@2x.png and /skill:brag?tab=readme
```

Two paths destroyed, exit 0. The report's own "independent" grep
(`it3-3.md` §2, `[\w/.:~$<>=-]/skill:...`) omits `@ ? # * [ {` too, so it would
print 0 over that tree as well — the check was fitted to the matcher.

b. Restore-and-run, byte-identical: forcing the old unguarded `BARE` on a copy
(`/tmp/rtest/old/`) gives `SELF-CHECK FAIL ... -> '<output-dir>/skill:brag.mp4'`,
`rc=1`, `TREE BYTE-IDENTICAL` (sha256 before/after). But it exits 1 at
`skills-activation.py:43` — the *self-check*, before `corrupt_paths` is ever
consulted. The corrupt>0 branch (`:66`) has never been exercised by a live
corruption, which is why the tautology is invisible.

c. Vacuous pass, CONFIRMED:
`HOME=/tmp/vtest/emptyhome python3 skills-activation.py` →
`0 skills scanned, ... 0 path corruptions`, `rc=0`. Same with a chmod-000
skills tree. Nothing asserts a minimum file count, so "clean" and "saw nothing"
print identically. An unreadable *file* is loud (traceback, rc=1); an unreadable
*tree* is silent.

d. "Writes nothing" is false when a tree already holds a corruption
(`/tmp/rtest/mix/`): file A has a bare hit, file B a pre-existing
`/skill:wizard/<segment>` and no hit, so the pre-write counter is 0, A is
written, B is then flagged → `rc=1`, `TREE MODIFIED`. The pre-write scan at
`skills-activation.py:50-58` skips files without hits.

## 3. Zero corruptions — CONFIRMED

My own regex, written from the definition, over every `SKILL.md` path, not just the
deduped set: `162 paths` (128 in `~/.agents/skills` + 34 symlinked dirs in
`~/.pi/agent/skills`, both `~/.agents/skills` symlink dirs), `145` unique
realpaths, `bad: 0`. Also `bare left: 0`. Flagging rule: path char before the
slash, or after the name `/`, alnum, `_`/`-`+alnum, `.`+alnum, or any of
`@ % ? # * [ ] { }`. The 34 symlinked copies resolve to files already in the 128,
so the claim's "145 files" is the whole installed set.

`sed -n '130p;132p' ~/.agents/skills/brag/SKILL.md` → `<output-dir>/brag.mp4`,
`<output-dir>/brag.jpg` restored. `python3 dotfiles/jcode/skill_slash.py` → rc 0.

## 4. F7 settlement — CONFIRMED

One statement: `/home/prm/AGENTS.md:30-36`, "Which skills are editable, stated once
here: ... changes only through `/home/prm/dotfiles/skills-overlay/<skill>.sh` ...
every other skill under `/home/prm/.agents/skills/` ... edited at
`/home/prm/dotfiles/agents/.agents/skills/<skill>/` ... never in place."
Numbers check out: `wc -l < ~/.jcode/state/upstream-sources` = 35, `cut -f1 … |
grep -qx flow` → rc 1 (not sync-owned), so flow is in the editable set.

Pointers, same quoted phrase, no second definition:
`flow/SKILL.md:79-81` ("stated once ... in `/home/prm/AGENTS.md` — not restated
here") and `memory-harness-home.md:102-104`. Both restate in the same shape
(overlay / dotfiles path / ledger+app state never), nothing contradicts.

Residue, one word: `memory-harness-home.md:102` still says "Where this meets the
**ban on editing** `/home/prm/.agents/skills/`" — AGENTS.md no longer bans that
path, it bans editing it *in place*. Stale noun, not a competing rule.

## 5. The four earlier refutations

| # | earlier refutation | now |
| --- | --- | --- |
| F1 | `memory-harness-home.md:54-56` pinned dead `update-all.sh` ranges | **CLOSED**: cites `install_if_different` / `install_live_jcode_config` by name; no line pins left. Blocks verified at `update-all.sh:749-758, 735-744, 650-659` |
| F7 | authority file banned `~/.agents/skills` while two files carved out an exception | **CLOSED**: one statement, `AGENTS.md:30-36`; both pointer files name it and add nothing (§4) |
| F4 | report cited `AGENTS.md:63`, command is `:64` | **CLOSED/moot**: the file was restructured; the command is `AGENTS.md:41` |
| 6 | the transform rewrites a path (`<dir>/skill:brag.mp4`) | **PARTIALLY OPEN**: the `.mp4`/`.jpg` class is closed and the tree is clean (§3), but the stated invariant ("a path can never match") is still false (§1) and unguarded (§2a) |

Ledger `:69` still cites `AGENTS.md:61-67` for a different point — not one of the
four, unchecked here since the file was restructured.

## Bottom line

Tree: clean (0/145, my grep). Gates: they can pass without seeing the tree and
without seeing this class. Fix the tail (`(?![\w/-])(?!\.[A-Za-z0-9])` → refuse
`@ % ? # * [ {` too, or require `[\s.,;:!?)\]}]|$` after the name), add a
minimum-file-count assertion, and put `"/brag"` back in the safe list before
calling the invariant by construction.
