# pi-only fragment read by gen-pi-agents.py. Not loaded by any agent.
#
# @header            replaces the shared title and is emitted first.
# @replace <anchor>  swaps the one shared line containing <anchor> for the lines below.
# @after <anchor>    keeps that line and inserts the lines below it.
# An anchor that matches zero or two shared lines fails the generator, so a change to
# the shared file cannot silently leave pi with a stale rule.
#
# This file holds only what pi must obey and the shared file cannot deliver: the six
# tool-form imperatives and the exact command for checking on an hc agent. Everything
# else in the generated file is the shared file as-is, clarify gate included.

@header
# Global instructions

Shared memory is `~/.agents/AGENTS.md`; `~/.commandcode/AGENTS.md` is not read in pi.

Why this block is duplicated: pi has no `@` import for context files, so a pointer line is inert — a rule behind a pointer fires only if a model chooses to go read another file, and these must fire without that choice. This is the one authorized exception to the no-duplication rule in `~/.agents/AGENTS.md`.

@replace start long work backgrounded or monitored
- Never block a shell command: long work gets its own terminal — `hc run --bg --name <n> '<cmd>'` — so `hc wait <n>` is legal later; if it truly must be `bash`, use `nohup <cmd> > <log> 2>&1 &`, record `$!` and the log path, then return. Never sit in an unbounded call waiting on it.

@replace Never block on an agent: launch it detached, then wait on its event
- Never block on an agent: launch it detached (`hc run --bg --name <n> pi`), then wait on its event (`hc wait <n>`).

@replace Wait with the harness's own wait call
- Wait with `hc wait <name>` (the one blocking call allowed, one event at a time, never a poll loop or a timer). Its cap is 180s by default, not the 600s `bash-guard` puts on a `bash` call: a 180s return means still running, so a longer wait is another `hc wait` next turn. For a job with no terminal (`nohup`), the legal wait is `timeout 170 tail -q -f --pid=$PID <log>` — it blocks on the process and returns at the cap, which is not polling.

@replace Peek at the job's log
- Peek once, then report one line: finished, running, next. An `hc` terminal: `hc read <name> --lines 20`. A `nohup` job: `bash` with `tail -n 20 <log>`.

@replace Synchronous work: the harness's own subagent tool
- pi has no in-process subagent tool: delegate with `intercom` (another pi session) or `hc` (below), never inline; several launches in one message run concurrently.

@replace Detached work: the harness's detached spawn
- Detached work: `hc run --bg --name <n> '<cmd>'`, then one event-wait, never a poll loop.

@after Check on it rather than assuming
- The commands: `hc read <n> --lines 20` for its output, `hc get <n>` for one terminal, `hc ls` for the live list (raw JSON; `hc list` is not a subcommand). `hc wait <n>` prints `{"ended":true,"exit_code":0,…}` — assert those fields instead of guessing from the screen.
