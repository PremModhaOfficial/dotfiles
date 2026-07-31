# HRAGENT Learnings

Problems, fixes, and design decisions for the herdr + pi-intercom multi-agent system.

### Lesson 1: herdr agent start is the spawn primitive
- `herdr agent start <name> --cwd PATH -- --tab ID -- <argv>` spawns named interactive panes with lifecycle tracking.
- `herdr wait agent-status <pane> --status idle --timeout MS` replaces polling.
- `herdr pane run <pane> <command>` sends keystrokes. `herdr agent list` returns JSON with pane info.
- Headless (`pi --headless`) doesn't get herdr lifecycle tracking — always use interactive panes.

### Lesson 2: Tabs over panes for workers
- Panes share a tab — cramped, output interleaves. `--split` only supports `right|down`.
- **Fix:** `herdr tab create` → `herdr agent start --tab <tab_id>`. Each worker gets its own tab.
- Tabs are navigable (`Alt+<number>`), full space, herdr-native.

### Lesson 3: Pub-sub only — never `ask`
- `intercom({ action: "ask" })` blocks — multiple responses or mid-task workers cause cascading deadlocks.
- **Fix:** `intercom({ action: "send" })` exclusively. Workers push `[DONE]`, `[FAIL]`, `[HELP]` etc.
- `[DET?]` and `[STAT]` are non-blocking sends, never asks.

### Lesson 4: Session naming requires a turn to sync
- `/name` sets pi's session name but intercom doesn't refresh until a turn starts (`syncPresenceIdentity`).
- **Fix:** Send the actual task after `/name` — the turn it triggers syncs the name.
- Forked `nicobailon/pi-intercom` → `PremModhaOfficial/pi-intercom` to add `session_info_changed` handler that syncs immediately.

### Lesson 5: Workers must always CC main
- Workers cross-communicating without CC'ing main means main loses visibility.
- **Rule:** Every status message goes to main. Cross-worker comms fine but CC main too.

### Lesson 6: JSON parsing — check the right paths
- `herdr agent start` returns pane_id at `result.agent.pane_id`, not `result.pane.pane_id`.
- `herdr tab create` returns tab_id at `result.tab.tab_id`.
- Use `jq` with fallbacks: `.result.agent.pane_id // .result.pane.pane_id // .pane_id`.

### Lesson 7: Extension structure
- Extensions live in `~/.pi/agent/extensions/<name>/` with `package.json` + `index.ts`.
- `@earendil-works/pi-coding-agent` is a built-in import — no npm install.
- The `/hragent` handler loads protocol, spawns workers, returns orchestration instructions. Main agent does the actual orchestration.

### Lesson 8: Fork management for pi-intercom
- Forked `nicobailon/pi-intercom` → `PremModhaOfficial/pi-intercom` for the `session_info_changed` patch.
- Update: change commit hash in `package.json`, run `npm install`.
- Merge upstream: `git remote add upstream ... && git fetch upstream && git merge upstream/main`.

### Lesson 9: Context budget
- Main agent context fills with subagent messages. Use context-mode `ctx_index` to store, `ctx_search` to retrieve.
- Keep protocol tags short and token-efficient.

### Lesson 10: Teardown
- `herdr pane close <pane_id>` — that's the teardown primitive. `herdr pane stop` doesn't exist.
- After close, `herdr agent list` shows only main session.
