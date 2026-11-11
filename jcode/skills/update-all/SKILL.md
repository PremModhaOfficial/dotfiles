---
name: update-all
description: Update the jcode fork, skill sources, tools and live configs while preserving custom gate behavior and runtime configuration. Read canonical context first. One command: bash ~/dotfiles/jcode/update-all.sh --parallel
version: 1.2.0
---

# update-all

## Run this first
- `bash ~/dotfiles/jcode/update-all.sh --context` — prints canonical paths, no work
- Read `~/.agents/skills/update-all/CHECKLIST.md` — ledger of last run + any failed steps
- `git -C ~/.jcode/source/jcode status --porcelain` — core MUST be clean (no untracked files)

## Execute
```bash
cd ~/dotfiles
bash ./jcode/update-all.sh --parallel --dry-run   # preview, no writes
bash -x ./jcode/update-all.sh --parallel          # real run (may take 10+ min first time)
```
Flags: `--parallel` (independent phases + sources concurrently), `--dry-run`, `--jcode-only`, `--skills-only`, `--tools-only`, `--config-only`, `--manifest-only`.

## Safety contracts
- **Upstream precedence.** jcode core is upstream-managed. Our fork carries `local/turn-end-gate` only where it doesn't conflict with upstream direction. On rebase conflict, upstream wins and we adapt:
  - Equivalent upstream functionality → drop our version, keep upstream's
  - Upstream absorbed our patch → keep merged result (not duplicate)
  - `turn_end_gate` = sole continuation-decision hook. `turn_end` / `post_tool_feedback` = fire-and-forget observers only. Do NOT duplicate control flow.
- Dirty core → fails, no stash/reset (clean it first)
- Rebase gate branch, build that branch, ONLY force-push on success
- Fast-forward pulls override `pull.rebase=true`, disable autostash
- Divergent live jcode config preserved, manual merge only
- Dirty dotfiles → skip push, install configs only (filter updater output, not user edits)
- Dry-run writes only reporting/lock files. No git ops, no builds, no installs, no skill copies

## Skill overlays
A sync replaces a skill dir wholesale, so anything the skill points at outside it
(`../../README.md`, `docs/*`, `agents/*.md`) is gone after install and any edit
made in the installed copy is erased by the next sync. Those fixes are recorded
patches instead: `~/dotfiles/skills-overlay/<skill>.sh`, applied by
`apply_overlays()` at the end of the `update_skills` phase — after every family
sync, before the manifest.

- Contract: cwd and `SKILL_DIR` are the installed skill dir, `CLONE` is
  `~/.jcode/updater-src`. Idempotent, exit 0 with an `OVERLAY-WARN` line when it
  cannot patch, touch `.overlay-applied` last.
- `skills-overlay/host/<skill>.sh` is the same contract for a skill installed
  outside `~/.agents/skills` (pi's npm-packaged ones, e.g. `paperclip`), and runs
  against `~/.pi/agent/skills/<skill>`.
- A missing installed dir is an `OVERLAY-WARN` and a skip, never a failure. A
  failed overlay is recorded in the checklist but never blocks configs/manifest.
- `bash ~/dotfiles/jcode/skills-audit.sh` reports any overlay whose skill dir has
  no `.overlay-applied` as "overlay not applied: <skill>".

## Verify + report
- Latest log: `~/.jcode/logs/update-all.log`. Per-run logs: `~/.jcode/logs/update-all-*`
- Babysit: `SDK_VERSION=latest`, `--harness jcode` (x2), exactly one jcode note, no `{{harness}}`
- Fork branch `local/turn-end-gate` still exists and built
- Count `*/SKILL.md` = manifest data rows
- Reload skills; if core rebuilt, restart jcode or `/rebuild` (needs `~/.jcode/debug_control`)
- Report: source commits, failures/skips, log+ledger paths, remaining restart work