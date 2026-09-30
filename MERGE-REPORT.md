# best-of merge — final report

Branch `best-of` → `master`. All 8 source branches folded in, every one verified
as an ancestor of `master`.

## Outcome

| | |
|---|---|
| Commits authored | 13 |
| Files changed vs `merger-work-main` | 86 (+7513 / −2993) |
| Source branches merged | 8 / 8 |
| Merge conflicts resolved | 10 (1 master, 9 wrk) |
| Deletions caused by the merge | 0 |
| Config validation | TOML, Lua, bash, fish, nvim all pass |

## Branches folded in

| Branch | Merge commit | Notes |
|---|---|---|
| `master` | `25c18fe` | 1 conflict: mpv HDR profile kept |
| `merger-work-main` | (base) | near-superset of master, 86 commits ahead |
| `origin/wrk` | `d3c659b` | 9 conflicts; purely additive, 0 deletions |
| `backup/dms-fingerprint-snapshot` | `fb7c3cf` | taken wholesale per user request |
| `DATA` | `e5ac821` | intent-interview skill recovered |
| `origin/skills` | `8792134` | unrelated history, `--allow-unrelated-histories` |

## Conflict resolutions

| File | Winner | Why |
|---|---|---|
| `mpv/.config/mpv/mpv.conf` | merger | HDR10 passthrough profile was a strict superset |
| `fish/config.fish` | merger | richer live config; only `mise completions` carried over |
| `fish/fish_variables` | merger | wrk side had stale `/home/prem-modha` paths |
| `kitty/kitty.conf` | merger | theme daemon owns fonts; wrk's block would fight it |
| `herdr/config.toml` | merger + union | kept token dashboard, fixed wrong home path |
| `herdr-sesh.toml` | merger | `fd -HI` over deprecated `fdfind -d 8` |
| `obsidian.lua` | master | master carried the deprecated-option fix |
| `treesitter.lua` | both | master removed `cabal`, wrk added `haskell` |
| `jcode/update-all.sh` + SKILL.md | merger | parallel phases, flock, dry-run, force-with-lease |
| `.gitignore` | union | every rule kept, `nvim/.bisect-wt/` added |

## Bugs found by the adversarial jury (3 reviewers, 2/3 to pass)

All four were verified by direct inspection before fixing. Every one was a real
defect I had shipped.

1. **`a0b1700` — silent content loss.** Commit `216b8af` ("chore: checkpoint
   work") truncated two files to 0 bytes: the zed Fluoromachine theme
   (95707 → 0) and `prime-agent/update-all.sh` (3467 → 0). Restored from
   `2251b28` and `544d8a9`. **Why my checks missed it:** every branch I diffed
   against already had the 0-byte version, so no diff surfaced it, and both
   `bash -n` and `json.tool` accept an empty file.
2. **`14c341a` + `d86f508` — dangling symlinks.** Four DMS plugin entries were
   absolute symlinks into `~/.config/.../plugins/.repos/`, a cache that is
   untracked. A clone anywhere else gets four broken links. Untracked, with
   exact-path ignore rules (a `dank*/` glob silently failed to match).
3. **`620d9be` — stale home paths.** `alacritty.toml:160` imported
   `/home/prem-modha/.config/alacritty/dank-theme.toml` and
   `jcode/.jcode/config.toml:239` pointed at `/home/prem-modha/dotfiles/...`.
   Corrected to `/home/prm`.

Rejected on evidence: a claim that `mcp-remote` was missing — it runs via
`npx`, which is installed.

## Repo hygiene

- 23 junk paths untracked (`690cbd8`): nvim logs, `.omc`/`.omg` state,
  `.srclight/index.db`, `*.bak`, `.repos/` cache. Files kept on disk.
- Skill duplication fixed (`6a0afe3`, `4baf33b`): `intent-interview` was
  committed at two paths stowing to the same target.
- `i-have-adhd` tracked for the first time (`eda2ae3`) — it existed only in an
  uncommitted worktree.
- No secrets: scanned for API keys and private keys, clean.

## Known gaps

- **`jcode/update-all.sh` (648 lines) and the nvim treesitter/obsidian set got
  no independent review.** This was R1's assigned slice in round 1 and R1 never
  reported on the wire. A second pass was launched via `cmd --yolo -p` but was
  stopped before it produced output. **These are unverified.**
- Pre-existing 0-byte niri files (`cursor.kdl`, `outputs.kdl`,
  `windowrules.kdl`) — empty in the source snapshot too, not merge damage.

## Environment findings

- `herdr pane run` **silently no-ops** in this Orca build: exit 0, nothing
  runs. Use `pane send-text` + `pane send-keys <pane> enter`.
- `mesh-peer.sh` defaults `MESH_WORK=leya`, publishing into the wrong namespace.
- KV `mesh.members.*` needs a `pane` field or peers read as `dead`.
- The valid Orca agent id is `command-code` (found in the AppImage's
  `app.asar`), but Orca orchestration never reaches `agent_readiness` with it:
  `timeout`, then `terminal_handle_stale`. **Orca cannot drive Command Code
  here.** `cmd --yolo -p` is the working headless path.
- `cmd help` documents `-p/--print` as the headless mode — this is what makes
  unattended review runs possible.

## Addendum — second review pass (`jcode run -p openrouter -m stealth/space-bunny-alpha`)

The round-1 gap (`jcode/update-all.sh`, unreviewed because R1 never reported)
was reviewed by a second pass. Findings below; every headline claim was
independently re-verified by me before recording.

### VERDICT: FIX-FIRST — 11 defects in `jcode/update-all.sh`

**1. Confirmed — the dotfiles pull/push is unreachable dead code.**
`SKILLS_DIR` (:45) resolves *inside* `$DOTFILES` (:50), because
`~/.agents` is a symlink to `dotfiles/agents/.agents`. Phase order runs
`update_skills` (:620) before `sync_configs` (:627), so the tree is always
dirty by the time the guards at :409 and :484 test it.
Verified: `git -C /home/prm/dotfiles status --porcelain | wc -l` = **85**.

**2. Confirmed — phase 5 installs from, and pushes to, the wrong checkout.**
`DOTFILES=/home/prm/dotfiles` is the main worktree on `DATA` @ `047247c`.
The merged code is in the linked worktree on `master` @ `3f8dbf3`. The live
entrypoint `~/.jcode/bin/update-all.sh` symlinks to the **DATA** copy, so the
code reviewed here never executes, and `git push origin "$df_branch"` (:485)
targets `origin/DATA`.

**3. Confirmed — `--dry-run` is dishonest.** `main` unconditionally runs
`mkdir -p` (:636), `checklist_write` (:637) and `cp "$LOG" "$shared_log"`
(:639) with no `$DRY` guard. A dry run destroys the previous real run's log.
Verified by reading :634-639 — no conditional. It also appends to the live
`CHECKLIST.md` and leaks a run dir per invocation (10 already retained).

**4. Live config overwritten with no divergence guard.** `install_if_different`
(:365-372) compares `readlink -f` **paths**, never content. Only
`config.toml` is protected, by a separate `cmp -s` (:383). Verified by reading
:365-375. Hooks, themes, jcode-theme and pickr config are blind-overwritten.

**5. `.a5c/processes` install is CWD-relative** (:471-472) while every sibling
path is absolute — a silent no-op under the documented invocation.

**6. No `trap` for INT/TERM** while `git rebase` (:204) is in flight; leaves
`.git/rebase-merge` and the tree on the gate branch.

**7. `self_review` can print "(none)" after 10 real matches** (:533, :536):
`grep | head -10 || echo "(none)"` under `set -o pipefail` returns 141 on
SIGPIPE, firing the fallback. The audit artifact claims "no debt" while
listing ten.

**8-11.** `upstream` remote never verified (:182-188); four duplicated dry-run
guards plus a duplicated `local` from the merge (:264/266, :311/316, :497/516,
:546/579, :105-106); `skill_sources` has no `DRY` guard of its own; and
`install_if_different`'s documented purpose is unachievable as written.

**Positively verified as safe:** the `git push --force-with-lease` at :196 is
correct — fork origin, lease read after `git fetch origin` (:189), explicit
expected OID, `rev-parse` guard firing on a missing ref.

### Not completed

The nvim treesitter/obsidian pass (round-1 candidate C8) did **not** finish:
full-config `nvim --headless` startup exceeded 200s on slow plugins, and the
reviewer spent its budget isolating plugins instead of reporting. That set
remains **unverified**.

### How the pass was driven

    jcode run -p openrouter -m stealth/space-bunny-alpha -C "$PWD" "<prompt>"

`jcode auth status` reports a provider `available` on a *credential presence*
check, not a balance check — all four configured providers 402 on an actual
run until `-m` pins the free model. See
`~/.agents/skills/agent-mesh/LEARNINGS-jcode.md`.
