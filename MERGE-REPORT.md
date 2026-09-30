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
