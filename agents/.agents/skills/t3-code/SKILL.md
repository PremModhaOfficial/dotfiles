---
name: t3-code
description: Operate T3 Code threads from inside an agent. Use when delegating a task, choosing a worktree, or recovering when T3 tools are missing.
---

# T3 Code

T3 Code injects its own orchestration rules into the session. Read those first. This skill adds only the gaps.

## Common path

1. `delegate_task` with the job.
2. If the result has `next`, end your turn. Completion wakes the thread.
3. On wake, read the result.
4. `status`: `queued`, `running`, `waiting`, `completed`, `failed`, `cancelled`, `interrupted`. Stop on the last four.
5. `waiting_for_children` (workState): children still run. Do not retry or cancel. End your turn.

## Gate

- Act only when T3 tools are visible, or `T3_ACP_MCP_NODE` is set. If a tool is missing, try its name once before treating it as absent.
- Tool names may carry a prefix such as `mcp__t3-code__`. Search for the bare suffix.
- An installed skill alone grants no coordinator authority.

## Gaps

- One task per worktree.
- `t3_thread_launch` takes `workspaceStrategy`: `worktree` with `baseRef`, `existing_worktree` with `worktreePath`, or `root` (default).
- If a delegate fails, retry once with the failure in the prompt, unless the user said to stop or run fewer. If it fails again, report and stop.
- Never start a server against `~/.t3/userdata`, open it read-write, or clean it up.
- Never kill by name or path match. Kill a PID captured at spawn, or the port owner after confirming `/proc/<pid>/cwd` is your worktree.
- When T3 tools are missing: `ELECTRON_RUN_AS_NODE=1 "$T3_ACP_MCP_NODE" ${T3_ACP_MCP_ENTRYPOINT:+"$T3_ACP_MCP_ENTRYPOINT"} acp-mcp-call <tool> '{}'`. Do not switch provider or CLI.

## References

- `references/t3-tools.md` ships with this skill: providers, CLI, MCP setup, tool list, delegation results, provider skill paths.

Preview: `driving-t3-previews`. PR: `linking-t3-prs`.
