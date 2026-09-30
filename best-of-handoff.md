# best-of — handoff

## What is true now

- Repo: `/home/prm/orca/workspaces/dotfiles/comber`, branch `master` @ `aa03d50`,
  pushed and in sync with `origin/master` (0 ahead / 0 behind). Tree clean.
- 8 branches folded in. 14 commits authored. 87 files. 0 deletions from merges.
- Full account of the merge: `MERGE-REPORT.md`. Environment traps: `LEARNINGS.md`.
- Adjudicated by a 3-reviewer jury (agent-mesh, `stealth/space-bunny-alpha`),
  2/3 to pass. Four real defects it caught are fixed.

## THE NEXT ACTION, one line

Fix defect 1 in `jcode/update-all.sh`: make `sync_configs`' clean-tree guard
stop being defeated by the skills phase writing into `$DOTFILES`.

## The four defects worth fixing, in order

**1. `update-all.sh:409` guard is dead code (MUST-FIX, proven).**
`~/.agents` is a symlink to `dotfiles/agents/.agents`, so `SKILLS_DIR` (:45)
resolves *inside* `DOTFILES` (:50). Phase order runs `update_skills` (:620)
before `sync_configs` (:627), so the tree is always dirty when :409/:484 test
it → `df_pull_ok=0` → the ff-only pull (:413) and push (:485) never run.
Proof: `git -C /home/prm/dotfiles status --porcelain | wc -l` = 85.
Two possible fixes: exclude `$SKILLS_DIR` from the dirty check, or run
`sync_configs` before `sync_skills`.

**2. Phase 5 installs from the wrong checkout.** `DOTFILES=/home/prm/dotfiles`
is the main worktree on `DATA` @ `047247c`; the merged code is in the linked
worktree on `master`. `~/.jcode/bin/update-all.sh` is a symlink to the DATA
copy, so reviewed code never runs and :485 pushes to `origin/DATA`.

**3. `--dry-run` is dishonest.** `main` unconditionally runs `mkdir -p` (:636),
`checklist_write` (:637), `cp "$LOG" "$shared_log"` (:639) — no `$DRY` guard.
A dry run destroys the previous real run's log. Also leaks a run dir per call
(10 already retained under `~/.jcode/logs/`).

**4. Live configs blind-overwritten.** `install_if_different` (:365-372)
compares `readlink -f` *paths*, never content. Only `config.toml` is guarded,
by a separate `cmp -s` (:383). Hooks, themes, jcode-theme and pickr config
get blind `cp`.

Lower severity, all recorded in `MERGE-REPORT.md`: `.a5c/processes` is
CWD-relative (:471-472); no `trap` for INT/TERM during `git rebase` (:204);
`self_review` can print "(none)" after 10 real matches (:533, :536) because
`grep | head -10 || echo` returns 141 on SIGPIPE under `pipefail`; four
duplicated dry-run guards and a duplicated `local` from the merge
(:264/266, :311/316, :497/516, :546/579, :105-106).

**Verified SAFE, do not "fix":** the `git push --force-with-lease` at :196 is
correct — fork origin, lease read after `git fetch origin` (:189), explicit
expected OID, `rev-parse` guard fires on a missing ref.

## Still unverified

The nvim treesitter/obsidian pass never finished — `nvim --headless` full-config
startup exceeded 200s on slow plugins and the reviewer spent its budget
isolating them. Only `cabal`-absent and `haskell`-present were ever checked.

## Traps already bitten — do not repeat

- **`herdr pane run` silently no-ops** in this Orca build: exit 0, nothing runs.
  Use `pane send-text` + `pane send-keys <pane> enter`.
- **Orca orchestration cannot drive Command Code here.** The valid agent id IS
  `command-code` (found in the AppImage's `app.asar`), but it never reaches
  `agent_readiness`: `timeout`, then `terminal_handle_stale`. Don't retry it.
- **`--worktree current` shares the coordinator terminal** — output lands in the
  wrong place. Use `new-child`.
- **Headless agent invocation that works:**
  `cmd --yolo -p "<prompt>"` (see `cmd help`, `-p/--print`), or
  `jcode run -p openrouter -m stealth/space-bunny-alpha -C "$PWD" "<prompt>"`.
- **`jcode auth status` lies about money.** It is a credential-presence check.
  All four configured providers 402 on a real run until you pin `-m` to the free
  model. Details: `~/.agents/skills/agent-mesh/LEARNINGS-jcode.md`.
- **A parse check is not a correctness check.** `bash -n` and `json.tool` both
  accept a 0-byte file. Two files had been silently zeroed by commit `216b8af`
  and passed every validation I ran. Check `git cat-file -s`.
- **Diffing against another branch tip proves nothing** when every tip shares the
  same defect. Compare against the last commit that held real content:
  `git branch --contains <good-sha>` then `git cat-file -s <sha>:<path>`.
- **A stow glob may not match.** `dank*/` failed to match four DMS symlinks; had
  to name each path explicitly.
- **A session restart is not available from this runtime.** It is an Orca
  terminal, not a herdr pane; `HERDR_PANE_ID` is unset and `herdr pane list`
  shows only unrelated opencode panes. Restarting pid 52101 (`command-code`,
  this session's parent) would kill the work mid-write.
