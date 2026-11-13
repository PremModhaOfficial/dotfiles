# Subagents: mechanics (detail)

- commandcode: the `agent` tool runs a subagent in its own context window and
  returns one result. One call per turn chains; several in one message run
  concurrently.
- `pubsub_fire` (commandcode): the `pubsub` mod spawns a headless run and returns
  immediately; the result arrives later as a message.
- pi: no in-process subagent tool; delegate with `intercom` or `hc`.
- Why bound the scope: a subagent asked to decide too much in one run burns its
  context and returns nothing.

Wake-up caveat for background subagents (commandcode): see
`~/.commandcode/AGENTS.md` § Background sub-agent wake-up.
