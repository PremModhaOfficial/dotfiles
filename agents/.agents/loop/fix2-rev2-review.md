# FIX-2 rev2 — antagonist review

**VERDICT: PARTLY REFUTED.** All six enumerated restores exist, are reachable and are
free of the rev1 holes; the alias, Lite gate, count and `check.sh` hold. But the claim's
universal — "everything the first review said the merges lost" — is false for three items
rev2 itself discloses, "verbatim" is false for three of the six, and restoring
`caveman-review` duplicates the comment-voice contract instead of deleting it.

Evidence base: live tree vs `loop/fix1-backup-skills.tar.gz` extracted to `/tmp/rev2chk`
(`decision-ledger pr open-pr retro caveman-review tiger-style-review caveman-help`).

---

## 1. The six restore items

| # | item | state |
| --- | --- | --- |
| 1 | `pr/CREDITS.md` + `metadata.credits` | **HOLDS** |
| 2 | `ds-ledger` Lite 1,3,8 / phase 9 / description trigger / evals | **HOLDS, not verbatim** |
| 3 | `ds-lessons` report-only / 1,000-line / look-first | **HOLDS 3 of 4** |
| 4 | `ds-pr` `git log` + conversation line | **HOLDS** |
| 5 | `tiger-style-review` prefix semantics + examples | **HOLDS, not verbatim** |
| 6 | `caveman-review` restored | **HOLDS** |

### 1. `pr` attribution — HOLDS
`diff /tmp/rev2chk/pr/CREDITS.md ds-pr/CREDITS.md` → one line, `pr` → `ds-pr`. That change
is disclosed. `ds-pr/SKILL.md:4-10` carries the original `metadata.credits` block byte for
byte (`show-me`, Dex Horthy, Humanlayer, URL). `find ds-pr -type f` → `CREDITS.md`,
`SKILL.md`.

### 2. `ds-ledger` — four restores present, three wording drifts
- Phase 9 (`SKILL.md:46`) is **identical** to the original line, both sentences.
- Lite (`:34`) is semantically the original but **not verbatim**: original
  `no security/data impact): Phases 1, 3, 8` → live `no security or data impact): phases
  1, 3, 8`.
- `evals/evals.json` differs from `decision-ledger/evals/evals.json` only at
  `skill_name` (`decision-ledger` → `ds-ledger`); all 4 ids intact, including the "rename
  the variable" negative.
- Description (`:3`): the demanded clause is back —
  `Use on such a task, even when the user never asks, and when they report something
  missed.` — but it is **the reviewer's sentence, not the original file's**. The original
  trigger was `Use whenever such a task has real consequences, even if the user never
  mentions requirements`. The restored sentence is now anchored to `Use for multi-phase
  or autonomous work`, so the skill has been **broadened to fire on any multi-phase run**
  and the `real consequences` qualifier is still absent. "Restored verbatim" is false
  here, and the effect is not neutral: rev1's complaint was a narrow loss of the auto-fire
  trigger; rev2 replaced it with a wider one.

### 3. `retro` → `ds-lessons` — 3 of the 4 named losses restored
- `ds-lessons/SKILL.md:26` — `Present these candidates to the user, in order of severity.`
  plus `Then stop unless the user asks for the fixes. /ds-lessons reports; it does not edit
  the repo unasked.` The report-only guarantee is real: step 5 (`Fix the classes the user
  picks`) is gated on the pick, and `Stop when` bullet 2 covers the report-only exit.
- `:35` — `Add navigation pointers to docs folders if the standards file gets more than
  1,000 lines long.` **verbatim**.
- `:36` — `Look for existing docs before writing new ones.` **verbatim**.
- **MISSING:** rev1 §1d item 4, the trigger
  `_Use when_ the AGENTS.md file is particularly large - in the repo OR the user's global
  scope` (`retro/SKILL.md:20`). `grep -n 'global\|particularly large' ds-lessons/SKILL.md`
  → nothing. Rev2 discloses this ("the global-scope half is not") and calls it out of
  ticket scope; fair, but then the claim cannot say "everything the first review said the
  merges lost is restored".

### 4. `ds-pr` context — HOLDS
`ds-pr/SKILL.md:18` — `(git log <base>...HEAD --format="%s")`, `the changed files`, and
`the conversation that led here`. `:20` — `Use the conversation context to inform the
description, since the diff rarely carries the why.` Both greps hit. Nothing parked: both
sit in the numbered Steps the skill executes.

### 5. `tiger-style-review` comment voice — substance restored, wording not verbatim
- `:60-63` the four glosses, including `🟡 risk: works but fragile (race, missing null
  check, swallowed error)`.
- All four glosses are **rewritten**: `will cause incident` → `will cause an incident`,
  `micro-optim. Author can ignore` → `micro-optimisation. The author can ignore it`,
  `genuine question` → `a genuine question`.
- The Drop list is **flattened to prose** and one item's content is gone:
  original `Hedging ("perhaps", "maybe", "I think") — if unsure use q:` → live
  `hope-to-help hedging (use q: when unsure)`. The three example words exist nowhere in
  `tiger-style-review` any more (they survive only in `caveman-review/SKILL.md:25`).
- Example 1 is **truncated**: `...This could potentially cause a crash...` drops
  `if the user is not found in the database`. Examples 2 and 3 are re-wrapped but complete.
- `:57-95` is inside the skill body, before `## Scoring`; it loads whenever the skill does.

### 6. `caveman-review` restored — HOLDS, with a duplicate
`diff -r /tmp/rev2chk/caveman-review caveman-review` → only the appended
`## Not this one` paragraph at `:55-57`. The upstream-sync rationale checks out against
`~/.jcode/bin/update-all.sh:331-335`, which syncs every `caveman/skills/*/SKILL.md`, so
the dir would be recreated.

Two consequences the claim omits:
- The restored skill has **no `disable-model-invocation`**, so it is back in the catalog
  (95 → 96), and its description trigger — `"review this PR", or "review the diff"` —
  now competes with `code-review`, `ds-review-loop`, `ponytail-review` and
  `tiger-style-review` for the same request.
- The prefixes and all three before-and-after examples now exist **twice** (§5 above).

---

## 2. The alias — routes, hidden, one line short of the brief

`decision-ledger/SKILL.md`, 7 lines (the claim says 6):

```
name: decision-ledger
description: Audit a component's decision points; see ds-ledger Mode B.
disable-model-invocation: true
---
Call the Skill tool with "ds-ledger" and use Mode B.
```

- **Routes:** yes. `ds-ledger/SKILL.md:13` (`Pick the mode … B for a component you
  configure`) is the next hop, and `:34` is the depth ladder. One hop, not zero.
- **Names the phases:** no. The alias carries no depth guidance, so `/decision-ledger`
  on a trivial task depends on the reader scrolling to `:33-35` to learn Lite exists.
  This is the exact gap the review warned about, but it is one section earlier rather
  than absent, so it is not "worse than the deletion".
- **Hidden:** yes, and pi honours it — `docs/skills.md:53`, `dist/core/skills.js:262`
  (`disableModelInvocation: frontmatter["disable-model-invocation"] === true`) and `:279`
  (filtered out of the prompt). `fix1-count.py` reports 96 auto / 32 manual, so the alias
  landed on the manual side and cost no catalog words.

---

## 3. Lite gate coherence — HOLDS

Read the whole skill, not the diff. With phases **1, 3, 8**:

- 1 = map components, 3 = build both ledgers, 8 = done gate returning `coverage table;
  Done ledger; Not-done ledger; open items; verification results; rollback path`.
- The Lite qualifier says the gate returns `only the two ledgers and open items`. That is
  satisfied: the coverage table needs phase 2, the verification results need phase 7, and
  both are skipped. No phase is asked to produce something a skipped phase owns.
- `Stop when` (`:58`) — `every phase in the chosen depth is done, both ledgers are full` —
  now agrees with a depth that includes phase 3.

One seam survives from the original, not introduced here: phase 3 still says "so the
coverage script can read it", but the script is a phase-2 step and Lite never runs it.
Same defect existed in `decision-ledger/SKILL.md`; verbatim restore means inherited.

---

## 4. Mutual naming — no deferral loop, but duplication

The pair quotes each other once each:

- `tiger-style-review/SKILL.md:104-107`: "`caveman-review` is the other terse review …
  Use it when the ask is comment voice rather than safety; use this one when the ask is
  invariants."
- `caveman-review/SKILL.md:55-57`: "`tiger-style-review` is the other terse review … Use
  this one for comment voice on any diff; use that one for safety."

Each file still defines its own content, so **nothing that belonged to this pair exists in
neither**. The failure is the opposite: `tiger-style-review` routes "comment voice" to
`caveman-review` while itself carrying the full four prefixes, the Drop/Keep lists, the
three worked examples and auto-clarity (`:57-95`). The routing line contradicts the body,
and the two copies have already drifted (gloss wording, hedge list, truncated example).
That is duplication, not deferral — and it is drift with no owner, since the copy in
`tiger-style-review` is upstream-overwritten.

Content that genuinely exists in neither file today (all disclosed by rev2, listed so the
"everything" claim is measured, not assumed):
- `retro/SKILL.md:20` global-scope trigger — `grep` in `ds-lessons` finds nothing.
- `decision-ledger` phase 6 parentheticals `(update overwrites config, not enabled at
  boot, no recovery path)` — `grep -r 'not enabled at boot'` → no file.
- `pr`'s eight worked examples (`on(save)` etc.) — `grep -r 'on(save)'` → no file.

---

## 5. Count — 128 exact, nothing counted twice

- `ls -d ~/.agents/skills/*/` = 128 = **126 real dirs + 2 external symlinks**
  (`cua-driver → ~/.cua-driver/skills/cua-driver`,
  `superwhisper → ~/.local/share/superwhisper/app/1.3.0/assets/agent-skill/superwhisper`).
  Neither target lives inside `~/.agents/skills`, so no target is counted twice.
- `find ~/.agents/skills -name SKILL.md` = 126 (symlinks not traversed) — consistent.
- `fix1-count.py` → 128 total / 96 auto / 32 manual / longest description 606 / exit 0.
- README: 128 skill rows, 130 lines beginning `|` (header + separator + 128), **no
  duplicate name**, and every frontmatter `name` equals its directory name.
- `bash flow/scripts/check.sh` → `OK: flow rules and skill references valid`, exit 0.
- Cosmetic: the report's "README rows 127 → 129" does not match the file's 128 rows.

---

## What to tell the next reader

The six items rev1 demanded are back and nothing is parked out of reach. Do not quote
"verbatim" — three of the six are rewrites with the same meaning, and one of them (the
`ds-ledger` description) changed what fires the skill. Say "126 → 128, one of which is a
hidden alias and one a restored upstream dir", and say that rev1 §1d item 4 (global-scope
trigger) plus two "defensible trim" items are still out.
