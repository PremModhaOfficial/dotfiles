# FIX-8 rev4 — antagonist review (falsification attempt)

**Verdict: the numbers are real — 94/94, rev1 control 33 failing, tsc shim exit 0 and not a no-op — and the six named attacks land mostly in the code's favour, but rev4 ships two NEW block-class false positives (a `$()` inside a shell comment, and the `exec`/`pane`-exposed agent-argument scan), plus one fail-open the claim implies it closed: a quoted pane payload with `;`/`&&`/`|` is never split, so `herdr pane run wC:pF 'cd /r && pi -p x'` passes — the machine's own launch shape.**

## 1. Claim reproduced — all three parts, measured

| claim | measured |
|---|---|
| `node ~/.agents/loop/fix8/fix8.test.mjs` | `94/94 cases passed (51 isolated, 43 composed)`, **EXIT=0** un-piped |
| rev1 control | `rev1 still fails, exit 1 — 33 cases failing` (11 isolated, 22 composed) |
| `sh ~/.agents/loop/fix8/tsc-check.sh` | **EXIT=0**, tsc `Version 7.0.2`, `--listFiles` resolves the one real file |
| shim is not a no-op | same config against a `/tmp` copy with `const nope: number = "x";` appended → `TS2322` at line 390, **EXIT=1** |

Nothing lost on real traffic — reproduced independently: **4 471** unique bash commands from `~/.pi/agent/sessions`, rev1 vs rev4 → **0** pass→BLOCK, **0** BLOCK→pass (the doc says 4 191; same result, larger corpus).

## 2. New false positives — the seven named probes all pass; two blocks elsewhere are new

All seven named attacks pass, so the reported bug is **not** repeated: `hc exec ls`, `herdr pane run wC:pF nvim`, `hc pane`, `herdr pane`, `echo "$(date)"`, `grep "$(cat f)" file`, `xargs -I{} hc send {} hi`. Also pass: `hc pane ls`, `herdr pane list`, `hc exec`, `hc exec --on m ls`, `hc exec -- 'echo hi'`, `hc exec cat "/tmp/my notes"`, `hc exec nvim "+normal pi"`, `echo "\$(pi -p x)"`, `echo '`pi -p x`'`, `printf '%s\n' '$(pi -p x)'`. The two recursions do not misfire on any of them.

Two **new** ones (rev1 passes, rev4 blocks):

1. **A substitution inside a shell comment now blocks.** `substitutionBodies` does not know about `#`, so text no shell ever runs is executed:
   - `true # echo "$(pi -p t)"` → **BLOCK** (rev1: pass)
   - `# TODO: the guard blocks $(pi -p x) so use hc run` → **BLOCK** (rev1: pass)
   - `ls -la # TODO: echo "$(pi -p t)"` → **BLOCK** (rev1: pass)
   Not in recorded traffic (0 hits in 4 471), but writing a comment *about* the guard is the one comment likely to contain this text.
2. **Adding `exec` to `SPAWN_SUBCOMMANDS` widens the documented over-block into the shape people actually use.** The forward scan was already wrong for `hc run --bg nvim pi -p x` (documented); `exec` and `pane` make it reachable from the form whose first argument is unambiguously a *program*:
   - `hc exec grep -n pi -p f` → **BLOCK** (rev1: pass)
   - `herdr pane run wC:pF grep -n pi -p f` → **BLOCK** (rev1: pass)
   - `hc pane run wC:pF grep -n pi -p f` → **BLOCK** (rev1: pass)
   New noise, same cause: `hc exec ls pi` → **warn** (rev1: pass), `hc exec echo pi` → **warn**.
   For `hc exec` the header's rationale ("guessing which argument is the program reintroduces the fail-open") does not hold — the first non-flag token after `exec` *is* the program, so the scan can stop at it exactly as the tmux branch does. This is a documented decision, but the doc names only the `hc run --bg` instance, and the newly covered instance is 3× broader.

Unchanged, for the record: `pi --help` and `codex` still fire the report-back warning while spawning nothing (isolated rows collapse warn/pass, so the suite cannot see it).

## 3. Recursion bound — terminates, and has one hole

No hang, no blow-up (single process, cold):

| shape | time |
|---|---|
| `hc exec bash -c "bash -c \"pi -p x\""` | 0 ms, blocks |
| 60 nested `hc exec` | 0 ms, blocks |
| 60 nested `"$("` substitutions | 1 ms, blocks |
| 5 000 sibling substitutions (88 KB) | 11 ms |
| 2 000 unclosed `$(` (6 KB) | 3 ms |
| 20 000 nested parens (40 KB) | 21 ms |
| 160 KB heredoc body | 3 ms |
| 5 000 space-containing harness tokens (59 KB) | 13 ms |

`MAX_DEPTH = 3` caps the chain: 12-level `bash -c` nesting returns 0 spawns in 1 ms — a miss, not a hang, and unreachable in practice (bash-guard's own wrapper already consumes one level).

**The hole is segmentation, not depth.** The harness and tmux branches call `analyze(tokenize(token), …)` directly, bypassing `scan`, so only the **first** `;`-segment of a quoted payload is examined:

- `herdr pane run wC:pF 'cd /r && pi -p x'` → **pass** (rev1: pass) — the pane runs the one-shot; the guard never sees it
- `herdr pane run wC:pF 'echo hi | pi -p x'` → **pass**
- `tmux new-session -d 'cd /r && pi -p x'` → **pass** (pre-existing, rev3)
- `herdr pane run wC:pF 'PI_SESSION_NAME=x pi -p t'` → block (single segment, works)

`scan` instead of `analyze` at those two call sites closes it and cannot introduce a new block class.

## 4. Package runners — all five pass, ranked by likelihood here

| runner | verdict | occurrences in 4 471 recorded commands | binary present |
|---|---|---|---|
| `npx` | **pass** silently | **38** — used for `skills`, `hyperframes`, `tsx`, `node-gyp` | yes |
| `bunx` | **pass** silently | **9** — `bunx skills@1.7.0` | yes |
| `pnpm dlx` / `pnpm exec` | **pass** silently | 0 | yes (`pnpm`, `pnpx`, `pnx` all installed) |
| `uvx` | **pass** silently | **1** | yes |
| `deno run` | **pass** silently | 0 | yes |
| `yarn dlx` | **pass** silently | 0 | no |

None of the three wrapper sets knows these names (`WRAPPERS`, `LAUNCHERS`, `HARNESSES`), so `bunx pi -p x`, `npx pi -p x`, `pnpx pi -p x`, `pnx pi -p x`, `uvx pi -p x`, `deno run pi -p x` are invisible. This machine uses `npx`/`bunx` as its normal way to launch third-party CLIs — that is the ranking above, and it is not hypothetical. The form a real launch would take here, `npx -y @earendil-works/pi-coding-agent -p x`, is invisible even to a basename check, because the token is the package name. Same family, also passing: `node /home/prm/.npm-global/bin/pi -p x` and `bun …/pi -p x` (pi's bin is `#!/usr/bin/env node`). Adding `npx`/`bunx`/`pnpx`/`pnx`/`uvx` to `WRAPPERS` costs one line and closes the top four rows.

## 5. Deliberate over-blocks and the gap list — asserted, as claimed

- `hc run --bg nvim pi -p x` → `block` row in **both** suites; `f() { pi -p x; }` → `block` row in the composed suite (test line 235). Isolated keeps only `f() { pi -p x; }\n( pi -p x )` (line 220); the definition-only probe still blocks (and `function build() { … }` too), so the over-block is asserted somewhere, just not in both suites.
- The header's documented-gap block lists all six with reasons: `ssh`/`docker run`/`systemd-run` (the target picks the binary), `eval` (words do not exist until it runs), script files (read later, changeable), heredoc into a shell (stdin data), vars/aliases (run-time values). The suite asserts each as `pass` (ssh, docker, systemd-run, eval, `bash /tmp/spawn.sh`, `bash <<EOS`), so a future "fix" turns the gap into a block and fails the run. Correct design.

## 6. Loads as pi expects — confirmed through the real loader

`discoverAndLoadExtensions([], "/home/prm", "/home/prm/.pi/agent")` → **9 extensions, 0 errors**; the guard's `handlers` map holds `tool_call` with 1 handler; the factory registers `tool_call` only, and `default` is a function under jiti with pi's own aliases (moduleCache off). No top-level side effects: the module body is types, constants and function declarations, and a second import registers nothing. Behaviour through the loaded handler matches `classify`: `pi -p x` block, `hc exec ls` pass, `herdr pane run wC:pF 'pi -p t'` block.

## Findings, one line each

1. `substitutionBodies` — strip `#`-to-end-of-line (outside quotes) before scanning bodies; today `true # echo "$(pi -p t)"` blocks.
2. `analyze` harness/tmux branches — call `scan(tokenize(token), …)`, not `analyze(...)`, so `herdr pane run wC:pF 'cd /r && pi -p x'` blocks.
3. `HARNESSES` forward scan — stop at the first non-flag token for `exec`, where the first positional is definitionally the program (`hc exec grep -n pi -p f` blocks today).
4. `WRAPPERS` — add `npx bunx pnpx pnx uvx` (≤1 line; closes the top four package-runner rows); the `@scope/pkg` form stays a named gap.
5. Suite — `f() { pi -p x; }` alone is asserted only in the composed suite; add the isolated row so both suites pin it.

Skipped: no attempt to fix anything (`Edit nothing`); rev1-vs-rev4 diff re-read only where a finding required it. Risk: findings 1–3 are blocks/misses of commands that never run an agent, so the guard's own remediation text is now reachable only via a form it cannot see.
