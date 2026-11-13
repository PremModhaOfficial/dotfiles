# FIX-8 rev1 — antagonist review

**Verdict: FIX-8 rev1 does not hold.** The classifier is correct in isolation (16/16 + 20/20 reproduced), but in the real hook pipeline it misses two of its own six block cases, because `bash-guard.ts` loads first, rewrites every command into `bash -c '<command>'`, and `analyze()` never splits that inner text on `;`/`|`/`&&`. `cd /repo && pi -p 'x'` therefore reaches a real fire-and-forget agent silently, with no block and no warning.

## Findings

### F1 (fatal, dangerous direction) — production pipeline misses every spawn that is not the command's first token

`extensions/herdr-interactive-only.ts:179-190` splits segments at top level only; `:148-153` recurses into `bash -c` with a single `analyze()` call, so `cd x && pi -p`, `echo | xargs pi -p` inside `-c` are never seen.

Load order is real: `discoverExtensionsInDir` uses `readdirSync` with no sort (`loader.js:644-665`), `emitToolCall` passes the *same mutated* event through handlers in order (`runner.js:965-980`, docs at `types.d.ts:1106`), and `node -e "readdirSync(...)"` returns bash-guard.ts before herdr-interactive-only.ts. `bash-guard.ts:44-50` mutates `event.input.command` in place, so this hook only ever sees the wrapper.

End-to-end, calling both real handlers in production order on one event:

```
cd /repo && pi -p 'summarize'        -> passed to shell (no block, no warning)
echo x | xargs -n 1 pi -p            -> passed to shell (no block, no warning)
cd /repo && claude -p 'fix'          -> passed to shell (no block, no warning)
hc run --bg --name f pi -p 'x'       -> BLOCKED
```

Reproduced counts: `node /tmp/fix8/prodcount.mjs` → **4/6 of the suite's own block cases still block** once bash-guard has rewritten the command. `guard.test.mjs` and `probes.mjs` never compose the two hooks, so 16/16 and 20/20 are true but test a path the runtime never takes.

This also falsifies the "admitted bypass" framing: this is not a script/heredoc/eval bypass, it is ordinary `cd repo && claude -p ...` while debugging.

### F2 (over-permissive) — `codex -m <model> exec` is a real one-shot and passes

`:112` `args.find(arg => !arg.startsWith("-"))` returns the *value* of the first flag, not the subcommand.

```
codex -m gpt-5-codex exec 'port the auth module'  -> [{"agent":"codex","nonInteractive":false}]  (warn-only)
codex --model gpt-5 exec 'x'                      -> same
opencode --model sonnet run 'x'                   -> same
```

### F3 (over-permissive) — `VALUE_FLAGS` swallows the binary

`:28-36` lists no-value flags as value flags. `sudo -E pi -p x` consumes `pi` as `-E`'s value:

```
sudo -E pi -p x  -> []   (no spawn detected)
```

### F4 (accidental, admitted but understated) — heredoc into a shell is swallowed whole

`stripHeredocs` (`:42-54`) removes the body before `bash` with no `-c` is examined, so `bash <<'EOS'\npi -p 'x'\nEOS` → `[]`. A false heredoc marker in a quoted word (`echo "<<EOF"`) also swallows every following line up to a bare `EOF`, including a real `pi -p`.

## What did hold

- **Load/shape (#3)**: loads under jiti with pi's alias, default export registers one `tool_call` handler, `{block:true, reason}` matches `ToolCallEventResult`. No other extension references `classify` or the old spawn regex (`grep -rn` over `~/.pi/agent/extensions`).
- **Same function (#4)**: the hook calls `classify` at `:195` in the same module the test imports (`guard.test.mjs:18`). No copy. The gap is that the test exercises the function, not the event path.
- **False positives (#5)**: this session's grep (`NON_INTERACTIVE\|block`) and `node -e` with quoted `-p/--print/exec` both yield `[]`. `hc rm t42`, `hc rm --force t42`, `hc kill t42`, `herdr kill t42` all pass without block or warning — the `hc rm` mistake class is not caught (it is not a spawn, so nothing regressed).

## Smallest fix for the worst one (F1)

Make the segment split recursive — every `bash -c` body goes through the same splitter, at every depth:

```ts
function scan(tokens: string[], depth: number, found: Spawn[]): void {
  let segment: string[] = [];
  for (const token of [...tokens, ";"]) {
    if (token === ";") { analyze(segment, depth, found); segment = []; }
    else segment.push(token);
  }
}
```

- `:151` → `scan(tokenize(stripHeredocs(args[cIndex + 1])), depth + 1, found);`
- `:179-190` → `const found: Spawn[] = []; scan(tokenize(stripHeredocs(command)), 0, found); return found;`

Verified on a copy at `/tmp/fix8/fixed.ts`: `guard.test.mjs` 16/16, composed block cases 6/6, `bash -c 'cd /r && pi -p x'` and `sh -c 'true; claude -p x'` now block, `grep -n 'pi -p'`, `hc send x 'then pi -p'`, `node -e` still pass.

Then add one composed regression test (run bash-guard's handler, then this one, same event) covering `cd repo && claude -p 'x'` — otherwise the same class returns. F2/F3 are separate one-liners (skip flag values when locating the subcommand; split `-E`/`-e`/`-n`/`-a`/`-s`/`-d` per wrapper) and should not be bundled into this fix.
