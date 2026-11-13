# Subagents: mechanics (detail)

- The native `agent` tool runs a subagent in its own context window and returns
  one result. One `agent` call per turn keeps a chain sequential; several in one
  turn run concurrently — that is the parallelism control, so put genuinely
  independent work in a single message on purpose.
- `pubsub_fire`: the `pubsub` mod spawns a headless run and returns immediately;
  the result arrives later as a message.
- Why bound the scope: a subagent asked to decide too much in one run burns its
  context and returns nothing.

Wake-up caveat for background subagents: see
`~/.commandcode/AGENTS.md` § Background sub-agent wake-up (cmd-specific).
