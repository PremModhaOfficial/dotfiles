# T3 tools reference

## Supported providers

T3 Code drives Claude Code, Codex, Cursor, OpenCode, Antigravity, Grok, Pi, and other ACP-capable agents on the user's own subscriptions.

## CLI

```sh
t3 project add .
t3 thread start . "task" --worktree main --branch feat-x --wait --json
t3 thread send <id> "follow-up" --wait
t3 thread show <id> --json --messages 20
t3 thread list --project . --json
t3 environment list
```

- `--wait`: exit 0 done, 1 failed, 2 agent asked a question.
- `message "-"` reads stdin. Use `--json` for machine reads.
- `t3 app [path]` opens the desktop app on that directory.
- `t3 up` sets up remote access. `t3 pair` prints a pairing QR.

## MCP setup

```sh
claude mcp add --transport http t3 https://<env>/mcp
claude mcp login t3

codex mcp add t3 --url https://<env>/mcp
codex mcp login t3
```

OAuth approve in Settings > Sharing & access. Revoke there. Access lasts about 30 days, depending on the environment's policy. A `401` means re-login.

## MCP tools

`orchestrator_capabilities`, `delegate_task`, `task_status`, `task_cancel`, `create_threads`, `t3_thread_launch`, `t3_thread_list`, `t3_thread_read`, `t3_thread_send`, `t3_thread_wait`, `t3_thread_interrupt`, `t3_thread_update`, `preview_status`, `preview_open`, `preview_snapshot`, `preview_act`, `preview_evaluate`, `html_preview`, `html_render`, `t3_environment_links`, `t3_environment_link`, `request_secret`, `schedule_task`, `link_pull_request`, `link_pull_requests`, `watch_pull_request`, `unwatch_pull_request`.

## Delegation results

- `next`: the literal string `Completion wakes this thread, so end your turn. Do not wait on it or poll it.`
- `workState`: `working`, `waiting_for_children`, `result_available`. Progress only.

## Provider skills

T3 surfaces each provider's own skills. Invoke with `$` or `/` in the composer.

- Claude: `~/.claude/skills`, `./.claude/skills`, plus enabled plugins. User beats project on name clash.
- Disable: `settings.json` > `skillOverrides` > `"off"` or `"user-invocable-only"`.
- Antigravity: `~/.gemini/config/skills`, `~/.gemini/antigravity-cli/skills`, `./.gemini/skills`, `./.agents/skills`, `./.agent/skills`. First found wins.
- Codex and OpenCode: no per-skill discovery documented in T3. Use `AGENTS.md` for standing instructions.
