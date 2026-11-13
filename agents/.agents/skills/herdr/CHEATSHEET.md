# Herdr cheatsheet — driving agents in named tabs

Rules for this workflow:

1. No manual work — agents execute, this session orchestrates.
2. Work goes through `herdr`.
3. Agents run **interactive** only (real TUI in a pane, never `-p` one-shots).
4. **Yolo** always — `cmd --yolo`.
5. **Named tabs, never panes/splits** — `tab create --label <task-name>`.
6. Only two primitives: **read pane** and **send-keys (+ enter)**.

## The loop

```fish
# 1. named tab (never split); --no-focus keeps the user's focus
set OUT (herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" --label "task-name" --no-focus)
set TAB  (echo $OUT | jq -r '.result.tab.tab_id')
set PANE (echo $OUT | jq -r '.result.root_pane.pane_id')

# 2. launch yolo agent interactively
herdr pane send-text $PANE "cmd --yolo"; herdr pane send-keys $PANE enter
herdr pane wait-output $PANE --match "Command Code v" --timeout 45000

# 3. send work: literal text, THEN enter as a separate key
herdr pane send-text $PANE "<task>"; herdr pane send-keys $PANE enter

# 4. wait for the reply, or read the pane
herdr pane wait-output $PANE --match "<unique-token>" --timeout 90000
herdr pane read $PANE --source recent-unwrapped --lines 120

# 5. close what you created
herdr tab close $TAB
```

## Read sources

| source | use |
|---|---|
| `recent-unwrapped` | default — logs/transcripts, soft wraps joined |
| `visible` | exactly the viewport |
| `recent` | rendered output incl. soft wraps |
| `detection` | the bottom-buffer snapshot Herdr uses for agent detection |

Add `--format ansi` when color is the evidence.

## Quirks (all verified live)

- **`send-keys` takes logical keys only** — `enter`, `esc`, `ctrl+c`, arrows. A word is rejected: `invalid_key: unsupported key hello`. Printable content always goes through **`send-text`**. That is why a submission is `send-text` + `send-keys enter`, two calls.
- `herdr pane run <pane> "<cmd>"` sends text and Enter in one call; fine, but the explicit two-call form is the one to use here.
- **`cmd` is not a startable kind.** `agent start --kind` only lists pi/claude/codex/gemini/… . Herdr still *detects* `cmd` from the pane title, and `agent get` / `agent wait` resolve a name after `agent rename` — but **`agent prompt` rejects it** (`agent_not_ready: not an active named agent`). So drive `cmd` with `pane send-text` / `pane send-keys`, never `agent prompt`.
- **`wait-output` searches the snapshot that already exists**, so it can match your own typed line before the agent answers. Ask for a reply token and split it inside the prompt so the echo can't match — e.g. prompt "join PEN and GUIN with one hyphen" and wait for `PEN-GUIN`.
- `--no-focus` on every create unless the user asked to switch context.
- Long agent output: have the agent write a Markdown file and reply only with the path, then `read_file` it — instead of dumping it into the pane.

## Cleanup

Close every tab you created (`herdr tab close $TAB`) once the run is done; leave the user's tabs untouched. Never close a tab you did not create.
