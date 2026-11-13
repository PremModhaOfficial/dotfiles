# FIX-8 rev4 — the four holes left by the rev3 review, closed

**Proof (one command):** `node ~/.agents/loop/fix8/fix8.test.mjs` → **`94/94 cases passed (51 isolated, 43 composed)`**, **exit 0** (exit checked un-piped). Negative control re-runs the same file against rev1: **exit 1, 33 cases failing** (11 isolated, 22 composed) — every rev4 row among them, so a green run is still not a harness artefact.

Only `~/.pi/agent/extensions/herdr-interactive-only.ts` and the test file changed. `bash-guard.ts` untouched (its rewrite is still exercised by every composed row: `rewritten=true` is asserted on all 43).

## The four fixes

| # | hole (rev3 review) | fix in `herdr-interactive-only.ts` | shape now classified |
|---|---|---|---|
| 1 | `herdr pane run <pane> 'pi -p x'` passed end to end — the shape this machine's own history used twice; `hc exec` also passed | `HARNESS_CONTAINERS = {pane}` steps one level down before reading the subcommand, `exec` joins `SPAWN_SUBCOMMANDS`, and the forward scan now recurses into any token containing a space, reusing the tmux quoted-command path. The scan still continues afterwards (`continue`, not `return`) so the recorded fail-closed behaviour in fix 4 stays intact. | `herdr pane run wC:pF 'pi -p t'`, `hc exec pi -p x`, `hc exec --on m pi -p x`, `hc exec bash -c 'pi -p x'` — all block; `herdr pane run wC:pF 'PI_SESSION_NAME=mpd-setup pi'` and `herdr pane run wC:pF nvim` pass (warn / pass) |
| 2 | `timeout 5 -s KILL pi -p x` passed: `skipFlags` ran before the duration was stripped | the wrapper loop alternates `skipFlags` and the duration match until neither applies, so flag/duration order stops mattering | `timeout 5 -s KILL pi -p x` blocks; `timeout -s KILL 5 pi -p x` and `timeout 600 sudo -u bot pi -p x` still block |
| 3 | quoted `$(...)` asserted `pass` while unquoted blocked | **safe direction: it blocks.** Substitution bodies are extracted with a small quote-aware scanner (`substitutionBodies`) and analysed like any command line; it runs on the raw command and on every `bash -c` payload, which is where a substitution survives quoting. Single-quoted text stays literal (`echo '$(pi -p t)'` passes) — that is a difference in quote type, not the old quoted/unquoted asymmetry, and it honours the header's rule that words in arguments are not actions. | `echo "$(pi -p t)"` blocks in isolation **and** composed (`bash -c 'echo "$(pi -p t)"'`); `bash -c "echo $(pi -p t)"` still blocks; `echo '$(pi -p t)'` passes both ways |
| 4 | two over-blocks the reviewer found | not chased. Both are now written into the header's documented-gap block as deliberate fail-closed decisions, one line each, **and asserted as `block` rows in the suite** so a future "fix" fails the run instead of silently changing policy: a never-called `f() { pi -p x; }`, and `hc run --bg nvim pi -p x`. | — |

The header also loses the stale `$(...)`-inside-double-quotes gap entry (no longer a gap) and gains the covered list: two-level `herdr`/`hc` subcommands and quoted substitution bodies.

## New rows (all previous rows kept)

| suite | want | got | command |
|---|---|---|---|
| isolated | block | block | `herdr pane run wC:pF 'pi -p t'` |
| isolated | block | block | `herdr pane run wC:pF 'PI_SESSION_NAME=x pi -p t'` |
| isolated | block | block | `hc exec pi -p x` |
| isolated | block | block | `hc exec --on m pi -p x` |
| isolated | block | block | `hc exec bash -c 'pi -p x'` |
| isolated | block | block | `timeout 5 -s KILL pi -p x` |
| isolated | block | block | `timeout -s KILL 5 pi -p x` |
| isolated | block | block | `echo "$(pi -p t)"` |
| isolated | pass | pass | `echo '$(pi -p t)'` (literal text) |
| isolated | block | block | `hc run --bg nvim pi -p x` (deliberate over-block) |
| isolated | pass | pass | `herdr pane run wC:pF 'PI_SESSION_NAME=mpd-setup pi'` |
| isolated | pass | pass | `herdr pane run wC:pF nvim` |
| composed | block | block | `herdr pane run wC:pF 'pi -p t'` |
| composed | warning | warning | `herdr pane run wC:pF 'PI_SESSION_NAME=mpd-setup pi'` |
| composed | block | block | `hc exec pi -p x` |
| composed | block | block | `hc exec bash -c 'pi -p x'` |
| composed | block | block | `timeout 5 -s KILL pi -p x` |
| composed | block | block | `echo "$(pi -p t)"` (was `pass` in rev3) |
| composed | pass | pass | `echo '$(pi -p t)'` |
| composed | block | block | `hc run --bg nvim pi -p x` (deliberate over-block) |
| composed | block | block | `f() { pi -p x; }` (deliberate over-block) |

Counts: isolated 39 → **51**, composed 35 → **43**, total 74 → **94**.

## Nothing lost on real traffic

Replayed every unique bash command in `~/.pi/agent/sessions` (**4 191** commands) through rev1 and rev4: **0** commands move block → pass and **0** move pass → block. 14 classify BLOCK, all genuine `pi -p` / `nohup pi -p` / `hc run … pi -p` one-shots. The two `herdr pane run` occurrences in that history are the interactive `PI_SESSION_NAME=mpd-setup pi` form and classify as an interactive spawn (report-back warning), not a block.

Twenty non-spawn probes stay empty: `herdr pane list`, `herdr pane send-keys … 'pi -p x' Enter`, `hc exec nvim /tmp/x`, `timeout 5 nvim`, `timeout -s KILL 5 tail -f log`, `echo $(date)`, `git commit -m "fix $(date)"`, `ls $(pwd)`, `herdr pane run wC:pF nvim`, `tmux attach`, `f() { echo hi; }`, `docker run --rm alpine echo hi`, `if grep -q x file`, … (`pi --help` and `env FOO=1 pi --help` still produce the report-back warning, unchanged: a warning, not a block).

## Is the `tsc --strict` check rerunnable byte-identically?

**Rev3: no.** No `tsconfig` was written down and no shim was committed, so the claim could be repeated only by reinventing an ad-hoc `paths` shim — same idea, not the same bytes.

**Rev4: yes.** The shim is now committed next to the suite:

- `~/.agents/loop/fix8/tsconfig.check.json` — `strict`, `noEmit`, ES2022/ESNext, `moduleResolution: bundler`, `skipLibCheck`, `paths` → `../../../.npm-global/lib/node_modules/@earendil-works/pi-coding-agent/dist/index.d.ts`, `files` → the one real extension file. (Relative paths because tsc 7.0.2 removed `baseUrl`.)
- `~/.agents/loop/fix8/tsc-check.sh` — `sh ~/.agents/loop/fix8/tsc-check.sh`, exits with tsc's status.

Measured: `sh ~/.agents/loop/fix8/tsc-check.sh` → **exit 0**. It is not a no-op: appending `const nope: number = "x";` to a copy of the checked file makes the same shim fail with `TS2322` at the right line, exit 1. Rerunnable as long as `tsc --version` is **7.0.2** and the pi package stays at `/home/prm/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent`; both are stated in the shim's comment and here.

## Files

- `~/.pi/agent/extensions/herdr-interactive-only.ts` — header gap block, `HARNESS_CONTAINERS`, `exec` in `SPAWN_SUBCOMMANDS`, harness forward-scan recursion, wrapper flag/duration loop, `substitutionBodies` + `scanText`.
- `~/.agents/loop/fix8/fix8.test.mjs` — 20 new rows, one flipped row, header gaps updated.
- `~/.agents/loop/fix8/tsconfig.check.json`, `~/.agents/loop/fix8/tsc-check.sh` — the committed type check.
