# FIX-8 rev2 — antagonist review

**Verdict: the numbers are real, the claim is not.** `node ~/.agents/loop/fix8/fix8.test.mjs` reproduces exactly (60/60, exit 0, tsc strict clean, jiti load OK), and the negative control reproduces too (rev1 → 35/39 isolated, 13/21 composed). But "the spawn guard now works in the real pipeline" is false: two ordinary one-shots reach a shell silently through the composed path, one of them a line continuation — the way agents and humans actually wrap long commands.

## Evidence per point

1. **Their command, run myself.** `60/60 cases passed (39 isolated, 21 composed)`, exit 0. `npx --no-install tsc -p /tmp/fix8/tsconfig.json` → exit 0, no output. `node /tmp/fix8/jitiload.mjs` → one `tool_call` handler registered, `block: true`. All three sub-claims hold.
2. **Negative control exists and fails as claimed.** `/tmp/fix8/rev1dir/herdr-interactive-only.ts` (identical to `/tmp/fix8/rev1-true.ts`) run under `FIX8_EXT_DIR`: **35/39 isolated** (fails exactly the four F2/F3 cases: `codex -m … exec`, `codex --model … exec`, `opencode --model … run`, `sudo -E pi -p`), **13/21 composed**, `48/60`. Provenance is sound, not a strawman: rev1-true.ts lacks `firstPositional` and has `-E` in the shared `VALUE_FLAGS`, matching `fix8-review.md` (written 12:05, before rev2 at 12:07) line for line. (The stray `/tmp/fix8/rev1.ts` is an intermediate F3-only attempt, not the reviewed rev1.)
3. **Composed harness is faithful, with one soft assertion.** It really loads both real files by `readdirSync` order and drives the *same mutated event object*, and `dist/core/extensions/runner.js:965-980` does exactly that (`snapshotEventHandlers` keeps `extensions` order, `result.block` short-circuits) — the loop is re-implemented but line-for-line equivalent, not a convenient reorder. Order is right on this fs (`bash-guard.ts -> herdr-interactive-only.ts`) and `orderOk` fails the run if it changes. Caveat: each row asserts `guardSaw !== command`, i.e. *non-identity*, not `bash -c` — a valid proxy here because bash-guard's only mutation is that wrapper, but the test would not notice a different rewrite. No live pi session was exercised: the proof is handler-level, not a real spawn.
4. **Real survivor found, in the composed path.** `cd /repo && \`⏎`pi -p 'summarize the diff'` → **passes both handlers, no block, no warning** (`rewritten=true`, `classify → []`). Root cause: `tokenize` turns `\`+newline into a glued token (`"\npi"`), so `base(token)` is not an agent and `analyze` returns. Backslash continuations are how multi-line shell commands are normally written, so this is the accidental shape, not a construction. Same file, other survivors with the same "first token unknown ⇒ give up" root cause: `{ pi -p x; }`, `! pi -p x`, `if true; then pi -p x; fi`, `tmux new-session -d -s w 'pi -p t'`, `systemd-run --user --scope pi -p t`, `ssh box pi -p t`, `npx pi -p x`. The header comment's blind-spot list (scripts, heredoc-into-shell, `$()` in double quotes, eval/vars) does not mention any of these, so the doc now overstates coverage.
5. **No regressions observed.** In the composed path: `grep -rn 'pi -p'`, `echo 'claude -p and codex exec'`, `node -e …`, heredoc-to-file, `hc send flow-test 'run pi -p …'`, `ps aux | grep -e pi`, `awk '{print "pi -p"}'`, `ls | xargs -n 1 echo pi -p` all pass silently; bare `pi` gives `warning`, not block; `hc send` to a peer is untouched. False-positive surface is genuinely clean.

## Two most dangerous survivors

1. Line continuation — most likely accident, silent, verified end-to-end:
   ```
   cd /repo && \
   pi -p 'summarize the diff'
   ```
2. Unlisted launcher / compound form — one shell syntax people and agents both emit:
   ```
   { pi -p 'fix the tests'; }
   ```
   (same hole: `! pi -p x`, `if true; then pi -p x; fi`, `tmux new-session -d 'pi -p t'`, `systemd-run --user --scope pi -p t`)

## Smallest fix

In `tokenize`, elide a line continuation before the generic escape branch — lines then join as the shell joins them (`pi \`⏎`-p x` still blocks, `cd /repo && \`⏎`pi -p x` now blocks):

```ts
if (ch === "\\" && command[i + 1] === "\n") { i++; continue; }
```

And in `analyze`'s modifier loop, skip shell keywords before the `WRAPPERS` test, so a compound command is not abandoned at its first token:

```ts
const SHELL_KEYWORDS = new Set(["{", "}", "!", "if", "then", "else", "elif", "fi", "do", "done", "while", "until", "for", "case", "esac"]);
...
if (SHELL_KEYWORDS.has(token)) { i++; continue; }
```

Launchers (`tmux`, `systemd-run`, `ssh`, `npx`) cannot be fixed the same way — the agent sits in their argument list, not at a positional — so either add a named-launcher scan or, at minimum, add them to the header's blind-spot list. The header currently claims more coverage than the code has.
