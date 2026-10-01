---
name: agent-mesh
description: Coordinate multiple CLI LLM agents over NATS — pub/sub, request/reply, and work queues, plus a KV capability registry so agents discover each other's subjects at runtime instead of hardcoding them. Use when asked to have agents talk to each other, fan out work, build a mesh, or use NATS/JetStream for agent IPC.
---

# Agent Mesh

Think WhatsApp for agents. No jargon needed:

- **chat** = private message to one agent (`chat <name> <message>`)
- **group** = message to everyone (`group <message>`)
- **inbox** = read your messages (`inbox`)
- **contacts** = see who is here (`contacts`)

First: run `contacts`, then say hi in `group` with your name so others learn you.
Private messages to you also pop a ping; groups stay silent, read them via `inbox`.
Everything below is the technical reference for how this works underneath.

Agents are just NATS clients. One server, subjects, and the `nats` CLI — no
framework, no agent runtime, no orchestrator. The CLI is the whole API surface.

## Setup

Reboot-proof: the mod ensures the server itself. A fresh PC needs only:

```bash
cmd --yolo -m <model> --mod ~/.agents/skills/agent-mesh/mesh.ts
```

On session start the mod dials `nats://127.0.0.1:4222` (`NATS_URL` overrides it);
if a server answers, the session joins it and touches nothing. If not, the mod
boots its own (`nats-server -js -sd <stable jsdata dir>`) and subscribes.
Two sessions racing both fail the probe and both launch — safe, because the
loser's bind on 4222 fails and it joins the winner's server on the second probe.
The data-dir lock is the backstop: one server ever owns jsdata. No pidfile
(stale after reboot), no refcount — the mod never stops the server, because
peers may still use it. The readiness probe is a real `nats pub` round-trip,
not a TCP open.

The data dir is stable (`~/.agents/skills/agent-mesh/jsdata`), so streams, KV
and the registry survive a reboot. The manual path still exists:

```bash
~/.agents/skills/agent-mesh/mesh.sh up     # pre-warm / inspect / stop
```

## FORBIDDEN BY LAW: the launch line must not set mesh ENV

**Never pass `MESH_SUBJECT`, `MESH_QUEUE`, `MESH_DELIVER` or `NATS_BIN` on the launch line.**
An agent's identity, subjects and delivery mode come from the **KV registry**
(`mesh.instructions` + `mesh.members.<name>`), and the `nats` binary is found by the mod's
**built-in fallback**. Setting these env vars hardcodes exactly what the registry exists to
publish — so a peer can no longer discover the agent, which is the one failure this skill is
built to prevent. Env is an internal override for the mod's own tests, not an API. There is no
situation in which an agent you launch needs it.

Wrong — hardcodes subjects and identity, invisible to the registry:

```bash
MESH_SUBJECT='work.leya.>,agents.leya.>' MESH_QUEUE= MESH_DELIVER=steer \
  NATS_BIN=/abs/path/nats cmd --yolo -m <model> --mod ~/.agents/skills/agent-mesh/mesh.ts
```

Right — identity read from KV, binary found by fallback, subjects discovered at runtime:

```bash
cmd --yolo -m <model> --mod ~/.agents/skills/agent-mesh/mesh.ts
```

Advertising (or joining) is done in KV, never in the environment:

```bash
nats kv get AGENT_STATE mesh.instructions
nats kv put AGENT_STATE "mesh.members.<name>" '{"subject":"work.<W>.<role>.>","queue":"<W>-<role>","model":"<model>"}'
```

## Peers, addressing and the tapes (all learned live)

Use the helper — it resolves from KV, so no subject is ever typed by hand:

```bash
~/.agents/skills/agent-mesh/mesh-peer.sh peers              # registry + live/dead pane per member
~/.agents/skills/agent-mesh/mesh-peer.sh send <to> <msg>    # deliver to <to>'s inbox (from KV)
~/.agents/skills/agent-mesh/mesh-peer.sh drain [me]         # replay work.<W>.<me>.> from WORK
```

- **Delivery is the receiver token.** `work.<W>.<receiver>.<sender>` — `work.leya.audit.leya-rca`
  has receiver `audit`, so it is a *feed*, not a message to anyone. Address a peer with the
  `subject`/`inbox` in `mesh.members.<peer>`; never guess it.
- **IN is receive-only; OUT is best-effort.** IN shows your own sends too (self-echo — you
  subscribe to `work.>`). OUT records a send only when the tool call looks like a publish
  (`nats pub …`, or a variable holding the binary). An empty OUT does **not** mean nothing was
  sent — check the stream.
- **A KV `pane` can be stale or malformed** (`w61-p21` vs the real `w61:p21`). `pane_not_found`
  means the record is old: re-discover with `herdr pane list` before sending keys.
- **Waking a peer:** pane surface only — `herdr pane send-text <pane> '<msg>'`, then
  `herdr pane send-keys <pane> enter` as a separate event.
- **KV keeps history 1**, so any overwrite is invisible and unrecoverable. One writer per key;
  each agent writes only its own `mesh.members.<name>`.

## The one thing to get right: discover, don't hardcode

Agents break when they guess subject names. **Registry first, always.**

An agent that *has* a capability publishes it once:

```bash
nats kv put AGENT_STATE "cap.build" '{"subject":"agents.build","queue":"builders","kind":"workqueue"}'
```

Live pattern (KV-first): read `mesh.instructions`, register `mesh.members.<name>`.
`cap.*` is the same shape for advertising a single capability:

```bash
nats kv get AGENT_STATE "cap.build"
```

A new agent that doesn't know what exists walks the whole registry:

```bash
for k in $(nats kv ls AGENT_STATE | grep '^cap\.'); do
  echo "[$k] $(nats kv get AGENT_STATE "$k" | tail -1)"
done
```

**KV keys cannot contain `:`** — use `.` as the separator (`cap.build`, not
`cap:build`). A colon silently errors as `invalid key`.

## Fan out work (pub/sub)

Everyone listening on a wildcard gets everything. Use for announcements.

```bash
nats sub 'agents.>' --count 5            # listen
nats pub agents.build "artifact-42"      # speak
nats sub 'agents.>' --count 5 --subjects-only   # see names, skip bodies
```

Subjects are dot-separated tokens with wildcards: `a.*.c` is one token wild,
`a.>` is a tail match. `*` matches one token, `>` matches the rest.

## Claim a job (request/reply)

For "do this and tell me the answer" when a specific agent must respond.

```bash
nats reply 'agents.svc.build' --command 'echo "built: $NATS_REQUEST_BODY"'
nats request agents.svc.build "artifact-42"
```

Inside `--command`, the request body is available three ways:
`$NATS_REQUEST_BODY` (env), `{{.Request}}` (template), and `{{1}}`/`{{2}}` to
pull tokens out of the subject when replying on a wildcard like `agents.svc.>`.

`nats request` prints the reply to **stdout** with the payload on the first
line — the diagnostics go after it. Never `tail -1` it; you'll get an empty
line and think it failed.

## Distribute work (work queue)

Many workers, one job each, no duplicates. This is the default for task work.

```bash
# producer side
nats pub agents.build "job-1"

# worker side — same --queue on every worker is what makes it a work queue
nats sub agents.build --queue=builders
```

Verified: 4 jobs across 2 workers delivered 2/2, zero duplicates. The queue
name is the entire coordination mechanism — no central scheduler exists.
Same subject + same queue = split 1:1:1 (scale); different queue per agent = each gets a copy (broadcast).

## Find live traffic (discovery by observation)

The registry says what *should* exist. This says what *is* actually running.

```bash
nats sub '>' --report-subjects --wait 5s
```

Only counts messages **arriving during the window** — if a subject shows 0,
publish something to it and re-run. It is not a historical listing.

## Persistence (JetStream)

Use it when a late-joining agent must see earlier work, or a crashed worker's
job must be redelivered. Otherwise skip it — core NATS is enough for pub/sub,
req/reply, and work queues.

```bash
nats stream add AGENTS --subjects 'agents.>' --storage file --defaults
nats stream add WORK --subjects 'work.>' --storage file --defaults
nats sub 'agents.>' --all --stream AGENTS     # replay everything, any time later
```

Both trees are durable: `agents.>` via AGENTS, `work.>` via WORK. Nothing is
fire-and-forget once a stream covers it.

Streams are bounded (DeepWiki-sourced, live since 2026-09-27): 10k msgs, 100MB,
72h age, 1MB per message, discard-old. `mesh.sh up` recreates them bounded via
`ensure_streams` if missing. `stream edit` needs a TTY for confirmation, so the
headless path is delete (`-f`) + recreate with `--defaults` — back up first,
recreate loses history.

A stream is an append-only log. Any future agent can replay the full history
of a subject with `--all` and no producer running.

For crash-safe work queues, use a durable consumer so unacked jobs get
redelivered. **Create it from a JSON config** — the interactive flags prompt
one at a time and each one fails headlessly:

```bash
cat > wq-consumer.json <<'EOF'
{
  "durable_name": "wq-worker",
  "deliver_policy": "all",
  "ack_policy": "explicit",
  "replay_policy": "instant",
  "max_deliver": 3,
  "filter_subject": "wq.build"
}
EOF
nats consumer add WQ --config wq-consumer.json
nats sub --stream WQ --durable wq-worker --ack
```

When using `--durable`, pass **no subject argument** — the filter already lives
in the consumer. Supplying one errors with `cannot specify both subjects and a
durable consumer`.

## Headless gotchas

Every one of these was hit while building this:

- `nats stream add` / `kv add` prompt for confirmation and die without a TTY.
  Pass `--defaults`.
- `nats consumer add` prompts for *each* setting individually (deliver target,
  replay, max-deliver, max-pending, headers-only, then a bare confirmation).
  Use `--config` instead — one file, no prompts.
- `nats sub --report-subscriptions` renders an empty table in 0.5.0. Use
  `--report-subjects` with real traffic.
- `--count=N` is long-form; `-c` is not accepted on `sub`.
- `nats request` writes the reply to stdout before its own diagnostics.

## Addressing: `work.<W>.<receiver>.<sender>`

One work = one `<W>`. Point-to-point, no guessing:

```bash
nats pub work.abc.orch.human '{"ask":"status"}'   # human -> orch, only orch gets it
nats sub 'work.abc.orch.>' --queue=abc-orch       # orch inbox: all senders to me
nats sub 'work.abc.*.human'                       # audit: everything human sent in this work
```

Broadcast: publish to `work.<W>.all.<sender>`; every member subscribes to
`work.<W>.all.>` alongside its inbox. One extra subject, no fan-out code.
Scale: more workers = same subject + same queue (`--queue=<W>-<role>`), NATS
splits 1:1:1, zero dupes (verified 6/6). Harder work = new role receiver or new
workID, never a bigger parser. Different session/different job = different `<W>`,
full isolation by prefix. Registry: `cap.<W>.<role>` ->
`{"subject":"work.<W>.<role>","queue":"<W>-<role>"}`.
Old `agents.*` still works; new work uses `work.*`.

New `<W>` vs reuse: reuse when the new task reads the same state, continues the
same thread, or answers into the same audit trail — a follow-up, a retry, a
sub-step. New `<W>` when the task stands alone: different goal, different owner,
different lifetime, or a failure you want quarantined from the old trail.
Reusing `<W>` shares history; forking `<W>` contains blast radius. When unsure,
check the stream (`nats sub 'work.<W>.>' --all --stream AGENTS`): if its history
helps the new task, reuse; if it's noise, fork.

## Flow that works

```bash
nats kv get AGENT_STATE mesh.instructions               # identity + subjects live here
nats kv put AGENT_STATE "mesh.members.<name>" '{"..."}' # register self
# subscribe broad, filter by receiver token in-session — no hardcoded subject
```

Verified end to end: registered via KV, broad-subscribed, 3 workers split
3 jobs 1:1:1, no duplicates.

## The mod: `mesh.ts` — receiving inside a running agent

The CLI is the whole API for sending. Receiving needs the mod, which subscribes and injects each
message into the session as `[nats <subject>] <payload>`.

```bash
MESH_SUBJECT=agents.<name> MESH_QUEUE=<name> NATS_BIN=/abs/path/to/nats \
  cmd --mod ~/.agents/skills/agent-mesh/mesh.ts --yolo "…"
```

Env (overrides only; identity lives in KV `mesh.instructions`): `MESH_SUBJECT`
(default broad-sub `work.>,agents.leya.>`), `MESH_QUEUE` (default empty =
broadcast, every agent gets its own copy), `NATS_BIN` (default `nats`, fallback
to the cached binary), `MESH_DELIVER` (`steer`, or `follow-up`). NATS fallback
built in. The footer shows a live tape: `MESH:[ received | in-flight ]`,
newest right, `...` truncates both ends at 100 chars. Same string via the
`mesh_tape` tool (pipeable, state/rendering split).
First message in every session is a bootstrap telling the agent to read KV and
register `mesh.members.<name>` — no env needed to join.

- **Broadcast is the default (no `MESH_QUEUE`): every agent gets its own copy.**
  Set a shared `MESH_QUEUE` only to scale one role (same subject + same queue
  = split 1:1:1).
- **`NATS_BIN` must be absolute** unless the CLI is on PATH — the mod spawns it directly, and a bad
  path fails silently apart from one notify.
- **Delivery does not wake an idle agent.** `steer` lands after the current tool batch; `follow-up`
  only when the run would stop. Both inject into a run, so a message sent to an idle session sits
  in the queue until it next runs. Poke it, or keep it working, if you need it acted on now.
- Multi-line payloads survive intact (fixed 2026-09-27; earlier versions kept only the first line,
  because the parser queued the first payload line and dropped the rest).
- `--mod` is launch-time only and cannot be set from config, so a session already running without
  the mod must be restarted to gain receive.

## Boundaries

- No auth in the default setup — binds `0.0.0.0:4222`. On a shared network use
  `--user`/`--password` or a creds file.
- Core NATS is fire-and-forget: a message sent with no subscriber is gone. That
  is correct for pub/sub, wrong for anything that must not be lost — use a stream.
- JetStream file storage grows on disk. Set limits before pointing it at real data.

## Best practices (from nats-io/nats-server, DeepWiki-confirmed)

- `*` = one token, `>` = tail: inbox `work.<W>.<you>.>`, audit `work.<W>.*.<sender>`.
- Queue group = exactly one member gets each message (core: at-most-once). Our
  exactly-once comes from the shape (one queue per role), not the transport.
- Crash-safe queues need JetStream + `AckExplicit` (unacked work redelivers);
  `DeliverAll` is mandatory for work-queue streams.
- Never overlap `FilterSubject` on partitioned consumers — delivery goes weird.
- One `<W>` per job; a new job is a new prefix, never a flag on an old one.

## DONTs (all bitten live)

- DON'T publish to `*`/`>` — wildcards are subscribe-only, NATS rejects the pub.
- DON'T share one queue across roles — queue group = steal, aim misses.
- DON'T use `:` in KV keys — `invalid key`, use `.` (`cap.build`).
- DON'T `tail -1` a `nats request` — payload is first line, diagnostics last.
- DON'T pass subject + `--durable` — filter lives in consumer, it errors.
- DON'T expect idle wake — steer/follow-up inject into a run only.
- DON'T trust `--report-subscriptions` (0.5.0 empty) — use `--report-subjects` with traffic.
- DON'T `stream add`/`consumer add` headless without `--defaults`/`--config` — prompts die without TTY.
- DON'T use `-c` on `sub` — only `--count`.
- DON'T hardcode subjects — read KV `mesh.instructions` + `mesh.members.*` first.
- DON'T reuse `<W>` — new job = new workID, full isolation.
- DON'T put wildcards in a consumer deliver subject — server rejects it.
- DON'T put `/` or `\` in stream names; durable/consumer names also ban `.`, `*`, `>`.
- DON'T mix durable + ephemeral — ephemeral consumer with a durable name set is invalid; durable name must equal consumer name when both given.
- DON'T hand-publish into `$KV_`, `$OBJ_`, `$JS.API` — use `nats kv`, never raw pub.
- DON'T pull-consume without durable + explicit ack on workqueue streams; push consumers can't set `max_waiting`.
- DON'T enable flow control without heartbeats; DON'T exceed stream replica count on consumers.
- DON'T publish to a topic token (`*.audit.*`, `*.report.*`) and expect a peer to get it — that is a feed, not delivery; send to `mesh.members.<peer>`'s subject.
- DON'T trust a KV `pane` field for waking — re-discover with `herdr pane list`; stale/malformed ids give `pane_not_found`.
- DON'T read an empty OUT tape as "not sent" — OUT is regex best-effort; check the stream.
- DON'T let two writers share a KV key — history is 1, the clobber is silent and unrecoverable.
