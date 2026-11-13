# FIX-8 rev3 — antagonist review (falsification attempt)

**Verdict: the numbers are real and rev3 survives every named attack on its six new shapes; it is not clean — rev3 introduces one new block-class false positive (never-called function definitions), leaves two live one-shot launchers passing (`herdr pane run`, `hc exec`), and its `timeout` handling is order-dependent.**

## 1. Claim reproduced — true, all three parts

| claim | measured |
|---|---|
| `node ~/.agents/loop/fix8/fix8.test.mjs` | `74/74 cases passed (39 isolated, 35 composed)`, **exit 0** (checked with the exit code un-piped) |
| rev1 control | `rev1 still fails, exit 1 — 19 cases failing` (4 isolated, 15 composed; all six rev3 shapes among them) |
| `tsc --strict` | clean, exit 0 (see caveat below) |

The control is a real control: it re-runs the same file with `FIX8_EXT_DIR=rev1`, so a green run cannot be a harness artefact. The six new composed rows are present and block. Caveat: no `tsconfig.json` exists in `~/.pi/agent`, so "tsc clean" is only reproducible with an ad-hoc `paths` shim (`moduleResolution: bundler` + `paths` → the globally installed `dist/index.d.ts`); the check is not committed anywhere.

## 2. New false positives — none from the seven named probes, two elsewhere

All seven suggested probes pass (no block): `if grep -q x file`, `tmux new-session -d nvim`, `tmux attach`, `f() { echo hi; }`, `docker run --rm alpine echo hi`, `time pi --version`, `env FOO=1 pi --help`. Twenty more non-spawn shapes were probed; the tmux/grouping/keyword work does not block any of them.

Two genuine block-class false positives do exist:

1. **A function definition that is never called now blocks** (new in rev3, via the `SHELL_KEYWORDS` skip):
   - `f() { pi -p x; }` → **BLOCK** (rev1: pass)
   - `function build() { pi -p x; }` → **BLOCK** (rev1: pass)
   Nothing executes; rev3's own suite only asserts the shape *with* a call (`f() { pi -p x; }\n( pi -p x )`), so the definition-only case is untested. This is the original bug in reverse: a harmless line is hard-stopped, and in a sourced script it blocks every future edit of that file. `cat > f.sh <<'EOS' … EOS` is safe only because the heredoc stripper drops the body.
2. **Harness forward-scan blocks an agent-shaped *argument*** of another program:
   - `hc run --bg --name x nvim pi -p x` → **BLOCK**
   - `hc run --bg --name x grep -n pi -p f` → **BLOCK**
   The `HARNESSES` loop scans forward for the first token whose basename is an agent and never stops at the first non-flag token, which is the program. The new tmux branch gets this right (it returns at the first non-agent token); the harness branch does not. Low likelihood, but it is the same defect the tmux fix closed, one branch over.

Noise (not blocks, but real): `pi --help`, `codex`, `time pi --version`, `env FOO=1 pi --help` all fire the report-back warning although nothing is spawned. The isolated runner collapses warn and pass into one verdict, so the suite's `pass` rows for `pi --help` and `codex` hide this.

Real-world check: over **4 165 unique bash commands** recorded in `~/.pi/agent/sessions`, exactly **19 classify BLOCK — all genuine `pi -p` / `nohup pi -p` one-shots**. Zero block false positives on actual traffic.

## 3. The accidental pass (not adversarial)

**`herdr pane run <pane> 'pi -p t'` → pass, all the way through the composed pipeline.** This is not contrived: `herdr pane run` is a live subcommand (`herdr pane --help`: *"run — Run a command in a pane"*), and this machine's own session history contains it twice as the way agents were started (`herdr pane run wC:pF 'PI_SESSION_NAME=mpd-setup pi'`). The cause is structural: `HARNESSES` reads only the token right after the binary, sees `pane`, and returns — every two-level `herdr` subcommand is invisible, and the quoted-command recursion rev3 just added for tmux is not reused here.

Runners-up, same family:

- **`hc exec pi -p x` → pass** (`hc exec --on m pi -p x`, `hc exec bash -c 'pi -p x'` too). `exec` is a first-class, current `hc` subcommand — *"Run one program without a terminal … exactly what it wrote"*, default 60 s timeout — i.e. strictly more fire-and-forget than `hc run --bg`, and it is missing from `SPAWN_SUBCOMMANDS` (`run/new/spawn/agent/start`). This is the sibling the guard's own remediation text ("`hc run --bg pi`") points people away from.
- **`timeout 5 -s KILL pi -p x` → pass.** `skipFlags` runs before the duration is stripped, and the loop restarts only at the wrapper test, so flags placed *after* the duration become the "executable". `timeout -s KILL 5 pi -p x` and `timeout --foreground 5 pi -p x` block correctly; only the post-duration order misses.
- Joined flag forms (`pi --print=x`, `pi -pfoo`, `codex exec --json`) split: the `codex`/`opencode` forms are fine because `exec`/`run` are positional, but `pi --print=x` warns instead of blocking. Not a realistic miss — `pi --print` is a boolean (*"Non-interactive mode: process prompt and exit"*), so `--print=x` is not valid usage; the prompt is positional.
- Already handled, confirmed: `env -i`, `nohup`, `setsid`, `xargs -0 -n1`, and `make agent` (passes correctly — the spawn lives in the Makefile, see §4).

## 4. The documented-gap list — evidence-ranked, one deserves a fix

Counted over the same 4 165-command corpus, commands that *both* match a gap shape *and* contain an agent one-shot: heredoc-into-shell 0, `ssh` 0, `docker`/`podman` 0, `systemd-run` 0, `eval` 1, script file 2, quoted `$()` 6, var/alias 4 — and every non-zero hit is incidental text inside a prompt, not a real spawn. As *accidents a person here would hit*, ranked:

1. **Script file (`bash x.sh`) / `make agent`** — highest. This machine's whole pattern is detached launches, and history has 112 `bash .sh` and 8 `make <target>` invocations. Also genuinely unfixable here: the file is read later and can change between check and run — rev3's reasoning is correct, leave it.
2. **Quoted `$()`** — the only gap worth fixing now. `out=$(pi -p t)` blocks but `out="$(pi -p t)"` does not; the asymmetry is a trap, the case is reachable (104 quoted `$(` commands in history), and the fix is local: when a quoted token contains `$(…)`/backticks, scan just the substitution body. Cost is ~4 lines — and it flips one row rev3 deliberately asserts as `pass` (`echo "$(pi -p t)"`), which must be updated with it.
3. **Vars/aliases** — low and unfixable without dataflow; a script that sets `A=pi` is the script-file gap again.
4. **`eval`** — low; nothing to see statically.
5. **Heredoc-into-shell** — contrived; zero real hits.
6. **`ssh` / `docker run` / `systemd-run`** — zero evidence on this machine, and the stated reason (the remote side picks the binary) is sound.

## 5. The tmux branch is bounded — confirmed

- Bounded: it takes the first non-flag token after the session-creating subcommand, then `return`s — one analysis per command, not one per argument; recursion stays under `MAX_DEPTH 3`.
- Non-spawns pass: `tmux ls`, `tmux attach -t pi`, `tmux new-window`, `tmux new-window -n pi`, `tmux split-window -t pi:0.0`, `tmux new-session -d nvim`, `tmux new-session -d -s pi-watch 'tail -f log'`, `tmux new-session -d -s w -c /home/prm/pi nvim`.
- Spawns block: `tmux new-session -d pi -p x`, `tmux new-session -d 'pi -p x'`, `tmux respawn-pane -k -t w 'pi -p x'`.
- Residual misses, not false positives: `tmux new-session -d bash -c 'pi -p x'` and `tmux new-session -d -e FOO=1 pi -p x` (the first non-agent token is analysed and returned on).

## Findings, one line each

1. `herdr-interactive-only.ts` — `HARNESSES` matches one token, so `herdr pane run <pane> 'pi -p t'` and `hc exec pi -p x` fail open; extend to two-level subcommands (`pane run`) and add `exec`, reusing the tmux quoted-command recursion.
2. `analyze` — keyword skipping makes a never-called function body executable: `f() { pi -p x; }` blocks; either drop grouping shapes from the block path or accept them and document it.
3. `HARNESSES` forward scan — stop at the first non-flag token, as the tmux branch already does (`hc run --bg nvim pi -p x` blocks today).
4. `analyze` timeout loop — strip the duration before `skipFlags`, or re-enter the wrapper loop, so `timeout 5 -s KILL pi -p x` is not inverted.
5. Suite — no `tsconfig` is committed for the `tsc --strict` claim; add it or drop the claim.
