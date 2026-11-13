# FIX-1 revision 2 — undo rev1's hiding

rev1 was refuted (`fix1-review.md`): pi has no catalog-wide budget, so making 57 skills
invisible bought nothing and killed the triggers of 19 skills that readable files name.
This revision restores the pre-ticket state for the flags, keeps only the rewrites a sync
cannot undo, keeps the deletion, and replaces the 1500-word target with pi's actual rule
(`docs/skills.md:81`: a description is at most 1024 characters).

Reproduce every number below:

```bash
mkdir -p /tmp/fix1-before && tar xzf ~/.agents/loop/fix1-backup-skills.tar.gz -C /tmp/fix1-before
mkdir -p /tmp/fix1-rev1  && tar xzf ~/.agents/loop/fix1-rev2-backup-skills.tar.gz -C /tmp/fix1-rev1
python3 ~/.agents/loop/fix1-count.py
python3 ~/.agents/loop/fix1-rev2-apply.py            # idempotent: second run prints `updated: 0`
```

`fix1-rev2-backup-skills.tar.gz` is the tree as rev1 left it, taken before this revision
touched anything; `fix1-backup-skills.tar.gz` is the pre-ticket tree.

## Before / after

| measure | pre-ticket | rev1 (snapshot) | rev2 now |
| --- | --- | --- | --- |
| SKILL.md files installed | 133 | 126 | 126 |
| **visible (model-invocable)** | **99** | **41** | **95** |
| **hidden (`disable-model-invocation: true`)** | **34** | **85** | **31** |
| catalog words | 3937 | 1553 | 3554 |
| raw words (all descriptions) | 4948 | 4139 | 4254 |
| longest description | 746 chars | 527 chars | 606 chars |
| descriptions over 1024 chars | 0 | 0 | **0** |
| descriptions over 60 words | 17 | 2 | 6 |
| catalog characters | 25 410 | 9 635 | 22 816 |

Two caveats on the middle column: rev1's own report measured 1458 catalog words and 0
descriptions over 60 words at 11:57; by the time this revision started (12:05) other
tickets working the same tree had removed six skills (`caveman-review`, `claude-handoff`,
`open-pr`, `pr`, `retro`, `decision-ledger`). Those six deletions are **not** rev1's and
are not restored here. The 126/41/85 row is the honest "state rev2 inherited".

Words are informational only now — nothing gates on them (see §4).

## 1. Flags: 54 of rev1's 57 removed, 31 pre-existing kept

rev1 flagged 57; 54 are still installed (the other 3 belong to skills since deleted).
All 54 now have no `disable-model-invocation` line, and every skill that carried the flag
before the ticket still does. Check, over the 126 installed skills:

```
pre-ticket flagged, still installed: 31
flagged now: 31   identical set: True
pre-ticket flagged but deleted since: ['claude-handoff', 'open-pr', 'retro']
```

Frontmatter now differs from the pre-ticket tree for exactly 13 skills, and every one of
those 13 differences is accounted for:

```
frontmatter still differs from pre-ticket: ['ai-image-generation', 'archify', 'code-review',
 'ds-context-reset', 'ds-ledger', 'ds-lessons', 'ds-pr', 'feature-compare', 'ghostex-agents',
 'ghostex-cli', 'ghostex-help', 'ghostex-manage-beads', 'ghostex-visuals']
```

- 10 are this ticket's kept rewrites (§2).
- `ds-ledger`, `ds-lessons`, `ds-pr` were rewritten by another ticket on the same tree —
  not touched or reverted here.

`flow/scripts/check.sh` exits 0, so the flow ladder's named skills all resolve again.

## 2. Rewrites: 10 kept, 6 reverted, 1 moot

Of the 17 rewrites, 10 are on locally-owned skills (kept), 4 are on skills that
`update-all.sh:316` re-copies with `cp -R`, and 2 are on symlinks into app-managed
directories. The last two were reverted too: neither file is locally owned, so the next
install silently returns vendor text — the same failure mode as the `cp -R` sync, just a
different updater. That is a judgement call; say so if you want them kept instead.

| skill | owner | description |
| --- | --- | --- |
| `ai-image-generation` | local | 101 → 29 words (746 → 226 chars) — kept |
| `archify` | local | 103 → 30 (740 → 223) — kept |
| `code-review` | local | 68 → 40 (419 → 235) — kept |
| `ds-context-reset` | local | 61 → 39 (349 → 219) — kept |
| `feature-compare` | local | 78 → 35 (489 → 219) — kept |
| `ghostex-agents` | local | 123 → 34 (704 → 195) — kept |
| `ghostex-cli` | local | 78 → 26 (654 → 218) — kept |
| `ghostex-help` | local | 89 → 32 (534 → 194) — kept |
| `ghostex-manage-beads` | local | 71 → 30 (423 → 167) — kept |
| `ghostex-visuals` | local | 70 → 34 (411 → 210) — kept |
| `tiger-style` | `cp -R` sync | 79 → 79 (606 → 606) — **reverted to upstream** |
| `tiger-style-audit` | `cp -R` sync | 61 → 61 (422 → 422) — **reverted** |
| `tiger-style-review` | `cp -R` sync | 67 → 67 (521 → 521) — **reverted** |
| `ponytail-review` | `cp -R` sync | 63 → 63 (370 → 370) — **reverted** |
| `cua-driver` | symlink → `~/.cua-driver` | 70 → 70 (431 → 431) — **reverted** |
| `superwhisper` | symlink → app bundle | 72 → 72 (527 → 527) — **reverted** |
| `decision-ledger` | local | 89 → 89 — moot: dir deleted by another ticket (content merged into `ds-ledger`) |

The four `cp -R` skills are exactly the rewrites the reviewer predicted a sync would
overwrite; `babysit` (regenerated, not copied) carried only a flag, which is gone.
Reverts were byte-checked against the upstream fronts:

```
RESTORED-UPSTREAM: tiger-style
RESTORED-UPSTREAM: tiger-style-audit
RESTORED-UPSTREAM: tiger-style-review
RESTORED-UPSTREAM: ponytail-review
RESTORED-ORIGINAL: cua-driver
RESTORED-ORIGINAL: superwhisper
```

## 3. The deletion holds

`event-loop-orchestration` is named nowhere under `~/.agents/skills` except its own
survivor, so the deletion stands (the reviewer confirmed v1's body is a subset of v2's):

```
$ cd ~/.agents/skills && grep -rn "\bevent-loop-orchestration\b" . | grep -v v2-event-loop
(nothing)
$ grep -rn "event-loop-orchestration" README.md
125:| v2-event-loop-orchestration | bundled/manual | — |
```

The reviewer's stale-README point is already gone: README has 126 rows for 126 skill
directories, no `event-loop-orchestration` row, no missing or extra row. Nothing to do.

## 4. The 1500-word target is retired

pi caps only individual descriptions at 1024 characters; the renderer emits every visible
skill (`dist/core/skills.js:279`). The 1500 came from Claude Code's and Codex's listing
budgets, so `~/.agents/loop/fix1-count.py` now gates on the rule pi actually has:

- enforces: every description ≤ 1024 characters (hard, exit 1 otherwise)
- prints: skills, visible/manual split, catalog and raw word counts, longest description — no gate

`fix1-count.py` is outside the files this ticket owns (`~/.agents/skills/*/SKILL.md`,
`README.md`). It was the only place the retired target lived —
`grep -rn 1500 ~/.agents/skills` finds only unrelated code — so it was changed here;
revert that one file if the counter belongs to someone else.

## Visible / hidden now

**95 visible, 31 hidden.** Every hidden skill's flag predates this ticket: rev1's report
already said "34 skills already carried the flag before this ticket and were left alone",
and 31 of those 34 are still installed. Nothing was hidden for a budget, and nothing in
`flow/SKILL.md` or `flow/rules.md` names a hidden skill.

| hidden skill | reason | still named by a visible file |
| --- | --- | --- |
| `ask-matt` | pre-ticket flag, untouched | — |
| `chief-of-staff` | pre-ticket flag, untouched | — |
| `ghostex-agents` | pre-ticket flag, untouched | — |
| `ghostex-browser-use` | pre-ticket flag, untouched | `driving-t3-previews` |
| `ghostex-cli` | pre-ticket flag, untouched | — |
| `ghostex-computer-use` | pre-ticket flag, untouched | — |
| `ghostex-help` | pre-ticket flag, untouched | — |
| `ghostex-manage-beads` | pre-ticket flag, untouched | — |
| `ghostex-visuals` | pre-ticket flag, untouched | — |
| `grill-me` | pre-ticket flag, untouched | — |
| `grill-with-docs` | pre-ticket flag, untouched | — |
| `handoff` | pre-ticket flag, untouched | — |
| `i-have-adhd` | pre-ticket flag, untouched | — |
| `implement` | pre-ticket flag, untouched | — |
| `implement-spec` | pre-ticket flag, untouched | — |
| `improve-codebase-architecture` | pre-ticket flag, untouched | — |
| `loop-me` | pre-ticket flag, untouched | — |
| `megacave` | pre-ticket flag, untouched | `caveman`, `caveman-help` |
| `merge` | pre-ticket flag, untouched | — |
| `rebase` | pre-ticket flag, untouched | — |
| `setup-matt-pocock-skills` | pre-ticket flag, untouched | `code-review` |
| `teach` | pre-ticket flag, untouched | — |
| `to-questionnaire` | pre-ticket flag, untouched | — |
| `to-spec` | pre-ticket flag, untouched | — |
| `to-tickets` | pre-ticket flag, untouched | — |
| `triage` | pre-ticket flag, untouched | — |
| `ultracave` | pre-ticket flag, untouched | `caveman`, `caveman-help`, `cavecrew` |
| `wait-what` | pre-ticket flag, untouched | — |
| `wayfinder` | pre-ticket flag, untouched | — |
| `workmux` | pre-ticket flag, untouched | — |
| `worktree` | pre-ticket flag, untouched | — |

## Verification (run after the edits)

```
$ python3 ~/.agents/loop/fix1-count.py
skills total       : 126
in catalog (auto)  : 95
manual-only        : 31
CATALOG words      : 3554
raw words (all)    : 4254
longest description: 606 chars
target             : <=1024 chars each -> PASS
exit=0

$ bash ~/.agents/skills/flow/scripts/check.sh
note: EGM skills at /home/prm/.pi/agent/git/github.com/google/elephant-goldfish-model/skills
OK: flow rules and skill references valid
exit=0

$ python3 ~/.agents/loop/fix1-rev2-apply.py     # idempotent
updated: 0
exit=0
```

No visible description exceeds 1024 characters (single-line ones via `grep`/`awk`;
29 descriptions use YAML block scalars, so the python walk in `fix1-count.py` is the
authoritative check and covers all 126):

```
$ cd ~/.agents/skills
$ for f in $(grep -L '^disable-model-invocation:' */SKILL.md); do
    awk -v f="$f" '/^description:/{l=$0; sub(/^description:[[:space:]]*/,"",l);
      gsub(/^"|"$/,"",l); if (length(l)>1024) print "OVER", length(l), f}' "$f"; done
(no output)

$ python3 - <<'PY'   # authoritative: handles block scalars
...  # see fix1-count.py's description()
PY
visible skills: 95
visible descriptions over 1024 chars: []
longest visible: [(606, 'tiger-style'), (527, 'superwhisper'), (521, 'tiger-style-review')]
```

YAML: all 126 frontmatters parse with `yaml.safe_load`, every `name` equals its directory,
no description is empty, longest is 606 characters.

## What a re-sync would still break

- **Nothing this ticket wrote.** After the reverts no skill on the `cp -R` list carries an
  edited description, and none carries a rev2 flag — a sync can no longer undo a rewrite.
- **Pre-existing flags on synced skills.** `ultracave` and `megacave` are re-copied from
  `JuliusBrussee/caveman`, and their `disable-model-invocation` flags predate this ticket,
  so the next `update-all.sh --skills-only` drops the flags and both become visible. Not
  caused by rev1, not fixed here (their descriptions are 186/187 characters, so no cap breaks).
- **The three named skills kept hidden by item 1** still have dead pointers: `caveman` and
  `caveman-help` name `ultracave`/`megacave`, `cavecrew` names `ultracave`,
  `code-review` names `setup-matt-pocock-skills`, and `driving-t3-previews` names
  `ghostex-browser-use`. All four flags are pre-ticket, so rev2 leaves them as found.
- **Trigger losses in the 10 kept rewrites** (reviewer item 4) survive by instruction:
  `ai-image-generation` lost its 20 keywords, `ds-context-reset` lost two clauses,
  `ghostex-help` lost its natural-language triggers, `archify` lost its proactive clause.
  Both of the two trigger losses the reviewer named as product names — `cua-driver`'s "Cua"
  and `superwhisper`'s "push to talk" — are back, because those two files were reverted.

## Files this revision wrote

- `~/.agents/skills/*/SKILL.md` — 58 frontmatters (54 flags removed, 6 descriptions
  reverted, 2 of which also had a flag); no body touched.
- `~/.agents/loop/fix1-rev2-apply.py` — the change, idempotent.
- `~/.agents/loop/fix1-rev2-backup-skills.tar.gz` — the rev1 tree, for a revert of this revert.
- `~/.agents/loop/fix1-count.py` — 1500-word gate replaced by the 1024-character gate.
- `~/.agents/loop/fix1-rev2.md` — this file.

No `AGENTS.md` opened for writing; `update-all.sh` untouched; no git commit.
