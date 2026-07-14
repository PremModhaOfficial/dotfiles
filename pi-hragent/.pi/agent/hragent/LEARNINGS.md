# HRAGENT Learnings & Mistakes

Tracks problems, fixes, and design decisions encountered while building the
herdr + pi-intercom multi-agent orchestration system.

## 2026-07-09 — Initial Design

### Lesson 1: Spawn mechanism
- **Problem:** Assumed `pi --headless` was the way to spawn subagents.
- **Fix:** herdr provides `herdr agent start <name> -- <argv>` — spawns interactive
  panes with proper state tracking. Subagents are always interactive, never headless.
- **Why it matters:** herdr tracks `working`/`blocked`/`idle` per pane. Headless
  sessions don't get herdr lifecycle tracking.

### Lesson 2: Communication model
- **Problem:** Planned for req/reply polling pattern.
- **Fix:** Push-based model with intercom `send` for notifications, `ask` only when
  blocking is needed. Main agent should never poll — subagents push `[DONE]`,
  `[HELP]`, `[FAIL]` etc.

### Lesson 3: Context budget
- **Problem:** Main agent context fills up with subagent messages.
- **Fix:** Use context-mode `ctx_index` to store messages, `ctx_search` to retrieve
  on demand. Keep messages token-efficient with short protocol tags.

### Lesson 4: Session naming
- **Problem:** Subagents need consistent names so intercom routing works.
- **Fix:** `herdr agent start <name>` sets the agent name. Also send `/name <name>`
  via `herdr pane run` to ensure pi session name matches.

### Lesson 5: Tool stack hierarchy
- Context-mode first for processing/indexing
- Intercom for messaging
- herdr for lifecycle/state
- Ponytail for lazy code

### Lesson 6: Spawn via `herdr agent start`
- **Found:** `herdr agent start <name> --cwd PATH -- <argv>` spawns a named,
  interactive agent pane with full herdr lifecycle tracking.
- **Also available:** `herdr pane split` + `herdr pane run` for lower-level control.
- `herdr wait agent-status <pane> --status <state> --timeout MS` blocks until
  agent reaches a state — replaces polling.

### Lesson 7: Canonical herdr SKILL.md
- Official herdr agent skill lives at `herdr.dev/docs/agent-skill/` and on GitHub.
- SKILL.md teaches agents to: inspect workspaces/tabs/panes, split panes,
  spawn agents, read output, wait for state, coordinate.
- Installed via `npx skills add ogulcancelik/herdr --skill herdr -g`.

### Lesson 8: Message protocol design
- **Decision:** Use `[TAG] <from ><to>: message` format — compact, parseable,
  token-efficient.
- Tags: ACK, GO, DONE, FIN, HELP, HUMN, FAIL, BLK, DET, DET?, STAT.
- Push-based: subagents fire `send` for state changes, `ask` only when blocking.
- **Rationale:** Every message is parseable in one glance, no structured JSON
  overhead in intercom messages, main agent never polls.

### Lesson 9: Extension structure for /hragent
- pi commands need a proper extension in `extensions/<name>/` with `package.json`
  and `index.ts`.
- The `/hragent` command handler loads protocol, spawns workers, returns
  orchestration instructions to the main agent.
- The main agent does the actual orchestration following the protocol.
- Extension code is minimal — just spawn + protocol load + instructions.

### Lesson 10: Built-in imports for pi extensions
- `@earendil-works/pi-coding-agent` and `typebox` are provided as built-in imports
  by the pi runtime. No npm install needed for extension deps.
- Extensions in `~/.pi/agent/extensions/<name>/index.ts` are auto-discovered.
- Extension directory format: `extensions/hragent/package.json` + `index.ts`.

### Lesson 11: herdr agent start is the spawn primitive
- `herdr agent start <name> --cwd <path> -- <command>` creates a named,
  interactive agent pane. Supports `--split right|down` and `--no-focus`.
- `herdr wait agent-status <pane> --status idle --timeout MS` replaces polling.
- `herdr pane run <pane> <command>` sends keystrokes (with Enter).
- `herdr agent list` returns JSON with pane info and agent status.

### Lesson 12: Completed build (2026-07-09)
- Created: PROTOCOL.md, spawn.sh, LEARNINGS.md, hragent extension
- Protocol: 10 tags (ACK, GO, DONE, FIN, HELP, HUMN, FAIL, BLK, DET, DET?, STAT)
- Push-based: subagents fire `send`, `ask` only for blocking calls
- `/hragent` command: reads protocol, generates spawn commands, returns
  orchestration instructions to the main agent
- Next step: reload pi and test `/hragent` command

### Lesson 13: Intercom presence doesn't auto-sync on `/name`
- `/name` sets pi's session name but **intercom doesn't refresh presence** until a
  turn starts (`turn_start` handler calls `syncPresenceIdentity`).
- Sending `/name` via `herdr pane run` works (pane shows "Session name set"), but
  intercom still shows the fallback `subagent-chat-...` alias.
- **Fix**: after `/name`, send a non-command message (no leading `/`) to trigger an
  agent turn → intercom syncs presence → worker becomes routable by name.
- Workaround: send the actual task as the first message via `herdr pane run`;
  the turn it triggers syncs the name before the worker starts using intercom.

### Lesson 14: Workers can cross-communicate autonomously
- w2 (context-mode research) sent its report directly to w1 via intercom without
  main agent involvement: `[DONE] context-mode research complete. Report sent to hragent-w1`.
- This confirms the protocol's cross-worker communication works.
- Main agent still needs the final reports — w2's report was shared with w1, not
  back to main. Adjust protocol: **workers always CC main agent on [DONE]**.

### Lesson 15: `herdr pane close` is the teardown primitive
- `herdr pane stop` doesn't exist — tear down workers via `herdr pane close <pane_id>`.
- `herdr pane close` confirms with `{"result":{"type":"ok"}}`.
- After close, `herdr agent list` shows only the main session.

### Lesson 16: First message MUST trigger a turn to sync intercom name
- `/name` sets pi's session name, but `syncPresenceIdentity` only runs on
  `turn_start` and `model_select` (from pi-intercom source), not on name change.
- **Workaround (still valid)**: send a non-command message (the actual task) via `herdr pane run` after
  `/name`. This triggers an agent turn → `syncPresenceIdentity` reads the new name
  → worker becomes routable by name in intercom.
- Added `--task` arg to `spawn.sh` that does this automatically.
- The extension now generates spawn commands WITH `--task` filled in.
- **Root cause fix**: forked `nicobailon/pi-intercom` to
  `PremModhaOfficial/pi-intercom` and added `session_info_changed` handler:
  ```typescript
  pi.on("session_info_changed", (_event, ctx) => {
    if (!getLiveContext(ctx)) { return; }
    const sid = ctx.sessionManager.getSessionId();
    if (sid && client) {
      client.updatePresence({
        ...buildPresenceIdentity(pi, sid),
        status: currentStatus(),
      });
    }
  });
  ```
  This fires immediately when `/name` calls `setSessionName()`, syncing the name
  to the intercom broker without needing a turn trigger.
- Local npm install pinned to fork: `PremModhaOfficial/pi-intercom#5f138e1`.

### Lesson 17: Workers MUST always CC the main agent
- During first run, w2 sent report to w1, not to main. The main agent didn't see it.
- **Fix**: Protocol update — every status message MUST CC main. Cross-worker comms
  are fine but main must be CC'd too.
- Updated PROTOCOL.md with explicit rule and examples.

### Lesson 18: JSON parsing needs exact herdr output path
- `herdr agent start` returns agent info in `result.agent.pane_id`, not
  `result.pane.pane_id`. The spawn script's python parser now tries all 3 paths.

### Lesson 19: Fork management for pi-intercom
- Forked `nicobailon/pi-intercom` → `PremModhaOfficial/pi-intercom` to patch
  the `session_info_changed` gap that upstream hasn't merged.
- **Install**: `package.json` uses `PremModhaOfficial/pi-intercom#<commit>`
  instead of `^0.6.0` from npm registry.
- **Merge upstream updates**:
  ```bash
  cd ~/.pi/agent/pi-intercom
  git remote add upstream https://github.com/nicobailon/pi-intercom.git
  git fetch upstream
  git merge upstream/main
  # resolve conflicts, then:
  git push origin main
  ```
- **Update local install**: update commit hash in `package.json`, run `npm install`.
- Don't PR upstream until the fix is battle-tested.

### Lesson 20: Windows over panes for spawning workers
- **Problem:** Panes share a tab workspace — limited screen real estate, output interleaves, hard to read per-worker output independently.
- **Fix:** Use `--split window` instead of `--split right|down` when spawning workers via `herdr agent start`. Each worker gets its own window with full terminal space.
- **Why it matters:** Independent windows = readable output per worker, no cramming, easier to debug when something goes wrong.

### Lesson 21: Pub-sub only — never use `ask` for worker communication
- **Problem:** `intercom({ action: "ask", ... })` is blocking — it puts the main agent into a wait state. If multiple workers respond or a worker is mid-task, cascading deadlocks occur. Happened during hragent session on 2026-07-14: main got stuck on two simultaneous `ask` calls.
- **Fix:** Use `intercom({ action: "send", ... })` exclusively (fire-and-forget, pub-sub). Workers push all status changes via `[ACK]`, `[GO]`, `[DONE]`, `[FIN]`, `[FAIL]`, `[HELP]`, `[HUMN]`, `[BLK]` — main never polls, never blocks.
- **Result:** Zero deadlocks, workers process in parallel, main stays responsive.
- **Protocol update:** Removed `[DET?]` and `[STAT]` as blocking `ask` patterns. If main needs details, it sends a `[DET?]` as non-blocking `send` and worker replies with `[DET]` when ready.
