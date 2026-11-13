# it3 review D — blind antagonist

Read: `~/.agents/loop/it3-6.md` (file map only), `~/dotfiles/jcode/skill_slash.py`,
`skills-lint.py`, `skills-activation.py`, `~/dotfiles/jcode/update-all.sh`.
The author's reasoning was not read; every claim below was re-derived from the
code and from runs in `/tmp/ihrev`.

**VERDICT: REFUTED.** All three halves of the claim fail.
- Half 1, "no path is ever rewritten": FALSE — `cat "/brag"` is rewritten on disk.
- Half 2, "no live line names an installed skill bare": true for today's tree, but
  the mechanism leaves `|/brag|`, `**/brag**`, `run /brag!`, `Trigger:/brag` bare,
  so the guarantee does not survive a sync.
- Half 3, "every skipped token is counted with its reason": FALSE — the lint prints
  zero problems on a tree containing those bare tokens, path reasons are attached
  to tokens with no path, and `/brag-` is not counted at all.
- Point 4 (pipefail): CONFIRMED, exit 1 in all three option states.
- "Both syncs byte-identical": REFUTED for `README.md` and for a literally wiped tree.

## Sandbox

`/tmp/ihrev/t1`, `/tmp/ihrev/t2`: `HOME` with `/.agents/skills/<145 skill dirs>`.
`/tmp/ihrev/fake`: a copy of `~/dotfiles/jcode` + `agents/AGENTS.md` + `skills-overlay`
+ `.git`, with a 145-skill synthetic tree, so the *real* `update-all.sh` can run its
skills phase end to end; `HOME=/tmp/ihrev/pf` symlinks
`.jcode/updater-src -> /home/prm/.jcode/updater-src`. The real skills tree is 743 MB
and was not copied; the sync/transform code path is the same one.

## 1. A path is rewritten — REFUTED

Root cause: `skill_slash.py:149` — `words_before()` returns `[]` when the slash does
not directly follow a space or tab. A quoted path argument therefore loses its
command, rule 4 cannot fire, and the quoted path is rewritten. The docstring at
`skill_slash.py:143-147` states this as intended for `say "/brag"`, but it applies to
`cat`, `cd`, `rm` too.

```
$ python3 -c 'import importlib.util as u;s=u.spec_from_file_location("m","/home/prm/dotfiles/jcode/skill_slash.py");m=u.module_from_spec(s);s.loader.exec_module(m);print(repr(m.normalize("cat \"/brag\"\n",{"brag"})))'
cat "/skill:brag"\n
```
Same for `cat '/brag'`, `cd "/brag"`, `ls \`/brag\``. On disk, with exit 0:

```
$ HOME=/tmp/ihrev/t1 python3 ~/dotfiles/jcode/skills-activation.py
skills-activation: token ledger after: rewritten=2, path-suffix=2, ... violation=0
skills-activation: 145 skills scanned, 1 files changed, ... 0 path corruptions
EXIT=0
$ sed -n 1p /tmp/ihrev/t1/.agents/skills/brag/SKILL.md
cat "/skill:brag"
```
The write is not reported as a corruption, and the lint's `check_change()` accepts it
because the lint bails on the same quote (`skills-lint.py:108-115`, `_words_before`).
Both opinions share the defect.

Second, unlisted path commands (`skill_slash.py:118-121`, a closed set): `mkdir /brag`,
`touch /brag`, `vim /brag`, `python3 /brag`, `bash /brag`, `sort /brag`, `open /brag`,
`rsync --exclude /brag`, and the Windows form `dir /brag` are all rewritten to
`/skill:brag`. `skill_slash.py:177`.

What held: `/brag.md`, `/brag.sh`, `/brag/`, `/brag.d/x`, `/brag@2x.png`, `/brag?x`,
`/brag#x`, `~/brag`, `./brag`, `<output-dir>/brag.mp4`, `C:/Users/me/brag`,
`https://x.dev/brag`, `https://x.dev?u=/brag`, `map (/brag)`, `/brag..` are all
byte-identical. Live tree: 0 quoted-path-arg hits (`/tmp/ihrev/live4.py`), so no live
corruption yet.

## 2. A genuine command left bare — REFUTED

Opener is `skill_slash.py:99-107` (space, tab, quote, line start). Anything else in
front of the slash is invisible; any character after the name outside `END` is
invisible. Left bare, with zero problems reported:

```
|/brag|                 (markdown table cell, no padding)
**/brag**               (bold)
<kbd>/brag</kbd>        (HTML)
run /brag!              (trailing !)
should I run /brag?     (trailing ?)
run /brag…              (ellipsis)
Trigger:/brag           (trigger field, no space — `:` is a path char)
```
`| /brag |`, `` |`/brag`| ``, `# /brag`, `## /brag`, `> /brag`, `1. /brag`, tab cells,
fenced blocks and indented lines do rewrite. `Trigger:/brag` and `Triggers:/brag` are
left because `:` is in `PATH_CHARS` (`skill_slash.py:110-115`).

Live tree: no such form exists today (`/tmp/ihrev/live.py` finds 0 odd prefixes,
`live3.py` 0 odd tails). The claim is true of the tree, false of the transform that is
supposed to keep it true: the sandbox run exited 0 with `|/brag|` and `Trigger:/brag`
still on disk.

## 3. Counting — REFUTED

- Lint prints zero on a tree containing bare tokens: `lint.tree_assert("|/brag|", {"brag"})`
  and `lint.tree_assert("Trigger:/brag", {"brag"})` both return `[]` (exit 0 end to end,
  output in §1). Both land in `_left_reason()` (`skills-lint.py:138-146`) as
  `path-suffix` / `path-char`, so `VIOLATION_REASONS` never fires.
- Wrong reason: `|/brag|` contains no path but is booked `path-suffix`; `Trigger:/brag`
  contains no path but is booked `path-char`. The ledger's path buckets are therefore
  not evidence that a token was a path.
- Miscount: `x /brag-` is not counted at all — `_name_at()` rejects a trailing dash
  (`skills-lint.py:89`), `tokens()` drops it (`skills-lint.py:187`), and no reason
  bucket moves. Ledger before/after the t1 run: `path-suffix=2, path-char=1, violation=2`
  for six slash tokens; the sixth (`/brag-`) is in none.
- Matcher/lint divergence the other way: `/brag,:` is refused whole (`EXIT=1`,
  `REFUSED: 1 problem`) because `_end_ok()` recurses over separators
  (`skills-lint.py:100-101`) while the regex does not. Fail-closed, but it means the
  two "independent" opinions disagree on ordinary punctuation.

## 4. pipefail — CONFIRMED

`run_logged()` (`update-all.sh:94-109`) clears `pipefail` and `errexit`, reads
`PIPESTATUS[0]`, restores both. Forced failure of the piped step: append `/brag,:` to
`sandbox/brag/SKILL.md`, so `skills-activation.py` exits 1 under `tee`.

```
$ HOME=/tmp/ihrev/pf PYTHONPATH=... bash   /tmp/ihrev/fake/jcode/update-all.sh --skills-only ; echo $?
1        # "ERROR: a bare /<skill> activation survived"; checklist "fail: skill activation form"
$ HOME=/tmp/ihrev/pf PYTHONPATH=... bash -o pipefail  .../update-all.sh --skills-only ; echo $?
1
$ HOME=/tmp/ihrev/pf PYTHONPATH=... bash +o pipefail -c '...'                          ; echo $?
1
```
Only one decision pipeline bypasses `run_logged` — `update-all.sh:773`
`tail -1 "$LOG" | grep -q '^PASS'` — and it is fail-closed. So no failing piped step is
swallowed in this file.

## 5. Two syncs byte-identical — PARTLY REFUTED

Same tree, two real runs, hashes over every file under the skills dir:

```
$ ... update-all.sh --skills-only   # run 3, exit 0
$ ... update-all.sh --skills-only   # run 4, exit 0
$ cmp h3.txt h4.txt   # excludes README.md
BYTE-IDENTICAL
$ sha256sum .../skills/README.md    # includes "on <ISO timestamp>" line 3
```
`SKILL.md` bytes are stable (the sync re-introduces bare forms and the transform
rewrites them identically every run: "14 files changed, 44 references rewritten" on
each run). `README.md` is regenerated with the run time and differs between the two
syncs, so "post1 == post2 byte-identical" is false if the manifest is in scope.

A literally wiped tree does not reach two syncs at all:

```
$ rm -rf .../agents/.agents/skills/* ; ... update-all.sh --skills-only ; echo $?
skills-activation: REFUSED: 35 skill files found, floor is 140
1
```
`sync_skills()` (`update-all.sh:504-556`) reinstalls only the 35 upstream-family skills
(6 ponytail + 22 caveman + 5 tiger-style + herdr + babysit); the other ~93 dirs live in
the dotfiles repo, so the floor (`skills-activation.py:55`) refuses. "wipe -> sync ->
sync, both exit 0" holds only if the wipe is not a wipe of the skills directory.

## What I did not check

- The live 145-file tree for `cat "/name"` corruption: checked, 0 hits.
- Real `~/.agents/skills` copy: not made (743 MB); the sandbox tree is synthetic, and
  the sync step pulled `--ff-only` on the real `updater-src` (all "Already up to date").
- `overlay-lib.sh`'s import of `skill_slash.py` was not exercised; the transform path
  and the lint path were.
