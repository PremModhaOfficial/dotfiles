# hragent Protocol — Intercom message format

Subagents talk to each other and the main agent via `pi-intercom`.
Every message follows a strict tag format so the receiver can parse it in
one glance without loading a full conversation.

## Message format

```
[TAG] <from> ><to>: <message>
```

- `[TAG]` — one of the tags below, always uppercase, bracketed.
- `<from>` — the sender's session name (optional for direct replies).
- `><to>` — the target session name (optional for broadcast).
- `<message>` — the payload. Keep it under 200 chars. Use `[DET]` for details.

## Tags

| Tag | Meaning | Used when |
|-----|---------|-----------|
| `[ACK]` | Acknowledge receipt | Subagent got a task |
| `[GO]` | Started working on | Task begun |
| `[DONE]` | Subtask complete | A slice is finished |
| `[FIN]` | Assignment complete | Entire job done, awaiting next or exit |
| `[HELP]` | Needs agent help | Blocked, need input from another agent |
| `[HUMN]` | Needs human input | Need user decision |
| `[FAIL]` | Task failed | Irrecoverable error |
| `[BLK]` | Blocked | Waiting on external dependency |
| `[DET]` | Details | Additional info about a prior `[DONE]`/`[FAIL]`/etc |

> **No blocking tags.** All communication is pub-sub via `intercom send`. Never use `ask`.

## Push-based lifecycle

Subagents **push** state changes. The main agent never polls.

### Rule: Always CC the main agent

Every status message (`[GO]`, `[DONE]`, `[FIN]`, `[FAIL]`, `[HELP]`, `[HUMN]`, `[BLK]`)
MUST be sent to the main agent. The main agent is the single source of truth for
the global state. Cross-worker communication is fine but must **also** CC the main.

```
[DONE] <w1 >main: refactored auth.ts        ← CC main
[DONE] <w1 >w2: here's my output, see above  ← cross-worker, still CC main:
[DONE] <w1 >main: cross-worker: sent output to w2
```

### Intercom name sync (important!)

pi-intercom only syncs the session name to the broker on `turn_start` (when an agent
turn begins). Setting the name via `/name` does NOT automatically update intercom
presence. A non-command message must be sent to trigger a turn first.

**Fix in spawn.sh:** The `--task` argument sends the task via `herdr pane run` after
`/name`. This non-command message triggers a turn → `syncPresenceIdentity` →
worker becomes routable by name in intercom.

### Startup sequence

```
1. Spawn:    herdr agent start hragent-w1 -- env TERM=xterm-256color pi
2. Name:     herdr pane run <pane> "/name hragent-w1"
             → pi receives "/name" command. Name set but NOT yet in intercom.
3. Task:     herdr pane run <pane> "Research feature X and report findings"
             → pi receives task as user input → triggers agent turn
             → turn_start → syncPresenceIdentity → name syncs to broker
             → agent starts working → reports results via intercom
             ← Now routable: intercom({ action: "send", to: "hragent-w1", ... })
```

Subsequent communication goes through intercom only.

### Normal flow

```
             Main → pane run: task description (triggers turn, syncs name)
Subagent → Main: [ACK] <w1 >main: got it
Subagent → Main: [GO] <w1 >main: extracting validate() to auth-utils.ts
Subagent → Main: [DONE] <w1 >main: validate() extracted
Subagent → Main: [FIN] <w1 >main: auth refactor done, 3 files changed
             Main → pane run: (next task starts a new turn)
Subagent → Main: [ACK] <w1 >main: got it
```

### Cross-worker with CC

```
Subagent w1 → w2: [DONE] <w1 >w2: my analysis is ready
Subagent w1 → Main: [DONE] <w1 >main: cross-worker: sent analysis to w2
             Main → w1: [ACK] <main >w1: noted
```

### Error flow

```
Subagent → Main: [FAIL] <w1 >main: tests failing, auth-utils.ts:42 type error
   Main → Subagent: [DET?] <main >w1: show the error
Subagent → Main: [DET] <w1 >main: TypeError: User | null not assignable to User
```

### Help flow (blocking `ask`)

```
Subagent → Main: [HELP] <w1 >main: should validate() throw or return Result?
   Main → Subagent: return Result, callers already handle it
```

### Human needed (blocking `ask`)

```
Subagent → Main: [HUMN] <w1 >main: API key for staging?
   Main → You: worker-1 needs API key for staging
```

## Intercom tool usage

### Fire-and-forget (notifications)

```typescript
intercom({ action: "send", to: "planner", message: "[GO] w1 >main: extracting validate()" })
intercom({ action: "send", to: "planner", message: "[DONE] w1 >main: validate() extracted" })
intercom({ action: "send", to: "main", message: "[DONE] w1 >main: cross-worker: sent output to w2" })
```

### Blocking (needs answer)

```typescript
intercom({ action: "ask", to: "planner", message: "[HELP] w1 >main: should this throw or return?" })
// → Reply from planner: return Result
intercom({ action: "ask", to: "w2", message: "[DET?] w1 >w2: what did you return?" })
// → Reply from w2: [DET] w2 >w1: { status: "ok" }
```

### Replying to incoming

```typescript
// Inside the turn triggered by an incoming intercom ask:
intercom({ action: "reply", message: "return Result, callers already handle it" })
```

## herdr state mapping

Intercom status is mapped to herdr agent status automatically by `pi-intercom`.
Subagents don't need to manually report state to herdr.

| Intercom message | herdr status |
|-----------------|--------------|
| `[GO]` | working |
| `[BLK]` | blocked |
| `[HELP]` | blocked |
| `[HUMN]` | blocked |
| `[DONE]` | idle |
| `[FIN]` | idle → done |
| `[FAIL]` | blocked |

## Result retrieval

After `[DONE]`/`[FIN]`, the main agent can request details:

```typescript
// Ask for details
intercom({ action: "ask", to: "w1", message: "[DET?] >w1: show changed files" })

// Subagent replies with context-mode indexed results
intercom({ action: "reply", message: "[DET] >main: src/auth.ts, src/utils/auth-utils.ts" })
```

For large results, subagents can `ctx_index` their work output, then reply with
search terms:

```
[DET] >main: indexed as worker-1-auth-refactor, search for "changed files"
```
