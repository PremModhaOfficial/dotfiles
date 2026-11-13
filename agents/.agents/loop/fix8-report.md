# FIX-8 rev 1 — herdr-interactive-only guard: parse the command, not the words

File: `~/.pi/agent/extensions/herdr-interactive-only.ts` (single file, TypeScript, no commit).
Test: `/tmp/fix8/guard.test.mjs` (classifier), plus `/tmp/fix8/probes.mjs` (adversarial pass).

## What changed

Before: two regexes over the whole command string — `hc run|herdr … (pi|claude|codex|opencode|goose|amp)`
plus `-p|--print|exec` anywhere. Any argument or heredoc body that *mentioned* a spawn matched.

After: a small shell-aware parser, exported as `tokenize()` and `classify()` so it is testable.

1. `stripHeredocs()` removes `<<'EOS' … EOS` bodies — they are data, not commands.
2. `tokenize()` splits into words and `;` segment boundaries, tracking single/double quotes and
   backslash escapes; drops redirects and their targets (`>`, `>>`, `2>&1`, `<<WORD`), so `2>&1` no
   longer contributes tokens and a quoted `"hc run pi -p"` stays one argument.
3. `classify()` walks each segment, skipping env prefixes (`FOO=1`), wrappers (`env`, `sudo`, `doas`,
   `timeout`, `xargs`, `nice`, `nohup`, `stdbuf`, `setsid`, `time`, `exec`, `command`) and their
   flag values (`sudo -u bot`, `xargs -n 1`, `--name flow-test`, `timeout 600`), then takes the token
   at the position of the **executed binary**.
4. Recurses into `bash -c '<payload>'` (depth ≤ 3).
5. Spawn is recognised only when that binary is an agent CLI, or when it is `hc`/`herdr` with a
   spawn subcommand (`run|new|spawn|agent|start`) and an agent name as a positional argument —
   `hc send pi '…'` and `herdr list` are no longer spawns.
6. Non-interactive is decided per agent: `pi`/`claude` `-p`/`--print`; `codex` positional `exec`;
   `opencode`/`goose` positional `run`; `amp` `-x`/`--execute`/`-p`/`--print`.
7. Block reason now names the agent and the flag it was flagged for. The report-back warning is kept
   and applies to real interactive spawns (`hc run --bg … pi`); it is silent for `hc send`, `grep`,
   `echo`, `node -e`, and heredoc bodies. Warning severity fixed to `"warning"` (was invalid
   `"warn"`; `tsc --strict` was failing on it). `tsc -p` on the file is now clean.

## Case table (`/tmp/fix8/guard.test.mjs`)

| # | expect | command | spawns found |
|---|--------|---------|--------------|
| 1 | block | `hc run --bg --name flow-test pi -p 'summarize the diff'` | pi (one-shot) |
| 2 | block | `claude -p 'fix the tests' > /tmp/out.txt 2>&1` | claude (one-shot) |
| 3 | block | `cd /repo && timeout 900 codex exec --full-auto 'add the retry'` | codex (one-shot) |
| 4 | block | `opencode run 'bump the version'` | opencode (one-shot) |
| 5 | block | `sudo -u bot env FOO=1 pi --print 'hello'` | pi (one-shot) |
| 6 | block | `echo 'go' \| xargs -n 1 pi -p` | pi (one-shot) |
| 7 | pass | `hc run --bg --name flow-test pi` | pi (interactive) |
| 8 | pass | `hc run --bg --name flow-ok claude --model opus` | claude (interactive) |
| 9 | pass | `hc run --bg --name amp-test amp` | amp (interactive) |
| 10 | pass | `grep -n 'NON_INTERACTIVE\|block' ~/.pi/agent/extensions/bash-guard.ts \| head` | – |
| 11 | pass | `echo 'hc run --bg --name flow-test pi -p'` | – |
| 12 | pass | `node -e 'const N=/(?:^\|\s)(?:-p\|--print\|exec)(?:\s\|$)/; …'` | – |
| 13 | pass | `cat > /tmp/spawn-acceptance.sh <<'EOS'` + body `hc run --bg --name flow-test pi -p 'x'` | – |
| 14 | pass | `hc send flow-test 'then run pi -p or codex exec, your call'` | – |
| 15 | pass | `grep -rn 'codex exec' ~/.agents/AGENTS.md` | – |
| 16 | pass | `herdr list \| grep pi` | – |

## Output

```
$ cd /tmp/fix8 && node guard.test.mjs
want   got   ok    spawns                       command
block  block true  pi (one-shot)                hc run --bg --name flow-test pi -p 'summarize the diff'
block  block true  claude (one-shot)            claude -p 'fix the tests' > /tmp/out.txt 2>&1
block  block true  codex (one-shot)             cd /repo && timeout 900 codex exec --full-auto 'add the re
block  block true  opencode (one-shot)          opencode run 'bump the version'
block  block true  pi (one-shot)                sudo -u bot env FOO=1 pi --print 'hello'
block  block true  pi (one-shot)                echo 'go' | xargs -n 1 pi -p
pass   pass  true  pi (interactive)             hc run --bg --name flow-test pi
pass   pass  true  claude (interactive)         hc run --bg --name flow-ok claude --model opus
pass   pass  true  amp (interactive)            hc run --bg --name amp-test amp
pass   pass  true  -                            grep -n 'NON_INTERACTIVE\|block' /home/prm/.pi/agent/exten
pass   pass  true  -                            echo 'hc run --bg --name flow-test pi -p'
pass   pass  true  -                            node -e 'const N=/(?:^|\s)(?:-p|--print|exec)(?:\s|$)/; co
pass   pass  true  -                            cat > /tmp/spawn-acceptance.sh <<'EOS'\nhc run --bg --name
pass   pass  true  -                            hc send flow-test 'then run pi -p or codex exec, your call'
pass   pass  true  -                            grep -rn 'codex exec' /home/prm/.agents/AGENTS.md
pass   pass  true  pi (interactive)             herdr list | grep pi

16/16 cases passed
```

Adversarial probes (`node probes.mjs`, 20/20): blocks `bash -c 'hc run --bg pi -p …'`,
`timeout 600 sudo -u bot pi -p`, `env -i pi -p`, `nohup pi -p &`, `hc run --name=flow pi --print`,
`goose run -t`, `amp -x`, `xargs -0 -n1 pi -p`, newline-separated `pi -p`; passes `pi --help`,
`ps aux | grep -e pi`, `grep -rn 'hc run --bg pi' .`, `echo pi -p`, `python3 -c`, `herdr new --name x goose`,
`hc send pi 'run it'`, `docker run --rm pi`.

`tsc -p tsconfig.json` (paths mapped to the installed pi package): no errors.

## What still bypasses the guard

- Script files: `bash /tmp/spawn.sh`, `./spawn.sh`, `npx whatever` — the file contents are not read.
- Heredoc bodies piped into a shell: `bash <<'EOS' … pi -p … EOS` (bodies are treated as data).
- `$(...)` / backticks inside double quotes (`echo "$(pi -p x)"`); unquoted `$(pi -p x)` does block.
- Variables and aliases: `A=pi; $A -p x`, `alias go='pi -p'`, `eval "pi -p x"`.
- Wrapper binaries not in the wrapper set (`docker run … pi -p`, `flock`, `systemd-run`).
- A wrapper value that is itself an agent name after an unknown value flag could be misread (all
  swallows are listed in `VALUE_FLAGS`).
- `pi --print=x`-style joined forms are not matched.
