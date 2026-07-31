# hragent — Multi-Agent Orchestration

Spawn and coordinate parallel subagent workers via herdr + pi-intercom.
Use when you need to parallelize work across 2+ agents.

## Files

| File | Purpose |
|------|---------|
| `PROTOCOL.md` | Intercom message format, tags, lifecycle |
| `spawn.sh` | Script to spawn a named worker |
| `LEARNINGS.md` | Accumulated mistakes and fixes |

## Spawning workers

Each worker gets its own **tab** (not panes sharing a tab):

```bash
bash ./spawn.sh "hragent-w1" --cwd "$PWD" --task "your task here"
```

Spawn script does: create tab → `herdr agent start --tab` → `/name` → prepend main agent name to task → send task → print pane_id.
The main agent name is auto-detected via `herdr agent list` and passed as `--main`.
Switch between workers with `Alt+<number>`.

## Communication

**Status updates:** `intercom({ action: "send" })` — fire-and-forget. Workers push `[ACK]`, `[GO]`, `[DONE]`, `[FIN]`, `[FAIL]`, `[BLK]`, `[DET]`. Main never polls.

**Blocking requests:** `intercom({ action: "ask" })` — only for `[HELP]`, `[HUMN]`, `[DET?]` where the sender needs an answer.

### Tags

| Tag | Purpose | Method |
|-----|---------|--------|
| `[ACK]` | Confirm receipt | send |
| `[GO]` | Started working | send |
| `[DONE]` | Subtask done | send |
| `[FIN]` | All done | send |
| `[HELP]` | Needs agent input | ask |
| `[HUMN]` | Needs human decision | ask |
| `[FAIL]` | Irrecoverable failure | send |
| `[BLK]` | Blocked on dependency | send |
| `[DET]` | Extra details | send |
| `[DET?]` | Request details | ask |

### Rules

- **Always CC main** — every message must go to main too.
- **Workers push status** — main never polls, never asks for status.
- `[HELP]`/`[HUMN]`/`[DET?]` are the only `ask` use cases.

## Orchestration (BY_LAW)

Follow the decision trees in PROTOCOL.md `BY_LAW` section strictly:

1. Spawn workers → wait for all [ACK] before proceeding
2. Workers push status — you never poll, never ask for status
3. On [DONE]: send next task if more work, else wait for [FIN]
4. On [FAIL]: retry up to 2 times via send, then report to user
5. On [HELP]/[HUMN]: answer if you can, relay to user if you can't
6. On [FIN] from all workers: summarize, teardown via `herdr pane close <pane_id>`

## Reference

PROTOCOL.md — full message format | LEARNINGS.md — past mistakes | spawn.sh — implementation
