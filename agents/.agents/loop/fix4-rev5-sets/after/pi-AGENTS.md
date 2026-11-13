# Global instructions

Shared memory is `~/.agents/AGENTS.md`; `~/.commandcode/AGENTS.md` is not read in pi.

Why this block is duplicated: pi has no `@` import for context files, so a pointer line is inert — a rule behind a pointer fires only if a model chooses to go read another file, and these must fire without that choice. This is the one authorized exception to the no-duplication rule in `~/.agents/AGENTS.md`.

## HARD RULE: clarify until ambiguity <= 3
- Score each prompt 0-10 before acting, short ones and follow-ups included; above 3, do not start the task.
- Scale: 0 = one reading, complete requirements; 10 = no usable reading.
- Ask at most 4 score-moving questions per round, re-score, act at <= 3.
- State the score and competing readings in one line before asking.
- Ask only about ambiguities that change the work; never about preferences.
- Never resolve ambiguity by silent assumption.
- Told to skip: state score, open readings, assumption; proceed only on confirm.

## HARD RULE: harness-agnostic home
- Always prefer `~/.agents` over harness dirs for skills, agents, memory, config; keep canonical shared files there.
- Harness files may only import, symlink or point there; do not duplicate content, except a harness with no import (pi: no `@`), which inlines the rules and says why.
- If a harness needs a fixed path, keep the content in `~/.agents` and add the smallest pointer.

## Never block
- Long means builds, tests, watchers, servers, any headless agent run.
- Never block a shell command: start long work in the background with `bash` (`nohup <cmd> > <log> 2>&1 &`), then return; never sit in a blocking call waiting on it.
- Never block on an agent: launch it detached, get woken on completion.
- Do not wrap a wait call or any poll loop around an agent or long job.
- Say one line about what is running, then stop; the signal is the next message.
- Peek with `bash` (`tail -n 20 <log>`), then report one line: finished, running, next.
- One wait alone, or none; it ends on the event, never a timer loop.
- User waiting on one delegated result: one event-wait, delivered in the same turn.
- Kill what you started before done; free the ports.

## Lookup before reading
- If `graft` exists, use it for local code; otherwise grep and read.
- If `graft` exists: build once where no graph exists, `callers --depth 2` before a signature change, tokens-saved tally to close the turn.
- Use deepwiki for dependencies or other repos; never clone or grep a vendored one.
- Open a file only when it is new, unindexed or truncated mid-span.

## Subagents
- pi has no in-process subagent tool: delegate with `intercom` (another pi session) or `hc` (below), never inline; several launches in one message run concurrently.
- Detached work: `hc run --bg` (below), never a blocking wait.
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

## Herdr / `hc` delegation
- Interactive agents only, never one-shot: a one-shot agent cannot report back.
- Every spawned agent's task text must tell it to report progress, findings and questions back.
- Check on it rather than assuming: its output, its recent lines, its session log.

## References
- Ambiguity cost — `~/.agents/references/memory-clarify.md` — when a score is borderline.
- Harness paths, pointer forms — `~/.agents/references/memory-harness-home.md` — before adding harness config.
- Background, wait, kill — `~/.agents/references/memory-never-block.md` — before long work or delegating.
- graft/deepwiki forms — `~/.agents/references/memory-code-lookup.md` — before reading code or a dependency.
- Delegation hygiene — `~/.agents/references/memory-subagents.md` — before spawning a subagent.
- `oc` and donsetch forms — `~/.agents/references/memory-web-access.md` — before fetching a page.
- flow phases — `~/.agents/references/memory-flow.md` — when starting repository work.

## EGM (Elephant & Goldfish Model)

Bundle root: `/home/prm/.pi/agent/git/github.com/google/elephant-goldfish-model`

- EGM skills are the `/skill:egm-*` commands; their sources are in `<bundle root>/skills/`.
- Resolve `agents/`, `resources/`, and `docs/` paths referenced by those skills against the bundle root, never against the working directory.

## Herdr / `hc` forms (pi)

The rules are the shared delegation section above; these are pi's names for them.

- Launch interactive: `hc run --bg --name <name> pi`, then `hc send <name> '<task>'`, then `hc read <name>` / `hc wait <name>`.
- One-shot is blocked here: `~/.pi/agent/extensions/herdr-interactive-only.ts` rejects `pi -p`.

## Detail

Command forms for the rules above live in `~/.agents/references/`: `memory-clarify.md`, `memory-harness-home.md`, `memory-never-block.md`, `memory-code-lookup.md`, `memory-subagents.md`, `memory-web-access.md`, `memory-flow.md`.
