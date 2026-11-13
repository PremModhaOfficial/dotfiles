# FIX-8 rev5 — four fixes on top of rev4, no number lost

Files: `~/.pi/agent/extensions/herdr-interactive-only.ts` (owned), `~/.agents/loop/fix8/fix8.test.mjs`.
`bash-guard.ts` untouched.

**Suite: 116/116 (66 isolated, 50 composed), EXIT=0** — rev4's 94 rows all still green, plus 22 new
(15 isolated, 7 composed). **rev1 control still fails, exit 1, 46 rows failing.** `sh tsc-check.sh` exit 0.

## 1. The machine's own shape — chained pane/exec payloads

`analyze` → `scan` at every payload site: the harness quoted-payload recursion, the `tmux` launcher
recursion, and the new program path. `herdr pane run wC:pF 'cd /r && pi -p x'` now blocks (rev4: pass),
likewise `'echo hi | pi -p x'` and `tmux new-session -d 'cd /r && pi -p x'`. Also used at the
`scanText` → substitution-body boundary, so a nested `$()` is judged the same way at every level.

## 2. Two new block false positives

- **Comments**: `stripComments` runs before tokenizing in `scanText`, dropping text after an unquoted
  `#` at a word start (quotes and `x#y` keep it). `true # echo "$(pi -p t)"`, `# TODO: ... $(pi -p x)`,
  `ls -la # ...` pass; a `#` inside quotes is still scanned as before.
- **exec/pane program**: for `exec` and `pane run`, the first positional is the program and analysis
  stops there — `hc exec grep -n pi -p f`, `herdr pane run wC:pF grep -n pi -p f`, `hc pane run wC:pF
  grep -n pi -p f` pass. A quoted payload token is re-tokenized into its `;`/`&&`/`|` segments; an
  argv-style program (`hc exec bash -c 'pi -p x'`) stays one token list, because `hc exec` runs it
  without a shell. `--on` added to `VALUE_FLAGS` so `hc exec --on m pi -p x` still blocks.
  `hc run --bg nvim pi -p x` still blocks: for `run` the agent is a positional argument, not the
  program (`hc run --bg pi` has no program word), so the header's rationale was narrowed, not dropped.

## 3. Package runners

`npx bunx pnpx pnx uvx` join `WRAPPERS` (their package is the binary); `pnpm dlx|exec` and `deno run`
resolve the package after a subcommand. `agentName` strips a `@version` suffix, so `npx pi@1.7.0 -p x`
blocks too. New rows, one per runner: `npx pi -p x`, `bunx pi -p x`, `pnpm dlx pi -p x`,
`uvx pi -p x`, `deno run -A pi -p x` all block; `npx skills@1.7.0` (real traffic, 38 npx uses here)
still passes.

## 4. Recursion bound — not regressed

`MAX_DEPTH = 3` now also bounds `scanText`'s substitution recursion; without it an unclosed `$(` chain
went quadratic (291 ms at 2 000). Measured after the fix (single process, cold):

| shape | time |
|---|---|
| 60 nested `hc exec` | 0.5 ms |
| 60 nested `"$("` | 1.2 ms |
| 2 000 unclosed `$(` | 9 ms |
| 5 000 sibling substitutions (78 KB) | 31 ms |
| 20 000 nested parens (39 KB) | 10 ms |
| 160 KB heredoc | 0.3 ms |
| 5 000 spaced harness tokens (77 KB) | 7 ms |
| 5 000 comment lines with `$(pi -p x)` | 10 ms |

rev4's table was 0–21 ms for the same shapes; the 78 KB synthetic case is ~2.8× rev4 (31 vs 11 ms)
because each substitution body is now comment- and heredoc-stripped. Real commands are < 1 KB, so the
per-command cost stays sub-millisecond.

## Evidence

| claim | measured |
|---|---|
| `node ~/.agents/loop/fix8/fix8.test.mjs` | `116/116 cases passed (66 isolated, 50 composed)`, EXIT=0 |
| rev1 control | `rev1 still fails, exit 1 — 46 cases failing` |
| `sh ~/.agents/loop/fix8/tsc-check.sh` | EXIT=0 |
| corpus (unique bash commands from `~/.pi/agent/sessions`, rev1 vs rev5) | 4 454 commands, **0** pass→BLOCK, **0** BLOCK→pass, 14 blocked by both |

The corpus count drifts (4 444 → 4 454) because this session keeps appending commands while it runs;
the delta to rev1 was zero on every extraction.

## Deliberately left open

- **Scoped package names** (`npx @earendil-works/pi-coding-agent -p x`) and **`npx -c '...'`**: now in
  the header's documented-gap list. A basename check cannot resolve them; it needs a package registry.
- **`pnpm -C dir dlx pi -p x`**: the subcommand is looked up immediately after the runner, not after
  the runner's flags (the five required runners do not need it).
- **Nested substitution depth**: bounded at `MAX_DEPTH + 1` levels, like every other recursion — a
  deeper chain is a miss, not a hang.
- **Pane payload substitutions** (`herdr pane run wC:pF 'echo "$(pi -p t)"'`) are not extracted; a
  pane payload is analysed as a token list, like `bash -c`, not through `scanText`.
- The reviewer's finding 5 is closed: `f() { pi -p x; }` now has an isolated row as well.
