# Harness-agnostic home: pointer forms (detail)

Cheapest first:

- An import line where supported: commandcode reads `@~/.agents/AGENTS.md`.
- Where the harness reads one fixed filename instead, symlink it.
- An inline repeat, only where the harness has no import and a pointer would be
  inert; pi is the one authorized case, because it cannot `@`-import
  (`docs/configuration.md`).

Why: one edit under `~/.agents` must reach every harness; content copied into a
harness dir drifts silently.
