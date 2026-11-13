# pi-only fragment read by gen-pi-agents.py. Not loaded by any agent.
#
# @header            replaces the shared title and is emitted first.
# @replace <anchor>  swaps the one shared line containing <anchor> for the lines below.
# @after <anchor>    keeps that line and inserts the lines below it.
# An anchor that matches zero or two shared lines fails the generator, so a change to
# the shared file cannot silently leave pi with a stale rule.
#
# This file holds only what pi must obey and the shared file cannot deliver: the six
# tool-form imperatives and the one override line. Everything else in the generated
# file is the shared file as-is.

@header
# Global instructions

Shared memory is `~/.agents/AGENTS.md`; `~/.commandcode/AGENTS.md` is not read in pi.

Why this block is duplicated: pi has no `@` import for context files, so a pointer line is inert — a rule behind a pointer fires only if a model chooses to go read another file, and these must fire without that choice. This is the one authorized exception to the no-duplication rule in `~/.agents/AGENTS.md`.

@after Full scale, refusal path and retry detail
- If told to start anyway: state the score and the reading you guessed, then go.

@replace start long work backgrounded or monitored
- Never block a shell command: start long work in the background with `bash` (`nohup <cmd> > <log> 2>&1 &`), record `$!` and the log path, then return; never sit in an unbounded call waiting on it.

@replace Never block on an agent: launch it detached, then wait on its event
- Never block on an agent: launch it detached (`hc run --bg`), then wait on its event.

@replace Wait with the harness's own wait call
- Wait with `hc wait <name>` (the one blocking call allowed, because `bash-guard` bounds it), one event at a time, never a poll loop or a timer. Each `bash` call is capped at 600s, so a longer wait is several `hc wait` calls or a background log plus a peek.

@replace Peek at the job's log
- Peek with `bash` (`tail -n 20 <log>`), then report one line: finished, running, next.

@replace Synchronous work: the harness's own subagent tool
- pi has no in-process subagent tool: delegate with `intercom` (another pi session) or `hc` (below), never inline; several launches in one message run concurrently.

@replace Detached work: the harness's detached spawn
- Detached work: `hc run --bg` (below), then one event-wait, never a poll loop.
