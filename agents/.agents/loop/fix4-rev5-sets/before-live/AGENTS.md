# Memory

## HARD RULE: clarify until ambiguity <= 3
- Score each prompt 0-10 before acting; above 3, do not start the task.
- Scale: 0 = one reading, complete requirements; 10 = no usable reading.
- Ask at most 4 score-moving questions per round, re-score, act at <= 3.
- State the score and competing readings in one line before asking.
- Ask only about ambiguities that change the work; never about preferences.
- Apply this to every prompt, short ones and follow-ups included.
- Never resolve ambiguity by silent assumption.
- Told to skip: state score, open readings, assumption; proceed only on confirm.

## HARD RULE: harness-agnostic home
- Always prefer `~/.agents` over harness dirs for skills, agents, memory, config.
- Keep canonical shared files under `~/.agents`.
- Harness files may only import, symlink or point there; do not duplicate content.
- If a harness needs a fixed path, keep the content in `~/.agents` and add the smallest pointer.

## Never block
- Long means builds, tests, watchers, servers, any headless agent run.
- Never block a shell command: start slow work backgrounded or monitored, then return.
- Never sit in a blocking shell call waiting on it.
- Never block on an agent: launch detached, get woken on completion.
- Do not wrap `shell_output(wait)` or any poll loop around an agent or long job.
- Say one line about what is running, then stop; the signal is the next message.
- Peek with `shell_output` and report one line: finished, running, next.
- One wait alone, or none; it ends on the event, never a timer loop.
- User waiting on one delegated result: one event-wait, delivered in the same turn.
- Kill what you started before calling the task done; free the ports.

## Lookup before reading
- If `graft` exists, use it for local code; otherwise grep and read.
- If `graft` exists: `graft build` once where no graph exists, `graft callers --depth 2`
  before a signature change, tokens-saved tally to close the turn.
- Use deepwiki for dependencies or other repos; never clone or grep a vendored one.
- Open a file only when it is new, unindexed or truncated mid-span.

## Subagents
- Synchronous work: the native `agent` tool; several in one message run concurrently.
- Detached work: `pubsub_fire`.
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
- If built-in search or fetch is denied, use the `donsetch` MCP tools.
- Never retry a denied built-in call.

## Order of operations
- Real repo work (bug, feature, PR) starts with the `flow` skill.
- Questions, research and chat do not need it.

## References
- Why ambiguity costs a turn — `references/memory-clarify.md` — read when a score is borderline.
- Harness paths and pointer rules — `references/memory-harness-home.md` — read before adding config, skills or memory for a harness.
- Background, wait and kill details — `references/memory-never-block.md` — read before running slow work or delegating.
- graft/deepwiki command forms — `references/memory-code-lookup.md` — read before reading code or a dependency.
- Delegation hygiene — `references/memory-subagents.md` — read before spawning a subagent.
- `oc` and donsetch forms — `references/memory-web-access.md` — read before fetching a page.
- flow phases — `references/memory-flow.md` — read when starting repository work.
