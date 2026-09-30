# Learnings

Running log of mistakes, corrections, and non-obvious facts about this environment.
Append new entries; don't rewrite old ones.

## 2026-09-30 — best-of branch merge

### Orca orchestration: don't use it for agent fan-out on this machine

Every `worker-start` dispatch failed. Facts, in the order I learned them:

- `orca` bare on Linux resolves to the GNOME screen reader (`/usr/bin/orca`).
  Use `orca-ide` (or `$ORCA_CLI_COMMAND` if set). Both were unset here.
- Valid `--agent` ids come from `orca-ide agent-context --json`, not from
  `--help`. The schema advertises `claude`, `codex`, `cursor`, `antigravity`,
  `muse`, `zcode`, `opencode`, `opencode2`. There is no `command-code` id even
  though `command-code` is the binary on PATH.
- `--agent claude` starts, reaches `ready`/`pending`, then dies with
  `process_exited` / `lastFailure: "Terminal closed by operator request"`.
- `--agent zcode` resolves to `agentIdentity: "command-code"` but then times out
  at stage `agent_readiness` with `lastError: "timeout"` — no zcode subscription.
- `worker-start` blocks past ~30s. The shell tool kills it at 30s and it *looks*
  like failure while the dispatch is actually live. Check
  `orca-ide orchestration worker-list --run <id> --json` before assuming failure.

Conclusion: dispatching Orca workers burned several rounds for zero progress.
Verify a terminal agent actually reaches `succeeded` on a trivial probe task
before fanning out real work. For small file sets, just do the edits directly.

### Merge hygiene

- `git merge --no-commit --no-ff` then inspect `git diff --cached --name-status
  HEAD | grep '^D'` before resolving. A stale branch merged additively should
  show zero deletions; a large `D` count means it would wipe current config.
- Two branches can carry the *same* cherry-picked fix under different hashes
  (`4a7cf7c` on master, `da7b69e` on merger-work-main — identical diff and
  message). Check `git show <sha> -- <file>` before deciding which side is
  "newer"; you may be merging a fix that is already present.
- `wrk` is 6 weeks stale and machine-specific: it hardcodes `/home/prem-modha/`
  while this machine is `/home/prm/`, and sources a `tokens.fish` that does not
  exist in the repo. Grep every candidate merge for foreign home paths before
  accepting.
