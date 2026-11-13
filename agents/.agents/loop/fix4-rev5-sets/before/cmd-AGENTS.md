# Memory

## Herdr integration (commandcode.integration plugin)

- Herdr agent-detection overrides for cmd live under `~/.config/herdr/plugins/config/commandcode.integration/agent-detection/cmd.toml`; global herdr reads remote manifests from `~/.local/state/herdr/agent-detection/remote/`.
- Status reporting is driven by the herdr-status.sh hook (SessionStart/PreToolUse/PostToolUse/Stop) in `~/.commandcode/settings.json`; it no-ops outside herdr (`HERDR_ENV != 1`).
- Debug with `herdr agent list` and `herdr pane process-info --pane <id>`; reload manifests via `herdr server reload-agent-manifests`.

## Background sub-agent wake-up (proven against cmd 1.88.2, 2026-11-02)

Built-in gap: a background sub-agent (`agent` tool, `run_in_background: true`, or agent file `background: true`) completes without waking the loop — the feed only gets a "Background agent finished: … (Ns | N tokens)" row (TUI settleBackgroundAgentRow). Monitors get a wake-up (`useMonitorOutputWakeup`), sub-agents do not.

Proven close-the-gap recipe (mod, not hooks — settings.json hooks only get PreToolUse/PostToolUse/Stop/SessionStart):
- `cmd.on('subagent_start')` payload carries `toolCallId`, `subagentType`, `background` — key background launches by toolCallId (do NOT parse the agent tool result).
- `cmd.on('subagent_stop')` fires for detached runs even while the session is idle (session-scoped event bus; mod host binds once per session; emission is `manager.wait().then(emit)` from the launch site). Payload: `{toolCallId, subagentType, tokensUsed, status?}`.
- Wake with `cmd.sendUserMessage(text)` (idle → host `submitUserMessage` → new turn; running → host queues/steers) or `cmd.prompt.submit(text)` (TUI `useModPromptWakeup` → automated user message). `cmd.queueMessage`/`deliverAs` queues NEVER start a turn — headless they degrade to a silent queue push.
- Mods cannot invoke `agent_output` (no tool seam in ModApi) — the wake text must instruct the model to collect.
- Background manager is in-memory, per-session (`bg-<n>-<8hex>` ids); `agent_output` wait/status/list return the stored outcome for the session's lifetime; nothing persists across exit.
- Empirical proof (pty-driven TUI, probe mod): run_end → subagent_stop(idle=true) +1.2s → sendUserMessage ok → run_start +38ms → model auto-called agent_output list + per-id and got the result. Evidence: scratchpad wake-lab/ (probe.log, pty-clean.txt).

## cmd tool names

The blocking shell tool that the shared rules forbid waiting on is `shell_command`.

## Shared rules (canonical)

@~/.agents/AGENTS.md
