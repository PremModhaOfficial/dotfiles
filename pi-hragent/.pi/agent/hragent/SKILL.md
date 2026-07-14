# hragent — Multi-Agent Orchestration

Spawn and coordinate parallel subagent workers via herdr + pi-intercom.
Use when you need to parallelize work across 2+ agents (research, code review,
implementation slices).

## Files

| File | Purpose |
|------|---------|
| `PROTOCOL.md` | Intercom message format, tags, lifecycle |
| `spawn.sh` | Script to spawn a named worker |
| `LEARNINGS.md` | Accumulated mistakes and fixes |

## Spawning workers

Always use **windows** (not panes):

```bash
bash ./spawn.sh "hragent-w1" --cwd "$PWD" --split window --task "your task here"
```

`--split window` gives each worker its own terminal window with full space.
Panes (--split right|down) share a tab — cramped, hard to read per-worker output.

The spawn script:
1. Calls `herdr agent start` with the name and task
2. Sends `/name <name>` to set the pi session name
3. Sends the task (non-command) to trigger a turn → syncs intercom name
4. Prints the pane_id on stdout

## Communication — Pub-sub only, never `ask`

**Only use `intercom({ action: "send", ... })`** (fire-and-forget).
Never use `intercom({ action: "ask", ... })` — that blocks and causes deadlocks
when multiple workers respond or a worker is mid-task.

### Tags

| Tag | Purpose | When |
|-----|---------|------|
| `[ACK]` | Confirm receipt | Worker got a task |
| `[GO]` | Started | Task begun |
| `[DONE]` | Subtask done | A slice finished |
| `[FIN]` | All done | Entire job complete |
| `[HELP]` | Needs agent input | Blocked (non-blocking send) |
| `[HUMN]` | Needs user input | Need a human decision |
| `[FAIL]` | Irrecoverable | Task failed |
| `[BLK]` | Blocked | Waiting on external dependency |
| `[DET]` | Details | Extra info about prior message |

### Rules

- **Always CC main** — every status message must be sent to main.
  Cross-worker comms are fine but main must see them too.
- **Workers push** — main never polls, never asks for status.
  Workers fire `[DONE]`, `[FAIL]`, `[HELP]` etc when they happen.
- **`[DET?]` and `[STAT]` are non-blocking `send`** — never `ask`.
  Worker replies with `[DET]` when it has the info.

## Orchestration pattern

1. Spawn workers via `spawn.sh` with `--split window` and `--task`
2. Wait for each to push `[DONE]` / `[FIN]` via intercom `send`
3. On `[HELP]`/`[HUMN]` → relay to user or reply via `send`
4. On `[FAIL]` → retry up to 2 times, then report to user
5. Teardown: `herdr pane close <pane_id>` for each worker

## herdr lifecycle mapping

| Intercom message | herdr status |
|-----------------|--------------|
| `[GO]` | working |
| `[BLK]`/`[HELP]`/`[HUMN]` | blocked |
| `[DONE]` | idle |
| `[FIN]` | idle → done |
| `[FAIL]` | blocked |

## Reference

- PROTOCOL.md — full message format details
- LEARNINGS.md — past mistakes and why patterns are what they are
- spawn.sh — the spawn implementation
