# Next-run context

Last reviewed: 2026-09-17. Read this before rediscovering sources or changing patches.

## Canonical entry points

- Script: `~/dotfiles/jcode/update-all.sh`
- Procedure: `~/dotfiles/jcode/skills/update-all/SKILL.md`
- Context: this file
- Shared history: `~/.agents/skills/update-all/CHECKLIST.md`
- Latest aggregate log: `~/.jcode/logs/update-all.log`
- `bash ~/dotfiles/jcode/update-all.sh --context` prints these paths without work.

## Preservation decisions

- Dotfiles branch was **DATA**. Detect the current branch, never hardcode DATA,
  wrk, or a historical merge branch. Dirty dotfiles contains unrelated user work.
  Do not broadly stage it, reset it, or manufacture an update commit.
- Coordinator already preserved **11 live-only jcode config keys**. Treat live
  `~/.jcode/config.toml` as containing runtime state beyond the dotfiles template.
  The updater deliberately skips divergent live config and reports manual merge.
- Audit says upstream niri fixes handle nested binds, but the **installed include
  still needs migration**. Keep the local niri patch temporarily until that
  include has been migrated and validated. Do not drop it just because an upstream
  fix exists. This updater change does not touch core or niri configuration.
- The custom **turn_end_gate is still needed** for babysitter continuation.
  Preserve the gate branch, babysitter-gate hook and non-hook-driven babysit note.
  Historical commit IDs may change after rebase. Verify behavior, not old hashes.
  Remaining risks: rebase conflicts, stale gate followups/loop-cap behavior, and
  confusing a successful build with promotion/reload of the running server.
  Do not fix or remove core gate behavior as part of updater-only maintenance.

## Skill refresh completed earlier this session

Seven independent pulls succeeded and source trees remained clean:

| Source | Commit |
|---|---|
| ponytail | e3ba2aa |
| caveman | 542442b |
| tiger-style | e4492f7 |
| tuicr | d6441a1 |
| babysitter | feb68abe3 |
| herdr | 101ccc2 |
| babysitter process library | feb68abe3 |

20 skill directories copied (40 source files verified), babysit regenerated.
26 installed SKILL.md files matched 26 manifest rows. Babysit verified with
SDK latest, two `--harness jcode` flags and exactly one jcode note. Previous script
log reported 25 due to header subtraction, fixed in this updater revision.
Private earlier ledger/log directory, for coordinator merge:
`/home/prm/.jcode/scratch/update-all-run-skills-20260917T170920Z-hZHms6/`
(`checklist.tmp`, `checklist-final.md`, `update-all.log`, `verification.txt`).

## New updater operational contract

Use `--parallel` explicitly. Core/skills/tools are independent. Every phase/job
has private status/logs and is waited before configs/manifest. Herdr tool setup
stays sequential internally. `flock` rejects overlapping executable runs.
Source-only workers bypass main and therefore need coordinator-owned locking,
private LOG/CHECKLIST_TMP/CHECKLIST/RUN_DIR, and disjoint scopes.

Core refuses dirty state, does not stash/reset, builds the rebased gate branch
before an explicit force-with-lease push, and returns to the prior branch.
Pulls use `-c pull.rebase=false -c merge.autoStash=false pull --ff-only` to
neutralize the global rebase preference without disturbing source modifications.
Failures are nonzero and recorded. Skips are visible, not proof of a merge.

Dry-run is `--dry-run`, **not JCODE_DRY=1**. It performs no Git mutation, build,
tool install, config copy, skill sync or manifest rewrite. It does write isolated
reporting/lock files. Validate with a scratch HOME and stubs before a real run.
Updater implementation was tested syntactically and with scratch/stub workflows.
These tests are not an end-to-end live update. Coordinator owns the next real
`bash -x ./jcode/update-all.sh --parallel` run, validation, commit and push.
