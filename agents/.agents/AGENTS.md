# Memory

## HARD RULE: clarify until ambiguity <= 3
- Score each prompt 0-10 first; it picks the step, not a stop.
- Unattended = nobody can reply here: `hc ls` shows my `$HC_TERMINAL_ID` has a parent, or a task file, or a scheduled/background run; cannot tell = unattended. Never stall: take the cheapest falsifying step, continue; open questions go in the report.
- Attended, above 3: ask up to 4 score-moving questions in one message, never taste, then re-score.
- Any command, read or test that resolves ambiguity re-scores first, attended or not; continue if it drops.
- First visible line, before any tool call: `Reading: X, because Y` (output, not reasoning); never a quiet assumption, reversible in one command.
- Spec: `~/.agents/references/memory-clarify.md`

## HARD RULE: harness-agnostic home
- Always prefer `~/.agents` over harness dirs for skills, agents, memory, config; keep canonical shared files there.
- Harness files may only import, symlink or point there; do not duplicate content, except a harness with no import (pi: no `@`), which inlines the rules and says why.
- If a harness needs a fixed path, keep the content in `~/.agents` and add the smallest pointer.

## Never block
- Long means builds, tests, watchers, servers, agent runs.
- Never block a shell command: start long work backgrounded or monitored, record `$!` and the log path, then return; never sit in an unbounded call waiting on it.
- Never block on an agent: launch it detached, then wait on its event.
- Wait with the harness's own wait call (the one blocking call allowed, because it is bounded), one event at a time; never a poll loop, never a timer.
- Say one line about what is running, then stop; the signal is the next message.
- Peek at the job's log, then report one line: finished, running, next.
- User waiting on one delegated result: one event-wait, delivered in the same turn.
- Kill what you started before done; free the ports.

## Lookup before reading
- If `graft` exists, use it for local code; otherwise grep and read.
- If `graft` exists: build once where no graph exists, `callers --depth 2` before a signature change, tokens-saved tally to close the turn.
- Use deepwiki for dependencies or other repos; never clone or grep a vendored one.
- Open a file only when it is new, unindexed or truncated mid-span.

## Subagents
- Synchronous work: the harness's own subagent tool; several in one message run concurrently.
- Detached work: the harness's detached spawn; then one event-wait, never a poll loop.
- Hand off on disk with absolute artifact paths.
- Never paste upstream content into a prompt.
- Bound scope: labelled slices, one artifact each.
- Never re-run a failed task at the same scope.
- Make every delegation send build/test output to a file and return pass/fail plus counts.

## Tool economy
- Batch independent reads, greps and MCP lookups into one `codemode` script.
- Never print or return raw tool output; return only the extracted fields.

## Web access
- Read pages with `oc` rather than the built-in fetcher.
- If built-in search or fetch is denied, use a fallback fetch server only if the harness has one configured; if it has none, report the denial.
- Never retry a denied built-in call.

## Order of operations
- Real repo work (bug, feature, PR) starts with the `flow` skill.
- Questions, research and chat do not need it.

## Herdr / `hc` delegation
- Interactive agents only: a one-shot cannot report back. A guard that blocks one-shot is right; headless is legal only for a harness no guard covers, and is still discouraged.
- Every spawned agent's task text must tell it to report progress, findings and questions back.
- Check on it rather than assuming: its output, its recent lines, its session log.

## References
- `~/.agents/references/`: `memory-clarify.md` (borderline score), `memory-harness-home.md` (pointer forms, machine layout), `memory-never-block.md` (wait and kill forms), `memory-code-lookup.md` (graft, deepwiki), `memory-subagents.md` (delegation), `memory-web-access.md` (`oc`, fetch fallback), `memory-flow.md` (phases).
