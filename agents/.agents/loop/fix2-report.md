# FIX-2 revision 1 — merge duplicate skill families

Worker report. Every number is reproducible with the command shown.

## Verdict

| measure | before | after |
| --- | --- | --- |
| SKILL.md files | 132 | 126 |
| skills deleted | — | 6 (`caveman-review` `claude-handoff` `retro` `decision-ledger` `pr` `open-pr`) |
| skills un-hidden here | — | 2 (`ds-ledger` `ds-pr`) |
| catalog (auto-invocable) at the start of this ticket | 41 skills / 1458 words | — |
| raw words (all skills) | 4166 | 4254 |

**The gate moved while I was working.** `~/.agents/loop/fix1-count.py` was rewritten mid-run by the FIX-1 rev2 worker (mtime 12:05, alongside `fix1-rev2-apply.py`): pi turns out to have no catalog-wide description budget (`docs/skills.md:81`, `dist/core/skills.js:279` emits every visible skill), so the 1500-word target was withdrawn and the only enforced limit is **1024 characters per description**. That worker also un-hid the 57 skills rev1 had hidden, so the tree went from 41 catalog entries to 95 while I was merging. Both facts supersede the budget arithmetic later in this report; the merges themselves are unaffected.

The count that is now the acceptance command, run after every step:

```bash
python3 ~/.agents/loop/fix1-count.py
# skills total 126 | in catalog 95 | manual-only 31
# longest description: 606 chars | target: <=1024 chars each -> PASS | exit 0
bash ~/.agents/skills/flow/scripts/check.sh   # OK: flow rules and skill references valid, exit 0
```

Catalog entries went 41 → 95 only because rev2 removed the hiding; of the two entries I absorbed (`decision-ledger` into `ds-ledger`, `pr` into `ds-pr`) nothing was lost, because both survivors are reachable and each family now has one home.

## Evidence used to pick survivors

`flow/SKILL.md` pins the four review skills by name (Review phase + escalations), and the ticket's own verify requires every skill named there to still exist. That is why four review skills survive and only `caveman-review` folds. Reference counts below are real references from another skill body (word matches like "a rule learned earlier" were discarded; `ds-pr` inside `ds-pr-comments` was discarded):

| skill | real references | catalog? | body | stop condition |
| --- | --- | --- | --- | --- |
| `ds-review-loop` | flow, ds-help, ds-mode, ds-ship | yes | 481 w | `## Stop when` |
| `code-review` | flow, ask-matt, implement, implement-spec, tdd | yes | 1066 w | process + aggregate |
| `ponytail-review` | flow, ponytail-help | yes | 834 w | `Verdict:` line |
| `tiger-style-review` | flow, tiger-style-help | yes | 462 w | `Solid. Ship.` |
| `caveman-review` | caveman-help | **no** | 414 w | `## Boundaries` |
| `ds-lessons` | flow, ds-help | yes | 363 w | `## Stop when` |
| `retro` | ask-matt, chief-of-staff | **no** | 679 w | none |
| `ds-ledger` | ds-help, ds-blueprint, ds-mode | **no** | 313 w | `## Stop when` |
| `decision-ledger` | none | yes | 808 w | `## Depth` → done gate |
| `handoff` | ask-matt (3), archify, ds-adopt, ds-context-reset | **no** | 144 w | none |
| `claude-handoff` | none | **no** | 289 w | none |
| `ds-pr` | ds-adopt, ds-help, ds-revive, ds-ship, ds-watch-pr, ds-pr-comments | **no** | 326 w | `## Stop when` |
| `pr` | ask-matt | yes | 568 w | none |
| `open-pr` | workmux | **no** | 230 w | none |

## Family table

| family | survivor | deleted | folded into the survivor | evidence |
| --- | --- | --- | --- | --- |
| Review | `tiger-style-review` | `caveman-review` | New `## Comment voice`: severity prefixes `🔴 bug / 🟡 risk / 🔵 nit / ❓ q`, the drop list ("I noticed", hedging, praise per comment, restating the line), the keep list, and the auto-clarity rule (security finding, architecture disagreement, new author → full paragraph). Both skills already emitted the same `L<line>: <tag> <violation>. <fix>.` line. | `tiger-style-review` is named by `flow` and `tiger-style-help` and is in the catalog; `caveman-review` is hidden, named only by `caveman-help`, and shorter. |
| Memory / learning | `ds-lessons` | `retro` | New step 2 `Scan the environment, not the code`: navigation pointers, existing-but-unwired checks, the mechanical-vs-judgement split, steering-file no-ops, tool economy, missing information. New `## Where a fix lands` (AGENTS.md = pointers only, CODING_STANDARDS.md = judgement calls, docs/skills, `writing-for-agents`), plus retro's implementation-vs-review context-pressure rule. | `ds-lessons` is named by `flow` and `ds-help` and has a stop condition; `retro` is hidden. `ask-matt` (3 refs) and `chief-of-staff` now point at `ds-lessons`. |
| Memory / learning | `handoff` | `claude-handoff` | New `## Start the fresh agent`: the `pi -n "<name>" -p "$(cat <file>)"` launch, `--resume`, and "take another CLI's own flags from `--help`". This is exactly what the old `skills-overlay/claude-handoff.sh` patched in, so no knowledge is lost. | `handoff` has 6 real references incl. `ask-matt`'s `/handoff` bridge; `claude-handoff` had none. |
| Memory / learning | `ds-ledger` | `decision-ledger` | Whole skill becomes `## Mode B: an audited component`: depth ladder (skip/lite/full), phases 0-9, done gate ("done except: <list>"), the `### Never` list, and its `references/` (knob-classes, ledger-template, challenge-protocol) + `scripts/coverage_diff.py`, moved verbatim into `ds-ledger/`. The old body became `## Mode A: a coding run`. One `## Stop when` now covers both modes. | `ds-ledger` is named by `ds-help`, `ds-blueprint`, `ds-mode`; `decision-ledger` had 0 references. Both were "record every decision with a reason and evidence"; the split was a word, not a job. |
| PR | `ds-pr` | `pr`, `open-pr` | `pr`'s body template (`Summary` / `Evidence` / `Merge Danger`, door + blast radius, the "smallest view" menu, the closing `Created with <model> in <harness>.` line) is now `## Body template`; `open-pr`'s commit-first step, `git push -u origin HEAD`, 72-char title, and `gh pr create --web` fallback are now steps 2, 5 and the second `## Stop when` branch. `pr`'s old step-5 list was demoted to the template, `ds-pr`'s filing procedure kept. | `ds-pr` had 6 real references and a stop condition; `pr` had 1 (`ask-matt`), `open-pr` 1 (`workmux`). Both callers now say `/ds-pr`. |

### Kept, with the reason

| skill | reason it was not folded |
| --- | --- |
| `code-review`, `ds-review-loop`, `ponytail-review` | Different jobs, all three pinned by `flow`: the loop that converges, the standards+spec axes, the quality/lean judgement. Deleting one breaks the verify line "every skill named in flow/SKILL.md still exists". |
| `caveman-evidence-review` | It reviews Caveman Cloud cost, score and trace evidence, not code. Nothing overlaps a code review; folding it would put cost-telemetry steps inside a diff review. |
| `ds-context-reset` | `handoff` writes a portable file outside the workspace; this one commits `PROGRESS.md` in the repo and resets inside it. Opposite rules, so each now carries a one-line "Not this one" boundary instead. |
| `ds-catchup` | A read-only catch-up for the *user* plus the decisions only they can make; `handoff` is state for the *next agent*. |
| `caveman-learn`, `caveman-stats` | `caveman learn`/`mem`/`simulate` CLI cards: cost sinks and token reports. Neither learns from mistakes nor keeps a decision log. |
| `learned` | Misnamed: it is the dag/stagehand PR-pipeline playbook (worktrees, cargo gates, herdr, whiteboard), not a learning loop. Nothing in it belongs in `ds-lessons`. |
| `ds-watch-pr`, `ds-pr-comments` | Watching CI and posting attributed comments are separate procedures with their own scripts/stop conditions. |
| `grill-me`, `grill-with-docs`, `grilling` | The two one-line aliases are hidden from the catalog already, cost zero catalog words, and exist so the human's typed `/grill-me` keeps working. Merging them would save no budget and break a habit. |
| `implement`, `implement-spec` | Looked at; `implement` is the thin per-ticket entry `ask-matt` routes to, `implement-spec` is the subagent/task-graph run. Out of the three families this ticket names; left untouched rather than churned unasked. |

### Un-hide (step 4)

Both were flagged in `fix1-report.md` for budget, not design, and both are automatic now. The later rev2 pass un-hid everything rev1 had hidden, so the end state agrees with these two decisions rather than depending on them.

| skill | fix1 reason it was hidden | hidden-because-budget or by-design | justification for un-hiding |
| --- | --- | --- | --- |
| `ds-ledger` | "rare task the user names" | **budget** — "rare" is a frequency argument, not a safety one | It is now the only ledger skill, and its trigger ("keep a decision log", "audit this config change") is not a name a user would type. |
| `ds-pr` | "side effect: writes, commits, deploys or spawns" | **budget, by inconsistency** — `ds-ship` (which merges PRs) and `ds-ready` are both in the catalog | It is now the only skill that files a PR. A PR-filing capability the model cannot select is exactly the regression this ticket exists to undo. |

Every other survivor of a merged family is auto-invocable with no flag: `ds-lessons`, `ds-ledger`, `ds-pr`, `tiger-style-review`, `code-review`, `ds-review-loop`, `ponytail-review`, `ds-context-reset`, `ds-catchup`.

`handoff` is the one survivor still hidden, and it is **hidden by design, not by budget**: the flag is already present in the pre-FIX-1 tree (`/tmp/fix1-before2/handoff/SKILL.md`, extracted from `fix1-backup-skills.tar.gz`), so FIX-1 never added it, and `ask-matt` invokes it as `/handoff` deliberately. Left alone.

While the word budget was still live I also trimmed `ds-ledger` (42 → 30 words) and `ds-pr` (42 → 38) descriptions. Those trims are now unnecessary but harmless: both still name their triggers and both are under the 1024-character cap.

## Durability — read this before the next `update-all.sh`

`sync_skills()` in `~/.dotfiles/jcode/update-all.sh` copies upstream skill dirs over `~/.agents/skills` on every full run. So:

- **Durable:** every merge into a `bundled/manual` skill — `ds-lessons` + retro, `handoff` + claude-handoff, `ds-ledger` + decision-ledger, `ds-pr` + `pr` + `open-pr`, and the `ask-matt` / `workmux` / `chief-of-staff` / `ds-help` / `ds-context-reset` edits. These dirs have no upstream source.
- **Reverts on the next full skill sync:** `caveman-review` comes back (caveman registry glob), and the `tiger-style-review` and `caveman-help` edits are overwritten by `sync_dir`. Both are upstream-managed. The existing idiom for that is one overlay per skill in `~/dotfiles/skills-overlay/`; `claude-handoff.sh` and `caveman-review.sh` there are now the two files to change. `~/.dotfiles` is outside the files this ticket owns, so I did not touch it.
- Two stale overlays (`caveman-review.sh`, `claude-handoff.sh`) now target deleted skills, so `skills-audit.sh` exits 1 with `overlay not applied`. That is the only remaining audit finding. Fix: `rm ~/dotfiles/skills-overlay/{caveman-review,claude-handoff}.sh`.

I did remove the 20 symlinks those deletions broke (`~/.claude/skills`, `~/.pi/agent/skills`, `~/.autohand`, `~/.hermes`, `~/.minimax`, `~/.zcode`, `~/.commandcode` each linked the deleted dirs). `skills-audit.sh` now reports 2 findings, down from 31.

## README

Regenerated, not hand-edited, the way the file itself says:

```bash
~/.jcode/bin/update-all.sh --manifest-only   # "manifest written to ~/.agents/skills/README.md (126 skills)"
```

## Verification

```
python3 ~/.agents/loop/fix1-count.py        -> longest description 606 chars, <=1024 each PASS (exit 0)
bash ~/.agents/skills/flow/scripts/check.sh -> OK: flow rules and skill references valid (exit 0)
skills named in flow/SKILL.md and ds-help/SKILL.md -> all present (script above, "dangling names: none")
survivors: headings diffed against the pre-change tree -> none lost, except `ds-ledger`'s `## Steps`,
  renamed to `## Mode A: a coding run` (all six original steps kept verbatim under it)
YAML: all 126 frontmatters parse, name == dir, description <= 1024 chars -> no problems
folded content still present after the concurrent rev2 pass (it rewrites frontmatter of
  upstream-synced skills only): tiger-style-review 2/2 new sections, handoff 1/1,
  ds-lessons 2/2, ds-ledger Mode A+B + references/ + scripts/, ds-pr Body template + Stop when
```

`flow/rules.md` untouched. No `AGENTS.md` written. No `~/.pi/agent/extensions/` change. Pre-change tree: `~/.agents/loop/fix2-backup-skills.tar.gz` (`tar xzf ... -C /tmp` to compare).

One content loss to name: `decision-ledger/evals/evals.json` was not carried over. It is eval metadata keyed to the old skill name, not instructions.

## Files this ticket wrote

- `~/.agents/loop/fix2-report.md`, `~/.agents/loop/fix2-backup-skills.tar.gz`
- 6 dirs deleted, 13 `SKILL.md` bodies edited, 2 un-hidden, `README.md` regenerated
- 20 dangling harness symlinks removed

Concurrent worker: `~/.agents/loop/fix1-rev2-apply.py` rewrote frontmatter across this tree at ~12:05 UTC (un-hiding rev1's 57 flags, restoring upstream descriptions). Nothing here overwrote it and nothing of mine was overwritten; the two changes were re-verified together at the end.
