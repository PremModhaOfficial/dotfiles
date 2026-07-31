# hragent Protocol

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

| Tag | Meaning | Used when | Method |
|-----|---------|-----------|--------|
| `[ACK]` | Acknowledge receipt | Subagent got a task | `send` |
| `[GO]` | Started working on | Task begun | `send` |
| `[DONE]` | Subtask complete | A slice is finished | `send` |
| `[FIN]` | Assignment complete | Entire job done | `send` |
| `[HELP]` | Needs agent help | Blocked, need input | `ask` |
| `[HUMN]` | Needs human input | Need user decision | `ask` |
| `[FAIL]` | Task failed | Irrecoverable error | `send` |
| `[BLK]` | Blocked | Waiting on dependency | `send` |
| `[DET]` | Details | Extra info about prior message | `send` |
| `[DET?]` | Request details | Ask for more info | `ask` |

**Fire-and-forget** (`send`): `[ACK]`, `[GO]`, `[DONE]`, `[FIN]`, `[FAIL]`, `[BLK]`, `[DET]`
**Blocking** (`ask`): `[HELP]`, `[HUMN]`, `[DET?]`

---

## BY_LAW — Orchestration rules

These are **mandatory**. The main agent and workers follow these decision trees
on every intercom message. No improvisation.

### HARD RULE: No pane scanning

**NEVER** read herdr panes directly (`herdr agent read`, `herdr pane run`, etc.)
to get worker output. ALL communication goes through intercom.

- Workers push results via `intercom send` — that's the only output channel.
- Main receives results via intercom — that's the only input channel.
- Pane reading is for debugging only, never for orchestration.
- If a worker hasn't sent `[DONE]`/`[FIN]`, it's still working. Don't poll.

**VIOLATION:** Worker doesn't know main's name → can't send results.
**FIX:** spawn.sh prepends main name to task. Worker MUST use that name in all intercom send calls.

```
VIOLATION: herdr agent read <pane> --lines 50  ← WRONG
CORRECT:   wait for intercom message            ← RIGHT
VIOLATION: sleep N && check pane                 ← WRONG
CORRECT:   intercom({ action: "ask", ... })      ← RIGHT
VIOLATION: intercom({ action: "send", to: "main" })  ← WRONG ("main" is not a name)
CORRECT:   intercom({ action: "send", to: "<actual_name>" }) ← RIGHT
```

### Main agent: after spawning workers

```
1. Run all spawn commands (parallel is fine)
2. WAIT for [ACK] from each worker — do NOT proceed until all ACK
3. Once all ACK'd: workers are alive and ready
4. If a worker doesn't ACK within 60s: assume spawn failed, report to user
```

### Main agent: on receiving a message

```
┌─ [ACK] ──── Track: worker is alive. If all ACK'd → workers ready.
│
├─ [GO] ───── Log only. Worker is working. Do nothing.
│
├─ [DONE] ─── Track: this slice is done.
│             ├─ If more tasks for this worker → send next task via send
│             ├─ If no more tasks → do nothing, wait for [FIN]
│             └─ Request details if needed: [DET?] via ask
│
├─ [FIN] ──── Track: worker is fully done.
│             ├─ If ALL workers [FIN] → proceed to teardown
│             └─ Otherwise → wait for remaining workers
│
├─ [FAIL] ─── Retry logic:
│             ├─ Retry count < 2 → re-send task via send: "[RETRY] <main >w: try again, <reason>"
│             ├─ Retry count ≥ 2 → give up, report to user
│             └─ If worker says [BLK] after [FAIL] → it's stuck, report to user
│
├─ [HELP] ─── Worker needs agent input:
│             ├─ You know the answer → reply via send (not ask)
│             ├─ You don't know → relay to user, send worker's question
│             └─ Never ignore [HELP] — worker is blocked until you respond
│
├─ [HUMN] ─── Worker needs human input:
│             ├─ Relay to user immediately
│             ├─ User responds → send answer to worker via send
│             └─ Never answer [HUMN] yourself — it's not your decision
│
├─ [BLK] ──── Worker is blocked on external dependency:
│             ├─ Log only. Worker will unblock itself or send [HELP]/[FAIL].
│             └─ Do NOT poll. Do NOT ask for status.
│
├─ [DET] ──── Details about a prior message:
│             ├─ Process the information
│             └─ Acknowledge if needed: [ACK] via send
│
└─ [DET?] ── Worker requesting details from another worker:
              ├─ If you have the answer → reply via send
              └─ If not → forward to the worker who has it
```

### Main agent: teardown

```
When ALL workers have sent [FIN] or [FAIL]:
1. Summarize results to user
2. Close each worker: herdr pane close <pane_id>
3. Report completion
```

### Worker: lifecycle rules

```
STARTUP:
1. On receiving task → send [ACK] to main immediately
2. Send [GO] to main when you begin actual work
3. Work on your assigned role only

DURING WORK:
4. Send [DONE] to main (and CC cross-workers if relevant) when a slice is done
5. Send [FAIL] to main if you hit an irrecoverable error
6. Send [BLK] to main if blocked on dependency (include what you're waiting on)
7. Send [HELP] via ask to main if you need agent input
8. Send [HUMN] via ask to main if you need human input

COMPLETION:
9. Send [FIN] to main when ALL your work is done
10. Wait for main to close your pane — do NOT self-terminate
```

### Worker: cross-worker communication

```
ALLOWED:
- Send [DONE] to a cross-worker with your output (CC main)
- Send [DET] to a cross-worker with details (CC main)

NOT ALLOWED:
- Do NOT send [HELP] or [HUMN] to cross-workers — always go through main
- Do NOT send tasks to cross-workers — only main assigns tasks
- Do NOT poll cross-workers for status — wait for them to push

RULE: Cross-worker comms are for data sharing, not coordination.
      Main is the single coordinator.
```

### Worker: what NOT to do

```
NEVER:
- Read herdr panes for output (use intercom send only)
- Ask main for status (push only, never poll)
- Send [HELP] to a cross-worker (always main)
- Send [HUMN] to a cross-worker (always main)
- Self-terminate (wait for pane close)
- Send duplicate [DONE] for the same slice
- Send [FIN] before all slices are [DONE]
```

---

## Intercom name sync

pi-intercom syncs the session name to the broker on `turn_start`.
`/name` alone does NOT update intercom presence — a non-command message
must trigger a turn first.

**spawn.sh flow:** `/name` → send task (non-command) → turn starts →
`syncPresenceIdentity` → name syncs → worker routable by name.

## herdr state mapping

| Intercom message | herdr status |
|-----------------|--------------|
| `[GO]` | working |
| `[BLK]`/`[HELP]`/`[HUMN]` | blocked |
| `[DONE]` | idle |
| `[FIN]` | idle → done |
| `[FAIL]` | blocked |

## Intercom tool usage

### Fire-and-forget (status updates)

```typescript
intercom({ action: "send", to: "main", message: "[GO] w1 >main: extracting validate()" })
intercom({ action: "send", to: "main", message: "[DONE] w1 >main: validate() extracted" })
```

### Blocking (needs answer — `[HELP]`, `[HUMN]`, `[DET?]` only)

```typescript
intercom({ action: "ask", to: "main", message: "[HELP] w1 >main: throw or return?" })
// → Reply: return Result
```

### Replying to incoming ask

```typescript
intercom({ action: "reply", message: "return Result, callers already handle it" })
```

## Result retrieval

After `[DONE]`/`[FIN]`, main can request details:

```typescript
intercom({ action: "ask", to: "w1", message: "[DET?] >w1: show changed files" })
intercom({ action: "reply", message: "[DET] >main: src/auth.ts, src/utils/auth-utils.ts" })
```

For large results, `ctx_index` output, then reply with search terms:
```
[DET] >main: indexed as worker-1-auth, search for "changed files"
```
