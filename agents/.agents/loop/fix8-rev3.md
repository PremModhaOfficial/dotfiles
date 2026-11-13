# FIX-8 rev3 — the two defects from the rev2 review, fixed and proven

**Proof (one command):** `node ~/.agents/loop/fix8/fix8.test.mjs` → `74/74 cases passed (39 isolated, 35 composed)`, exit 0; negative control (rev1 code) still fails, 19 cases, exit 1. `tsc --strict` clean; `jiti` load of the real file registers one `tool_call` handler that still blocks on a bash-guard-rewritten command.

## What changed in `~/.pi/agent/extensions/herdr-interactive-only.ts`

| # | defect (rev2 finding) | fix | shape now classified |
|---|---|---|---|
| 1 | Backslash-newline: `tokenize` glued `\`+newline into a token beginning with a newline, so `analyze` gave up | elide `\`+newline before the generic escape branch, so lines join exactly as the shell joins them | `cd /repo && \`⏎`pi -p x`; `pi \`⏎`-p x` still blocks too |
| 2 | Keywords/grouping: `analyze` stopped at the first token | `SHELL_KEYWORDS` skipped in `analyze`'s modifier loop, before the `WRAPPERS` test | `{ pi -p x; }`, `! pi -p x`, `if true; then pi -p x; fi`, `f() { …; }`, `( … )` |
| 3 | Launcher whose agent sits in its argument list (rev2 "named-launcher scan") | bounded branch: `tmux` + a session-creating subcommand (`new`, `new-session`, `new-window`, `split-window`, `respawn-pane`); takes the first agent token, or re-analyses a quoted command string | `tmux new-session -d pi -p x`, `tmux new-session -d 'pi -p t'` |
| 4 | Header overclaimed coverage | header lists every remaining gap with its one-line reason, plus the shapes now covered | — |

`bash-guard.ts` untouched. Negatives checked by hand and unchanged: `tmux ls`, `tmux send-keys -t flow Enter`, `tmux new-session -d -s w bash`, `for`/`while` loops, `{ echo hi; }`, `! true`, `grep -n 'if' f.sh` all classify empty.

Not chased, deliberately: `ssh`, `docker run`, `systemd-run`, `eval`, script files, heredoc-into-shell and quoted `$()`. They are asserted as `pass` below, so a gap cannot silently turn into a block.

## Case table — isolated (`classify()` on the command as typed)

| want | got | ok | spawns | command |
|---|---|---|---|---|
| block | block | true | pi (one-shot) | hc run --bg --name flow-test pi -p 'summarize the diff' |
| block | block | true | claude (one-shot) | claude -p 'fix the tests' > /tmp/out.txt 2>&1 |
| block | block | true | codex (one-shot) | cd /repo && timeout 900 codex exec --full-auto 'add the retry' |
| block | block | true | opencode (one-shot) | opencode run 'bump the version' |
| block | block | true | pi (one-shot) | sudo -u bot env FOO=1 pi --print 'hello' |
| block | block | true | pi (one-shot) | echo 'go' \| xargs -n 1 pi -p |
| block | block | true | codex (one-shot) | codex -m gpt-5-codex exec 'port the auth module' |
| block | block | true | codex (one-shot) | codex --model gpt-5 exec 'x' |
| block | block | true | opencode (one-shot) | opencode --model sonnet run 'x' |
| block | block | true | pi (one-shot) | sudo -E pi -p 'x' |
| block | block | true | pi (one-shot) | bash -c 'hc run --bg pi -p "task"' |
| block | block | true | pi (one-shot) | timeout 600 sudo -u bot pi -p 'x' |
| block | block | true | pi (one-shot) | env -i pi -p 'x' |
| block | block | true | pi (one-shot) | nohup pi -p 'x' & |
| block | block | true | pi (one-shot) | hc run --name=flow pi --print 'x' |
| block | block | true | goose (one-shot) | goose run -t 'x' |
| block | block | true | amp (one-shot) | amp -x 'x' |
| block | block | true | pi (one-shot) | xargs -0 -n1 pi -p |
| block | block | true | pi (one-shot) | true\npi -p 'x' |
| pass | pass | true | pi (interactive) | hc run --bg --name flow-test pi |
| pass | pass | true | claude (interactive) | hc run --bg --name flow-ok claude --model opus |
| pass | pass | true | amp (interactive) | hc run --bg --name amp-test amp |
| pass | pass | true | codex (interactive) | hc run --bg --name flow codex |
| pass | pass | true | goose (interactive) | herdr new --name x goose |
| pass | pass | true | codex (interactive) | codex |
| pass | pass | true | - | grep -n 'NON_INTERACTIVE\\|block' /home/prm/.pi/agent/extensions/herdr-interactive-only.ts \| head |
| pass | pass | true | - | echo 'hc run --bg --name flow-test pi -p' |
| pass | pass | true | - | node -e 'const N=/(?:^\|\s)(?:-p\|--print\|exec)(?:\s\|$)/; console.log(N.test("hc run --bg pi -p"))' |
| pass | pass | true | - | cat > /tmp/spawn-acceptance.sh <<'EOS'\nhc run --bg --name flow-test pi -p 'x'\nEOS |
| pass | pass | true | - | hc send flow-test 'then run pi -p or codex exec, your call' |
| pass | pass | true | - | grep -rn 'codex exec' /home/prm/.agents/AGENTS.md |
| pass | pass | true | - | herdr list \| grep pi |
| pass | pass | true | - | ps aux \| grep -e pi |
| pass | pass | true | - | echo pi -p |
| pass | pass | true | - | python3 -c 'print(1)' |
| pass | pass | true | - | hc send pi 'run it' |
| pass | pass | true | - | docker run --rm pi |
| pass | pass | true | - | cat notes.md \| head -3 |
| pass | pass | true | pi (interactive) | pi --help |
## Case table — composed (bash-guard.ts handler, then herdr-interactive-only.ts handler, one event)

Every row asserts `rewritten=true`: the guard really saw the command after bash-guard's `bash -c '…'` rewrite. `bash-guard.ts -> herdr-interactive-only.ts` is the readdirSync discovery order on this filesystem, and `orderOk` fails the run if that changes.

| want | got | ok | rewritten | command |
|---|---|---|---|---|
| block | block | true | true | cd /repo && pi -p 'summarize the diff' |
| block | block | true | true | cd /repo && claude -p 'fix the tests' |
| block | block | true | true | echo 'go' \| xargs -n 1 pi -p |
| block | block | true | true | hc run --bg --name flow-test pi -p 'summarize the diff' |
| block | block | true | true | claude -p 'fix the tests' > /tmp/out.txt 2>&1 |
| block | block | true | true | opencode run 'bump the version' |
| block | block | true | true | sudo -u bot env FOO=1 pi --print 'hello' |
| block | block | true | true | codex -m gpt-5-codex exec 'port the auth module' |
| block | block | true | true | sudo -E pi -p 'x' |
| block | block | true | true | cd /repo && timeout 900 codex exec --full-auto 'add the retry' |
| block | block | true | true | bash -c 'cd /r && pi -p x' |
| block | block | true | true | sh -c 'true; claude -p x' |
| pass | pass | true | true | grep -n 'NON_INTERACTIVE\\|block' /home/prm/.pi/agent/extensions/herdr-interactive-only.ts \| head |
| pass | pass | true | true | grep -rn 'codex exec' /home/prm/.agents/AGENTS.md |
| pass | pass | true | true | echo 'hc run --bg --name flow-test pi -p' |
| pass | pass | true | true | node -e 'const N=/(?:^\|\s)(?:-p\|--print\|exec)(?:\s\|$)/; console.log(N.test("hc run --bg pi -p"))' |
| pass | pass | true | true | hc send flow-test 'then run pi -p or codex exec, your call' |
| pass | pass | true | true | cat > /tmp/spawn-acceptance.sh <<'EOS'\nhc run --bg --name flow-test pi -p 'x'\nEOS |
| pass | pass | true | true | herdr list \| grep pi |
| warning | warning | true | true | hc run --bg --name flow-test pi |
| warning | warning | true | true | hc run --bg --name flow-ok claude --model opus |
| block | block | true | true | cd /repo && \\npi -p 'summarize the diff' |
| block | block | true | true | { pi -p x; } |
| block | block | true | true | ! pi -p x |
| block | block | true | true | if true; then pi -p x; fi |
| block | block | true | true | f() { pi -p x; }\n( pi -p x ) |
| block | block | true | true | tmux new-session -d pi -p x |
| pass | pass | true | true | ssh box pi -p t |
| pass | pass | true | true | docker run --rm pi -p t |
| pass | pass | true | true | systemd-run --user --scope pi -p t |
| pass | pass | true | true | eval 'pi -p t' |
| pass | pass | true | true | bash /tmp/spawn.sh |
| pass | pass | true | true | bash <<EOS\npi -p t\nEOS |
| pass | pass | true | true | echo "$(pi -p t)" |
| block | block | true | true | bash -c "echo $(pi -p t)" |
New in rev3: the six required rows (`cd /repo && \`⏎`pi -p …`, `{ …; }`, `! …`, `if/then/fi`, function body + subshell, `tmux new-session …`), the 7 documented-gap rows, and one extra `block` row proving an *unquoted* `$(…)` is still seen.

## Negative control

Same file re-run with `FIX8_EXT_DIR=~/.agents/loop/fix8/rev1` (`rev1/herdr-interactive-only.ts` is the reviewed rev1 — no `firstPositional`, `-E` in the shared `VALUE_FLAGS`; `rev1/bash-guard.ts` is a symlink to the real guard). Result: exit 1, **19 failing** — 4 isolated (`codex -m … exec`, `codex --model … exec`, `opencode --model … run`, `sudo -E pi -p`) and 15 composed, all six of the new cases among them. A green run therefore cannot be an artefact of the harness.

## Documented gaps — asserted as `pass` in the suite

| shape | why it cannot be classified statically |
|---|---|
| `ssh box pi -p t`, `docker run --rm pi -p t`, `systemd-run --user --scope pi -p t` | the agent runs on another host, container or unit; that target's own config picks the binary, not the words of this command |
| `eval 'pi -p t'` | the command is assembled at run time from variables and arguments, so the executed words do not exist until eval runs |
| `bash /tmp/spawn.sh` | the commands live in another file, read at run time and changeable after this check |
| `bash <<EOS` … `EOS` | the body is stdin data; text written to a file is indistinguishable from text fed to a shell |
| `echo "$(pi -p t)"` | inside a quoted word the substitution is one opaque token; resolving it needs a shell (an *unquoted* `$(…)` is split into words and is caught — asserted as `block`) |
| `FOO=pi; $FOO -p t`, `alias a=pi; a -p t` | variable and alias values are only known at run time |
