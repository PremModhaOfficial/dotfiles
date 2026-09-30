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

## 2026-09-30 — adversarial jury (agent-mesh)

Three `stealth/space-bunny-alpha` reviewers on a 3-member jury, 2/3 to pass.
Read their plan at `/tmp/jury/PLAN.md`; findings in `r2-notes.md`, `r3-findings.md`.

What they caught that I missed:

- **0-byte files parse clean.** `bash -n` and `json.tool` both accept an empty
  file, so the whole parse-sweep lens was blind to it. Commit `216b8af`
  ("chore: checkpoint work") had truncated `zed/.../fluoromachine-zed-theme.json`
  (95707 -> 0) and `prime-agent/update-all.sh` (3467 -> 0). Every branch I
  diffed against already had the empty version, so no diff surfaced it.
  **Check blob size (`git cat-file -s`), never just parse validity.**
- **Compare against the commit that last held real content,** not against
  another branch tip. `git branch --contains <good-sha>` then
  `git cat-file -s <sha>:<path>`.
- **Absolute symlinks into an ignored cache dangle on any other machine.**
  `dms/.../plugins/dank*` -> `/home/prm/.config/.../.repos/<hash>/`. The
  `.repos/` cache was untracked, so nothing tracked could satisfy them.
- **A glob in .gitignore does not always match the file you meant.** `dank*/`
  did not match; had to name all four paths explicitly.
- **Every branch head can be wrong in the same way.** "No diff" is not
  "nothing changed" when the defect predates every branch you compare to.

### Environment gotchas hit this session

- `herdr pane run <pane> <cmd>` **silently no-ops** in this build: exit 0,
  nothing runs. Use `pane send-text` + `pane send-keys <pane> enter`.
- `mesh-peer.sh` defaults `MESH_WORK=leya`, so it publishes into the wrong
  namespace for any other workID. Set `MESH_WORK` or use raw `nats`.
- KV `mesh.members.*` needs a `pane` field or `mesh-peer.sh peers` reports
  every member `dead` and nobody can be woken.
- `fish` rejects command substitution in command position, so
  `herdr pane run w:p cmd ... "$(cat f.txt)"` fails. Quote for fish or use
  send-text.

## 2026-09-30 — Orca agent rule (user-mandated)

**Dispatch Command Code on Orca. Nothing else.** No `zcode`, no `codex`, no
`opencode`, no `opencode2`, no `cursor` -- even when one reports
`state: ready`. `ready` only means a terminal opened; the wrong agent inside
it is a silent failure. Ask before dispatching any other agent.

Corollary learned the hard way: `--worktree current` runs the worker in the
coordinator's own terminal, so its output and keystrokes collide with the
coordinator session. Use `--worktree new-child`.

Fuller notes live in:
  ~/.commandcode/skills/orca-cli/LEARNINGS.md
  ~/.commandcode/skills/orchestration/LEARNINGS.md

Those SKILL.md files are stubs whose real content is served from the Orca
binary, so learnings go in the sibling LEARNINGS.md to avoid being overwritten.
