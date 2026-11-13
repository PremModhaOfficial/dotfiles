# IT3-4 blind antagonist review, round 3 attempt 3 (third reviewer)

Read order: my own checks first (five points below), then `it3-4.md`, then
`it3-review.md` / `it3-review-b.md` for point 5. Read-only on the tree; the only
file I wrote is this one. Nothing in `~/.agents` or `~/dotfiles` was edited, no
sync was run (`--skills-only` copies into live skills, out of bounds for a
read-only review).

## Verdict: REFUTED — narrowly, on points 1 and 4

Four of the five headline claims hold as stated: the grammar is positive and
anchored, the lint shares no code with it, the floor refuses, the whole tree is
read before the first write, all 26 table rows were predicted and match, and the
transform's pipe no longer swallows its exit. The live tree is clean by my own
grep too (0 rewritten paths, 0 bare activations in 145 loadable cards).

What does not hold:

1. There **is** a line both grammars accept that a reader calls a path, and it is
   not the admitted `cd /brag`. `[x](/brag)` — a root-relative link target — is
   invisible to the writer's `scan()` (opener `(`) *and* to the lint's
   `tree_assert()` (it only inspects tokens it already rewrote), so a tree
   containing `(/brag)` exits **0**, writes, and prints **`0 bare left`**.
   `it3-4.md` §7 item 2 says the failure mode is "a bare token → exit 1". It is
   exit 0. The claim "0 bare left" is therefore a statement about the same blind
   spot the writer has, not about the tree.
2. The other `| tee` call sites in `update-all.sh` are the same swallow shape as
   the one that was fixed (`python3 … | tee -a "$LOG" || rc=1`, `update-all.sh:521-522`).
   They are correct *only* because `pipefail` is inherited from `main`; they carry
   no `PIPESTATUS`. Demonstrated: with `pipefail` off they report success for a
   failing step. The fix is real for the transform and latent-swallow for the cap.

Nothing here is a live corruption: every gap-shaped line I searched for is absent
from the installed tree (point 4). The two refuted items are about what the report
says the code does when such a line appears.

## 1. A tree both accept while a reader reads a path — REFUTED

One command (both modules, real files, `NAMES={"brag"}`, brag is installed):

```
cd ~/dotfiles/jcode && python3 - <<'PY'
import importlib.util as u
def L(n,f): s=u.spec_from_file_location(n,f);m=u.module_from_spec(s);s.loader.exec_module(m);return m
ss=L("ss","skill_slash.py"); lint=L("sl","skills-lint.py"); N={"brag"}
for line in ("cd /brag","rm -rf /brag","[run](/brag)","see (/brag)","| /brag | x |"):
    new=ss.normalize(line,N)
    print("%-16r writer-> %-20r lint-> %-20r tree_assert(new)=%s scan=%s"
          %(line,new,lint.expect_line(line,N),lint.tree_assert(new),ss.scan(line,N)))
PY
```

Actual:

```
'cd /brag'       writer-> 'cd /skill:brag'   lint-> 'cd /skill:brag'   tree_assert(new)=[] scan=[(1,'brag')]
'rm -rf /brag'   writer-> 'rm -rf /skill:brag' lint-> same             tree_assert(new)=[] scan=[(1,'brag')]
'[run](/brag)'   writer-> '[run](/brag)'     lint-> '[run](/brag)'     tree_assert(new)=[] scan=[]
'see (/brag)'    writer-> 'see (/brag)'      lint-> 'see (/brag)'      tree_assert(new)=[] scan=[]
'| /brag | x |'  writer-> '| /skill:brag | x |' lint-> same            tree_assert(new)=[] scan=[(1,'brag')]
```

Both accept a rewrite of a shell path (`cd /brag` → `/skill:brag`, a directory
that cannot exist) and both accept, silently, a root-relative link target. The
pair is not independent where it matters: `check_change` is only called on lines
the writer already changed, and `tree_assert` skips every token whose `rewritten`
flag is false — so neither can see a `/name` the matcher declined to look at. The
justification in `it3-4.md` §1 ("There is no 'is this a path?' test left anywhere,
so there is nothing left to share a blind spot with") is wrong: the shared blind
spot moved from a path test to the opener rule.

End-to-end, the silent pass is not hypothetical. A 145-file tree with all cards
already `/skill:`-prefixed plus one line `See [the route](/s001) and (also /s002).`:

```
HOME=/tmp/gap python3 ~/dotfiles/jcode/skills-activation.py
skills-activation: 145 skills scanned, 1 carried a bare activation, 1 references
rewritten to /skill:<name>, 0 bare left, 0 path corruptions     EXIT=0
```

It wrote (md5 of the tree changed), it left `[the route](/s001)` untouched, and it
reported `0 bare left`. `it3-4.md` §7 item 2 predicts exit 1 for exactly this
shape. That prediction is false.

## 2. The pipe fix — CONFIRMED for the transform, same swallow latent elsewhere

Forced refusal, calling the real function from the real file, in the context the
real updater gives a phase (`APPLY || rc=1`, `set -uo pipefail`), `python3`
shadowed on `PATH` by a script that exits 1:

```
printf '#!/bin/sh\necho "FAKE TRANSFORM: refusing" >&2\nexit 1\n' > /tmp/stub/python3; chmod +x /tmp/stub/python3
env -i PATH=/tmp/stub:/usr/bin:/bin HOME=/home/prm bash -c 'set -euo pipefail; \
  source /home/prm/dotfiles/jcode/update-all.sh; LOG=/tmp/lg1/x.log; \
  CHECKLIST_TMP=/tmp/pa.tsv; DOTFILES=/home/prm/dotfiles; : >$LOG; : >$CHECKLIST_TMP; \
  rc=0; apply_skill_activation || rc=1; echo "FUNC_RC=$rc"'; cat /tmp/pa.tsv
```

Actual: `FUNC_RC=1`, checklist row `fail  skill activation form`, and — because
`update_skills` is `apply_skill_activation || rc=1` inside `run_jobs` — the phase
fails, `grep -q '^fail'` makes `main` return 1, so update-all exits 1. Also driven
with a real, unforced refusal (whole-tree corruption in the fixture):

```
env -i PATH=/usr/bin:/bin HOME=/tmp/badhome bash -c '… apply_skill_activation || rc=1 …'
ERROR /tmp/badhome/.agents/skills/s001/SKILL.md: line 6: /skill:brag preceded by path character 'x'
skills-activation: REFUSED: 1 problem(s) in the whole-tree scan; nothing written
FUNC_RC=1
```

So a lint disagreement or a tree corruption reaches update-all's exit status. Two
notes: (a) `PIPESTATUS` is not the mechanism that saves it — `pipefail` on that
pipeline already fails; `-e` is suppressed there by the `|| rc=1` call context, so
`PIPESTATUS` is the belt, `pipefail` the braces. (b) On any refusal the log still
says `ERROR: a bare /<skill> activation survived`, which is the wrong diagnosis for
a whole-tree refusal (nothing was bare). Cosmetic, but it is what a human reads.

Other piped calls, `grep -n 'tee' update-all.sh`, run both ways with a `python3`
that exits 1:

```
set -uo pipefail  … apply_skill_cap || rc=1   ->  CAP_RC=1   (correct share of pipefail)
set +o pipefail   … apply_skill_cap || rc=1   ->  CAP_RC=0   (swallows, no PIPESTATUS)
```

`update-all.sh:521-522` are byte-for-byte the defect that was just fixed
(`command | tee || rc=1`), and `:547`,`:570`,`:573` (`if … | tee …`) are the same
class. All are correct today only because `main` sets `pipefail` and nothing
clears it (`grep -n 'set +\|set -o'` → only `:176`, `:931`). There is no local
guard on any of them; the transform is the only one with `PIPESTATUS`.

## 3. Floor and pre-scan — CONFIRMED

```
cd /tmp && rm -rf f3 && mkdir -p f3/.agents/skills/{aaa,bbb,ccc} && for s in aaa bbb ccc; do \
  printf -- '---\nname: %s\ndescription: x\n---\ninvoke /%s now\n' $s $s > f3/.agents/skills/$s/SKILL.md; done
HOME=/tmp/f3 python3 ~/dotfiles/jcode/skills-activation.py; echo EXIT=$?; grep -h 'invoke' f3/.agents/skills/*/SKILL.md
```

`REFUSED: 3 skill files found, floor is 140` / `EXIT=2` / the three cards are still
`invoke /aaa now` (nothing written). Boundaries: 139 files → `EXIT=2`, 145 → runs.
Unreadable file inside a full tree (`chmod 000` on one of 145, md5 of all
`SKILL.md` before and after): `PermissionError` traceback, `EXIT=1`, md5 identical
— refused, nothing written, but loud as a traceback rather than the `REFUSED` text.
Both orderings are right: the floor is checked before any read, and every write is
after the whole-tree scan, so the mixed-tree half-write of round 2 is gone.

## 4. The two admitted gaps in the live tree — absent, but one is misdescribed

```
rg -n --no-heading '\(/[a-z][a-z0-9-]*\)|cd /[a-z][a-z0-9-]*' ~/.agents/skills ~/.pi/agent/skills
python3 - <<'PY'   # restricted to installed skill names, over both roots
…
PY
162 files; gap-shaped lines with a real skill name: 0
```

- `cd /brag` (and `rm -rf /brag`, `man /brag`): **0 occurrences**. The only `cd /`
  in the tree is `docker-agent-command-code/SKILL.md:44` → `cd /tmp/docker-agent-cc`,
  where `/tmp` is not an installed name. If it ever appeared, both the writer and
  the lint would rewrite it to `cd /skill:brag` and report clean — a reader
  following the line would look for a directory that cannot exist. Real risk,
  currently unpopulated.
- `(/brag)`: **0 occurrences**. The report's stated failure mode ("bare token →
  exit 1") is wrong; the actual behaviour is exit 0 with `0 bare left` (§1). A
  reader *is* misled by that class: `[x](/brag)` is how a card links to a page,
  and the run calls the tree clean while leaving it.

## 5. The earlier refutations

| # | earlier refutation | now |
|---|---|---|
| F1 | `memory-harness-home.md` pinned dead `update-all.sh` line ranges | **CLOSED**: `rg 'update-all\.sh:[0-9]'` → no hits; the file names its blocks instead |
| F7 | authority file banned `~/.agents/skills` while two files carved an exception | **CLOSED**: `~/AGENTS.md:30-37` states it once (sync-owned → overlay, else committed dotfiles source), and both pointers name that statement |
| F4 | report cited `AGENTS.md:63`, command is `:64` | **CLOSED/moot**: restructured, the block now sits at `:30-37` |
| 6 | the transform rewrites a path (`<dir>/skill:brag.mp4`) | **CLOSED for the tree, NOT closed as an invariant**: `brag/SKILL.md:130,132` are back to `<output-dir>/brag.mp4` / `.jpg` and the 26-row table refuses `@?#*[{;` and `/`; but §1 shows the pair still agrees on a path-shaped line, and `cd /brag` is a rewrite, not a refusal |
| 5 | proof command was vacuous (`reference/types/*` vs `references/`) | outside this ticket's scope, not re-checked |
| 1 | `ponytail-help` line numbers | not re-checked (brag/ponytail card line drift, unrelated to the transform) |

Two new, minor, not refutations: `skills-lint.py` and `skills-activation.test.py`
are **untracked** in `~/dotfiles` (`git status` shows `??`), so the second opinion
that the run depends on does not survive a clone or a stash — losing it makes
`_load` raise, which is the safe direction, but the file is not durable yet. And
`_load()` writes `__pycache__/*.pyc` into the tracked `dotfiles/jcode` directory on
every run, so "nothing written" means nothing but bytecode.

## Bottom line

The transform is safe on this tree and the four mechanical claims are true; the
floor, the pre-scan, the refusal and the exit-status wiring all hold under forced
failure. What is left is not a bug in the live tree but two statements in
`it3-4.md` that outrun the code: "0 bare left" is not a statement about the tree
(it shares the writer's opener blind spot), and `(/brag)`'s failure mode is a
silent exit 0, not exit 1. Point 2's remaining `| tee` sites are the same swallow
shape, saved only by an inherited shell option. Fix: make `tree_assert` also flag
unrewritten `/name` tokens in link-target position (or have `scan()` count them as
bare), give the cap lines `PIPESTATUS` too, and correct §7 item 2.
