# FIX-2 rev2 — what was restored, and the evidence

Ticket: `fix2-review.md` §1/§2/§3/§6. Scope respected: only `~/.agents/skills/*/` and
`~/.agents/skills/README.md` were written. No `AGENTS.md`, no `update-all.sh`, no commit.

**Skill count: 126 → 128.** Two additions, not one: `caveman-review` restored (item 6) and
`decision-ledger` alias added (item 7). `ls -d ~/.agents/skills/*/ | wc -l` = 128; README
rows 127 → 129 (header + 128). `caveman-review` is counted as a symlink-free real dir, so
the old "+2 symlinked" convention still gives 130 for the backup; the live number is 128.

**check.sh: exit 0.**
`bash ~/.agents/skills/flow/scripts/check.sh` → `OK: flow rules and skill references valid`.
Longest description still 606 chars (`python3 ~/.agents/loop/fix1-count.py` → PASS, 96
catalog + 32 manual-only = 128 parsed, so the new alias and the restored skill both parse).

---

## 1. `ds-pr` attribution — DONE

- New file `ds-pr/CREDITS.md`, restored from `pr/CREDITS.md` in the tarball. Only the
  self-reference changed (`pr` → `ds-pr`); the credit sentence itself is untouched.
  grep `reproduced almost word for word` → hit. grep `Dex Horthy` → hit.
- `ds-pr/SKILL.md:4-11` now carries the original frontmatter block:
  `metadata: credits: skill: show-me / author: Dex Horthy / organisation: Humanlayer / url: …`.
- Before: `find ds-pr -type f` → `ds-pr/SKILL.md` only. Now → `CREDITS.md` + `SKILL.md`.

## 2. `ds-ledger` — four restorations, gate now coherent

- `ds-ledger/SKILL.md:34` → `**Lite** …: phases 1, 3, 8; the gate returns only the two
  ledgers and open items.` (was `phases 0, 1, 8`).
  **Coherence checked, not assumed:** phase 3 is *build both ledgers*, phase 8 is the gate,
  phase 1 is map-components. So the gate sentence is satisfied by the phases it names, and
  `Stop when: Mode B: every phase in the chosen depth is done, both ledgers are full`
  (`SKILL.md:58`) now agrees. Under the old `0,1,8` it asked for ledgers phase 3 was told
  not to build — that contradiction is gone, not papered over.
- `ds-ledger/SKILL.md:46` (phase 9) ends with the restored second half: `Installed skills are
  usually read-only, so hand the entry to the user unless you have a writable copy or memory
  tool. If the cause was a process gap, propose the one-line change to this file.`
- `ds-ledger/SKILL.md:3` description regains `Use on such a task, even when the user never
  asks, and when they report something missed.` (auto-fire trigger back).
- `ds-ledger/evals/evals.json` restored from `decision-ledger/evals/evals.json`, all 4 evals
  (fprintd, sshd, systemd, and the "rename a variable" negative), `skill_name` renamed to
  `ds-ledger`. Parses: `EVALS: 4 ids [1, 2, 3, 4]`. Side effect: `python3 <this-skill-dir>/…`
  and the eval paths now sit beside the skill that needs them.

## 3. `ds-lessons` — report-only restored, plus both doc rules

- `ds-lessons/SKILL.md:26` is now the read-only branch, verbatim: `Present these candidates
  to the user, in order of severity.` followed by `Then stop unless the user asks for the
  fixes. /ds-lessons reports; it does not edit the repo unasked.` The old `Fix the most
  frequent classes now` line is now step 5, gated on the user picking — a `/retro`
  invocation no longer edits the repo. `Stop when` (`:41`) updated to match: *presented*,
  not *handled*.
- `:35` `CODING_STANDARDS.md` line regains `Add navigation pointers to docs folders if the
  standards file gets more than 1,000 lines long.`
- `:36` regains `Look for existing docs before writing new ones.`
- The duplicated `3.` numbering the merge left behind is gone (steps renumbered 1-8).

## 4. `ds-pr` context gathering — DONE

- `ds-pr/SKILL.md:18` step 3 now reads: `Gather context: the diff against the base …
  (`git diff <base>...HEAD`), the commit messages (`git log <base>...HEAD --format="%s"`),
  the changed files, and the conversation that led here.`
- `:20` step 5 ends with `Use the conversation context to inform the description, since the
  diff rarely carries the why.` — both greps hit verbatim.

## 5. `tiger-style-review` comment voice — DONE

`tiger-style-review/SKILL.md:57-95`:

- Prefix semantics restored: `🟡 risk: works but fragile (race, missing null check,
  swallowed error)` (grep hit), plus the missing `🔴 bug` / `🔵 nit` / `❓ q` glosses.
- The substitution is back in the Drop list: `"this is just a suggestion but..." (use
  "nit:" instead)`.
- The three ❌/✅ before-and-after rewrites are back (11 ✅ lines total, was 8).
- Boundaries regains `does not approve or request-changes, does not run linters` and
  `Output the comments ready to paste into the PR.`

## 6. DECISION CHANGE — `caveman-review` restored, not deleted

- `cp -a /tmp/fix2-src/caveman-review ~/.agents/skills/` from
  `loop/fix1-backup-skills.tar.gz`; `diff` against the tarball copy: identical
  (`SKILL.md`, `README.md`, `.overlay-applied`). Upstream-synced, so restoring is the only
  stable state — deleting it was silently undone by `sync_skills()`
  (`update-all.sh:334-341` iterates `caveman/skills/*/SKILL.md`).
- Mutual naming, one line each, so they are not competing siblings:
  - `caveman-review/SKILL.md` new `## Not this one`: *"`tiger-style-review` is the other
    terse review: same one-line shape and the same four severity prefixes, but it hunts
    Tiger Style safety and invariants…"*
  - `tiger-style-review/SKILL.md:106` adds the reciprocal: *"`caveman-review` is the other
    terse review: same one-line shape, the four severity prefixes and no Tiger Style tag
    taxonomy."* `tiger-style-review` stays the safety survivor.
- Both greps confirm the cross-reference exists exactly once in each file.
- **Rule recorded here and in the report's tail: never delete an upstream-synced skill
  again.** `caveman-review`, `caveman-help` and `tiger-style-review` are all overwritten by
  the next `update-all.sh`; only `ds-*` skills are local.

## 7. `decision-ledger` alias — DONE

`~/.agents/skills/decision-ledger/SKILL.md`, 6 lines, same shape as the `grill-me`
precedent (a `diff` of the two files differs only in description and body text):

```
name: decision-ledger
description: Audit a component's decision points; see ds-ledger Mode B.
disable-model-invocation: true
---
Call the Skill tool with "ds-ledger" and use Mode B.
```

Resolves: pi discovers `~/.agents/skills/` recursively (`docs/skills.md:61`), and the dir
holds a `SKILL.md` whose frontmatter `name` matches the directory — the same contract
`grill-me` and `ds-ledger` satisfy. It is manual-only, so it adds no catalog words (the
`96 auto / 32 manual` split shows it landed on the manual side).

## 8. Dead pointers

| file:line | state now | action |
| --- | --- | --- |
| `caveman-help/README.md:28` `/caveman-review one-line PR comments` | **true again** | no edit needed: item 6 restored the command, so the cheat sheet is correct. Deleting the row would have removed a live command — the pointer was fixed by the restoration, not by the deletion the review proposed. |
| `caveman-help/SKILL.md:28` `(caveman-review merged here)` | was false | replaced with two real rows: `tiger-style-review … Safety tags only.` and a new `caveman-review` row with its own example line. |
| `ds-ledger/references/knob-classes.md:28` `decision-ledger skill v5` | names a skill the merge absorbed | now `ds-ledger Mode B v5`, in the same miss-log example. |
| `.skill-lock.json:373-377` `claude-handoff` | generated file | **not hand-edited.** It is written by the `skills` CLI (v1.7.0, `~/.bun/install/cache/skills@1.7.0@@@1`, the same tool that owns the per-harness skill dirs). Regenerate with `bunx skills@1.7.0 remove claude-handoff` (`remove` is a real subcommand; `skills update` also rewrites the lock). Not run here: it mutates harness dirs and may hit the network. |

Zero dangling symlinks in all seven harness dirs after the restore (re-checked: 0 in
`~/.pi`, `~/.claude`, `~/.commandcode`, `~/.hermes`, `~/.zcode`, `~/.minimax`,
`~/.autohand`).

---

## What a re-sync still breaks (three edits live in synced skills)

`sync_dir` copies upstream over these dirs on every `update-all.sh`, so these restorations
are one full run away from vanishing unless an overlay ships in
`~/dotfiles/skills-overlay/` (outside the files this ticket owns, so not written):

1. `caveman-review/SKILL.md` — the `## Not this one` line. The dir itself is safe (upstream
   ships it); only the added section needs `caveman-review.sh`.
2. `tiger-style-review/SKILL.md` — the restored prefix semantics, examples and Boundaries
   clauses (item 5). Needs a `tiger-style-review.sh` overlay.
3. `caveman-help/SKILL.md` — the two-row Skills table (item 8). `caveman-help.sh` exists but
   only rewrites README links, not the table.
4. `~/dotfiles/skills-overlay/claude-handoff.sh` still targets a deleted dir (review §3);
   untouched, out of scope, still makes `skills-audit.sh` exit 1.
5. `ds-*` edits (items 1-4, 7) are local skills — they survive the sync.

## Disclosed, not restored (not in this ticket's list)

- `ds-ledger` phase 6 still lacks the parenthetical worked examples
  `(update overwrites config, not enabled at boot, no recovery path)`; the pre-mortem,
  the "reviewer who wants them to fail" and the deletion test are present.
- `retro`'s trigger `Use when the AGENTS.md file is particularly large — in the repo OR the
  user's global scope`: the repo half is covered by `ds-lessons` step 2's *Steering files*
  bullet, the global-scope half is not.
- `pr`'s eight worked examples stay compressed to bullets in `ds-pr` (review §1b, judged a
  defensible trim).
