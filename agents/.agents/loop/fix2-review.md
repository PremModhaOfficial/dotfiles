# FIX-2 rev1 — antagonist review

**VERDICT: PARTLY REFUTED.** The counts, gate, README and symlink claims hold. The
"nothing was lost" claim does not: `decision-ledger` and `pr` both lost real content,
one merge introduced a self-contradiction, one attribution file was deleted, and the
command the human ran today no longer exists. No step is unrecoverable; three are
worth a rev2.

## 0. Claims re-checked by running them

| claim | evidence | result |
| --- | --- | --- |
| 132 → 126 | backup `find … -name SKILL.md` = 130 dirs + 2 symlinked (`cua-driver`, `superwhisper`) = 132; live = 124 + 2 = 126 | HOLDS |
| check.sh exit 0 | `bash flow/scripts/check.sh` → `OK: flow rules and skill references valid`, exit 0 | HOLDS |
| longest description 606 | `python3 loop/fix1-count.py` → `longest description: 606 chars … PASS`, exit 0 | HOLDS |
| README regenerated | 126 skill rows, header says `update-all.sh --manifest-only`; no deleted name appears | HOLDS |
| 20 dangling symlinks pruned | 7 harness dirs, 0 dangling links left; all 34 `~/.pi/agent/skills` links resolve to a dir with `SKILL.md` | HOLDS (see §4) |
| survivors absorbed everything | see §1 | **REFUTED** |

## 1. Per-pair content diff

### 1a. `decision-ledger` → `ds-ledger` Mode B — REFUTED as a superset

Mode B is otherwise near-verbatim (all 10 phases, both ledgers, the `### Never` list, the
done gate, `ASSUMES`/`VERIFIED`/`GAPS` tags). Four things did not survive:

1. **Lite depth was changed, and the change is inconsistent.**
   Deleted: `Lite (reversible, one component, no security/data impact): Phases 1, 3, 8`.
   Now: `**Lite** …: phases 0, 1, 8` (`ds-ledger/SKILL.md:33`). Phase 3 is *build both
   ledgers*; the same line still promises `the gate returns both ledgers and open
   items`. Lite now asks for a gate over ledgers it was told not to build, and drops
   the two prompts that produce the audit's content. Either a typo or an unstated
   decision — it is not a superset either way.
2. **Phase 9 lost its second half.** Deleted: `Installed skills are usually read-only, so
   hand the entry to the user unless you have a writable copy or memory tool. If the
   cause was a process gap, propose the one-line change to this file.` The miss-log
   entry survives; the rule that closes the loop (hand it over, propose the process fix)
   does not.
3. **The description lost both auto-fire triggers.** Deleted: `Use on such a task, even
   when the user never asks, and when they report something missed.` Now: `Use for
   multi-phase or autonomous work, or /ds-ledger.` "Even when the user never asks" was
   the sentence that made the skill fire uninvited on a config change; it is now opt-in
   unless the model infers it.
4. **Phase 6 lost its worked examples**: `(update overwrites config, not enabled at boot,
   no recovery path)` and `a reviewer who wants them to fail`. Kept: the pre-mortem and
   deletion test themselves.

Also: `decision-ledger/evals/evals.json` (4 evals: fprintd, sshd, systemd, and the
"rename a variable does not run Full" negative case) is gone and now orphaned — the
report discloses the drop but those are the only behavioural tests this family has.

**References and scripts: intact and byte-identical.** `references/challenge-protocol.md`,
`references/knob-classes.md`, `references/ledger-template.md`, `scripts/coverage_diff.py`
all `diff` clean against the deleted originals. Phase 2's
`python <this-skill-dir>/scripts/coverage_diff.py --ledger … --source …` therefore still
resolves. That part of the claim is true.

### 1b. `pr` → `ds-pr` — REFUTED as a superset (attribution is the real loss)

Kept: the whole body template verbatim, the visual menu (compressed to seven bullets
from eight fenced examples), placement guidance, S-tier/A-tier evidence framing,
one-way/two-way door, blast radius, `GLOSSARY.md`.

Lost:
1. **`pr/CREDITS.md` was deleted and nothing in `ds-pr` replaces it.** It said the
   Summary-section menu comes from `show-me` (Dex Horthy, Humanlayer) *"reproduced almost
   word for word"*, plus `pr`'s frontmatter `metadata.credits` block naming that skill,
   author, org and URL. `ds-pr` reproduces the template and the menu and carries neither.
   The tree already has the convention for this (`archify/THIRD_PARTY_NOTICES.md`).
   `find ds-pr -type f` → `ds-pr/SKILL.md` only.
2. The eight worked examples (`on(save)` pseudocode, `submitForm` call tree,
   `<SessionPage>` component tree, `src/` file tree, the Mermaid sequence, three `diff`
   shapes, the TS block) are now `- pseudocode, for logic or an algorithm`-style bullets.
   The taxonomy survives; the teaching material does not. Defensible trim, but the report
   calls it "nothing lost".

### 1c. `open-pr` → `ds-pr` — two genuine losses, one deliberate inversion

Lost: `Get commit messages: git log <base>...HEAD --format="%s"`, `Read changed files to
understand the broader context`, and the guideline `Use the conversation context to
inform the description` — the last one is how a browser-opened body learned the *why*.
`ds-pr` step 3 diffs the branch and never reads commits or the conversation.
Inverted on purpose: `open-pr` said `Open PR creation in browser (do NOT create
directly)`; `ds-pr` creates directly and keeps `--web` as the last-resort fallback. Fine,
but it is a behaviour change, not an absorption, and the report reads as if it were one.

### 1d. `retro` → `ds-lessons` — PARTIAL, one behaviour change

Kept: primary-source reading with a session default, all seven scan categories with their
triggers, implementation-vs-review context pressure, AGENTS.md / CODING_STANDARDS.md /
docs / skills placement, `writing-for-agents`.

Lost:
1. **`Present these candidates to the user, in order of severity.`** This is the
   read-only guarantee. `retro` was `disable-model-invocation: true` and ended by
   *reporting*; `ds-lessons` step 3 says `Fix the most frequent classes now, one commit
   each` and has no report-only branch. A `/retro` invocation now edits the repo. That is
   the largest single behaviour change in the six merges.
2. `Add navigation pointers to docs folders if the standards file gets more than 1,000
   lines long.` — the only numeric threshold in the file.
3. `Look for existing docs before writing new ones.` — directly anti-duplication, and
   `ds-lessons` is the skill that decides where a fix lands.
4. The trigger `_Use when_ the AGENTS.md file is particularly large — in the repo OR the
   user's global scope` (the global half is what makes it fire on `~/.agents`).

### 1e. `caveman-review` → `tiger-style-review` `## Comment voice` — PARTIAL, smallest

Kept: the `L<line>: <tag> <violation>. <fix>.` format both already shared, all four
severity prefixes, the drop list, the keep list, auto-clarity, the revert clause.
Lost (cosmetic, no rule/stop-condition/table/script): the semantics of each prefix
(`works but fragile (race, missing null check, swallowed error)`), the
`"This is just a suggestion but..." — use nit: instead` substitution, the three ❌/✅
before-and-after rewrites, and Boundaries' `does not approve/request-changes, does not run
linters` + `ready to paste into the PR`.

### 1f. `claude-handoff` → `handoff` — HOLDS, true superset

Every instruction, the `pi -n … -p "$(cat …)"` launch, the `-p` rationale, `--resume`,
the `-n` naming rule, the other-CLI `--help` rule, suggested-skills, no-duplication and
redaction are all present in `handoff/SKILL.md`. Only change: the launch went from
mandatory to `## Start the fresh agent (optional)`. Nothing lost.

## 2. `decision-ledger`, the skill invoked today

**Method: kept, with the holes in §1a.** Phases 0–9, the depth ladder, the tags, the
done gate (`done except: <list>`), the `### Never` list and the miss log are all in
`ds-ledger`. Coverage: 4/4 reference and script files present and byte-identical, so
`references/challenge-protocol.md`, `knob-classes.md`, `ledger-template.md` and
`scripts/coverage_diff.py` all resolve.

**Invocation path: dead.** `/decision-ledger` matched no skill before this review; no
alias exists and `ds-help` never named the old skill, so nothing redirects. `ds-ledger`'s
description does not contain the word `decision-ledger` either — a model reading
`/decision-ledger` sees an unknown command, and a model *choosing* a skill no longer sees
"even when the user never asks".

**Alias: warranted, and by the worker's own rule.** This report's own "Kept, with the
reason" table justifies keeping `grill-me`/`grill-with-docs` because *"they exist so the
human's typed `/grill-me` keeps working… merging them would save no budget and break a
habit."* `grill-me/SKILL.md` is exactly the 6-line alias in question:

```markdown
---
name: grill-me
description: A relentless interview to sharpen a plan or design.
disable-model-invocation: true
---

Call the Skill tool with "grilling".
```

The same shape for `decision-ledger` (description: *Audit a component's decision points;
see ds-ledger Mode B.*, body: `Call the Skill tool with "ds-ledger" and use Mode B.`) fixes
the only user-visible regression, costs one hidden skill and no catalog words. It makes
the count 127, so the ticket's headline number needs restating either way — say 127 with
one documented alias, not 126 with a dead command.

## 3. Dead pointers (file:line)

| file:line | text | severity |
| --- | --- | --- |
| `skills/caveman-help/README.md:28` | `/caveman-review       one-line PR comments` listed as a live command | real: a printed cheat sheet advertises a command that errors |
| `skills/caveman-help/SKILL.md:28` | `(caveman-review merged here)` | will be false after the next sync restores the skill; reads as a broken promise |
| `skills/ds-ledger/references/knob-classes.md:28` | `decision-ledger skill v5 \| missed: …` in the miss-log example | low: historical example, but it names a skill that no longer exists inside the merged skill's own reference |
| `~/.agents/.skill-lock.json:373-377` | `"claude-handoff": { … "skillPath": "skills/in-progress/claude-handoff/SKILL.md" }` | low: lock entry for a deleted skill |
| `~/dotfiles/skills-overlay/caveman-review.sh`, `claude-handoff.sh` | both target deleted dirs | **confirms the report**: `skills-audit.sh` exit 1, `overlay not applied: caveman-review` / `claude-handoff`, `AUDIT-TOTAL: 2` |

Clean: `flow/SKILL.md`, `ds-help/SKILL.md`, `ds-mode`, `ask-matt` (now `/ds-pr`,
`/ds-lessons`), `chief-of-staff` (`**Retro** (../ds-lessons/SKILL.md)`), `workmux`
(`/ds-pr`), `~/.agents/AGENTS.md`, `~/.agents/references/`, `~/.pi/agent/AGENTS.md`,
`~/.pi/agent/extensions/`. No surviving mention of `retro`, `pr`, `open-pr` or
`claude-handoff` as a command anywhere in the tree.

## 4. Symlinks

- Dangling count across `~/.pi/agent/skills` (34), `~/.claude/skills` (97),
  `~/.commandcode/skills` (200), `~/.hermes/skills` (51), `~/.zcode/skills` (49),
  `~/.minimax/skills` (33), `~/.autohand/skills` (43): **0** in every dir.
- Every one of the 34 pi links resolves to a directory containing `SKILL.md`.
- **Cannot be proven positively** that no pruned link pointed at real content: no
  inventory of the pre-prune link set exists (`~/dotfiles` tracks `pi/agent/models.json`
  and extensions, not `pi/agent/skills`), so a wrongly-pruned *live* skill would show up
  only as an absent link, never as a dangling one. The evidence is negative-only: all six
  deleted targets are gone, and every surviving link still resolves.
- **Durability:** `caveman-review` is source `JuliusBrussee/caveman` in the regenerated
  README, and `sync_skills()` iterates `caveman/skills/*/SKILL.md`. The next full
  `update-all.sh` recreates the dir → the tree goes back to 127 skills with the
  duplicate restored, and the stale overlay then re-applies without complaint. 126 is
  not a stable state; only a committed overlay (or an upstream delete) makes it one.

## 5. Survivor choice: are the five review skills five jobs?

`caveman-evidence-review` is a different animal (Caveman Cloud cost/trace telemetry,
read-only operator). Keep.

The other four **duplicate their output contract four times**: the
`L<line>: <tag/violation>. <fix>.` one-line-per-finding shape plus a closing verdict
line now appears in `tiger-style-review` (`## Format`, `## Scoring`), `ponytail-review`
(`## 4. Output`, `Verdict:`), `code-review` (`## 5. Aggregate`) and, by absorption,
one more time inside `tiger-style-review` for `caveman-review`. That contract has one
home — the smallest skill in the family — which is backwards.

They are distinct as *methods*: `code-review` = two named axes with parallel subagents
and an aggregation step; `ds-review-loop` = a convergence loop with rounds, a reviewer
choice and a stop condition; `ponytail-review` = a judgement ordering that reads the
connected code, not just the diff; `tiger-style-review` = a tag taxonomy and nothing else
(no procedure, no axes, no loop). They are not distinct as *jobs*: all four judge one
diff and emit the same line format.

Decisive evidence that the boundary is not self-evident: the worker had to write 12
reciprocal "Not this one" clauses across 4 files (each names the other three). Four
skills that each need a map of the other three are one family that was sharded, not four
jobs. Worse, the default path is incoherent: `flow`'s Review phase is `ds-review-loop`,
which says *who* reviews and *when to stop* but never *what to look for* — so the default
reviewer must import `ponytail-review`'s rubric anyway (or invent one).

Next merge, if one is wanted: `ds-review-loop` + `ponytail-review` → one `review` skill
(loop + rubric + one stop condition), and `tiger-style-review`'s tag list → a shared
`flow/references/review-format.md` that the remaining reviews cite. That is 5 → 3 with no
loss of a method.

**Memory family** (`ds-lessons`, `ds-ledger`, `handoff`, `ds-context-reset`,
`ds-catchup`): `ds-lessons` (environment learning), `ds-ledger` (audit trail) and
`ds-catchup` (read-only, user-facing) are three jobs. `handoff` and `ds-context-reset`
are **one job** — write state to a file so a fresh context continues — differing only in
destination (temp dir vs `PROGRESS.md` in the repo) and whether it is committed. Each now
carries a "Not this one" naming the other, added by this worker: that is the tell. Next
merge: `handoff` + `ds-context-reset` → one skill branching on destination, 5 → 4.
`ds-ledger` Mode A is a third instance of "state in a file, not the chat", but its audit
columns earn it separate standing.

## 6. What rev2 should do, in order

1. Restore attribution: `ds-pr/CREDITS.md` from `pr/CREDITS.md` (and the
   `metadata.credits` block, or one line in the body).
2. `ds-ledger/SKILL.md:33`: Lite back to `phases 1, 3, 8`, or drop "returns both ledgers".
3. `ds-ledger` Mode B phase 9: re-add the read-only/writable hand-over and "propose the
   one-line change to this file"; restore `even when the user never asks` to the
   description.
4. Add the 6-line `decision-ledger` alias; restate the count as 127.
5. `ds-lessons`: a report-only branch carrying retro's `Present these candidates to the
   user, in order of severity`, plus the 1,000-line threshold and "look for existing docs
   first".
6. `ds-pr` step 3: also read `git log <base>...HEAD --format="%s"` and the conversation.
7. Delete `~/dotfiles/skills-overlay/{caveman-review,claude-handoff}.sh`,
   `caveman-help/README.md:28`, and the `.skill-lock.json` entry; then `skills-audit.sh`
   is silent.
8. Commit an overlay for `tiger-style-review` (and one for `caveman-help`) if 126 is meant
   to survive the next `update-all.sh`.
