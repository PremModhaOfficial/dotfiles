# FIX-4 rev3 — 4096-byte AGENTS.md + per-topic references

Revision 3 overrides rev2. Cap is back in force, so the rules were split rather
than trimmed: imperatives stay in `~/.agents/AGENTS.md`, verbose material moved
to one reference file per topic, one index line per reference. No git commit.

## File sizes

| File | Bytes | Cap |
|---|---|---|
| `~/.agents/AGENTS.md` | **3749** | 4096 (347 spare) |
| `~/.pi/agent/AGENTS.md` | 2940 | none |
| `~/.commandcode/AGENTS.md` | 2589 (unchanged, cmd-specific only) | none |
| `~/.agents/references/memory-clarify.md` | 963 | none |
| `~/.agents/references/memory-harness-home.md` | 1002 | none |
| `~/.agents/references/memory-never-block.md` | 2687 | none |
| `~/.agents/references/memory-code-lookup.md` | 1329 | none |
| `~/.agents/references/memory-subagents.md` | 1198 | none |
| `~/.agents/references/memory-tool-economy.md` | 414 | none |
| `~/.agents/references/memory-web-access.md` | 615 | none |
| `~/.agents/references/memory-flow.md` | 553 | none |

References total 8761 bytes; nothing was deleted to fit the cap.

## What lives where

- `AGENTS.md` — 48 short imperative lines under 9 headings, of which 8 are the
  reference index. No examples, no rationale, no tool transcripts.
- `references/memory-<topic>.md` — the original wording: ambiguity scale, pointer
  forms, `graft`/`deepwiki` command forms, `agent`/`pubsub_fire`, `codemode`,
  `oc`/`donsetch` names, the `flow` paragraph, the folded cmd sections.
- `~/.pi/agent/AGENTS.md` — same intent as rev2 (duplication authorized: pi cannot
  `@`-import, per `docs/configuration.md`), terse inline hard rules + order of
  operations, EGM and Herdr/`hc` sections, and one line pointing at the reference
  directory rather than repeating the index.
- `~/.commandcode/AGENTS.md` — untouched: Herdr plugin config, background-sub-agent
  wake-up recipe, `shell_command` mapping, trailing `@~/.agents/AGENTS.md`.

## Index coverage

8 entries in `AGENTS.md` § References, 8 reference files: same set, no orphans and
no dangling index line (checked by set equality, mismatch = none). Every reference
file is reachable from a single index line naming topic, path and read trigger.

## Imperative accounting

42 imperative-bearing units parsed from `/tmp/fix4/orig-*.md`: **5 inline,
27 in a named reference file, 10 kept in the harness-specific files (5 cmd + 5 pi),
0 lost.**

| # | Origin | Imperative (abridged) | Lands in |
|---|---|---|---|
| 1 | agents | If the score is greater than 3, do not start the task. | REF `memory-clarify.md` |
| 2 | agents | - Ask only about ambiguities that change the work. | INLINE `AGENTS.md` |
| 3 | agents | Never ask about preferences that do not. | REF `memory-clarify.md` |
| 4 | agents | - Never resolve ambiguity by silent assumption. | INLINE `AGENTS.md` |
| 5 | agents | proceed only after the user confirms. | REF `memory-clarify.md` |
| 6 | agents | ## HARD RULE: harness-agnostic home Always prefer `~/.agents` over harness-specific locations (`~/.c | REF `memory-harness-home.md` |
| 7 | agents | - Harness-specific files may only import, symlink, or point to `~/.agents`; | REF `memory-harness-home.md` |
| 8 | agents | do not duplicate content there. | REF `memory-harness-home.md` |
| 9 | agents | Questions, research and chat do not need it. | INLINE `AGENTS.md` |
| 10 | cmd | # Memory ## NEVER block — background everything, agents included A blocking wait is a bug, not patie | REF `memory-never-block.md` |
| 11 | cmd | - Never block on a shell command. | REF `memory-never-block.md` |
| 12 | cmd | Never sit in a blocking `shell_command` waiting on one; | REF `memory-never-block.md` |
| 13 | cmd | - Never block on an agent. | INLINE `AGENTS.md` |
| 14 | cmd | Do not wrap `shell_output(wait)` or any poll loop around an agent or a long task — that just trades  | REF `memory-never-block.md` |
| 15 | cmd | If you truly need one result before continuing, the wait goes in its own message and ends on the eve | REF `memory-never-block.md` |
| 16 | cmd | Go detached-and-stop only when the user is not blocked on the outcome. | REF `memory-never-block.md` |
| 17 | cmd | ## Long commands: never block, always report Long commands run, but the session never blocks on them | REF `memory-never-block.md` |
| 18 | cmd | Never sit in a blocking `shell_command` waiting on one; | REF `memory-never-block.md` |
| 19 | cmd | When a result is truly needed before the next step, that wait goes alone in its message and ends on  | REF `memory-never-block.md` |
| 20 | cmd | ## Understanding code: look it up, don't read it in Reach for a lookup before an open. | REF `memory-code-lookup.md` |
| 21 | cmd | Use `read_wiki_structure` first only when you do not know what to ask. | REF `memory-code-lookup.md` |
| 22 | cmd | Open a file directly only when it is new, unindexed (docs, configs), or the lookup truncated the spa | REF `memory-code-lookup.md` |
| 23 | cmd | Name artifacts by absolute path and never paste upstream content into a prompt. | REF `memory-subagents.md` |
| 24 | cmd | Split into labelled slices that each write one artifact, and never re-run a failed task at the same  | REF `memory-subagents.md` |
| 25 | cmd | Builds and tests flood an agent's context: instruct every delegation prompt to redirect `go build` / | REF `memory-subagents.md` |
| 26 | cmd | ## Tool economy: batch with codemode Do not fire independent reads, greps, or lookups one per messag | REF `memory-tool-economy.md` |
| 27 | cmd | Put them in a single `codemode` script and return only the extracted fields; | REF `memory-tool-economy.md` |
| 28 | cmd | never print or return raw tool output. | INLINE `AGENTS.md` |
| 29 | cmd | ## Web access For reading a page, prefer `oc` (only-cli), installed globally: `oc open <url>` return | REF `memory-web-access.md` |
| 30 | cmd | Site shortcuts like `oc gh repo only-cli oc` or `oc hn top` skip URL guessing; | REF `memory-web-access.md` |
| 31 | cmd | When they are, fall back to the `donsetch` MCP tools — `mcp__donsetch__web_search`, `mcp__donsetch__ | REF `memory-web-access.md` |
| 32 | cmd | ## Background sub-agent wake-up (proven against cmd 1.88.2, 2026-11-02) Built-in gap: a background s | KEPT `~/.commandcode/AGENTS.md` |
| 33 | cmd | Monitors get a wake-up (`useMonitorOutputWakeup`), sub-agents do not. | KEPT `~/.commandcode/AGENTS.md` |
| 34 | cmd | Proven close-the-gap recipe (mod, not hooks — settings.json hooks only get PreToolUse/PostToolUse/St | KEPT `~/.commandcode/AGENTS.md` |
| 35 | cmd | `cmd.queueMessage`/`deliverAs` queues NEVER start a turn — headless they degrade to a silent queue p | KEPT `~/.commandcode/AGENTS.md` |
| 36 | cmd | - Mods cannot invoke `agent_output` (no tool seam in ModApi) — the wake text must instruct the model | KEPT `~/.commandcode/AGENTS.md` |
| 37 | pi | - Resolve `agents/`, `resources/`, and `docs/` paths referenced by those skills against the bundle r | KEPT `~/.pi/agent/AGENTS.md` |
| 38 | pi | ## Herdr / `hc` delegation Interactive agents only, and they must talk back. | KEPT `~/.pi/agent/AGENTS.md` |
| 39 | pi | - Never spawn an agent through `hc`/`herdr` in one-shot mode (`pi -p`, `claude -p`, `codex exec`). | KEPT `~/.pi/agent/AGENTS.md` |
| 40 | pi | An extension hook (`~/.pi/agent/extensions/herdr-interactive-only.ts`) blocks that. | KEPT `~/.pi/agent/AGENTS.md` |
| 41 | pi | - Every spawned agent's task text must tell it to report back: send progress, findings and questions | KEPT `~/.pi/agent/AGENTS.md` |
| 42 | pi | Pointer only; | REF `memory-flow.md` |

## Verification

- Parser: every line/sentence containing must|never|always|do not|don't|only|may only.
- 0 rows MISSING. 8 rows are heading+body chunks of the originals (heading and
  first sentence on one logical line); each body sentence was matched verbatim in
  the target file, headings were renamed with a "(detail)" suffix.
- `AGENTS.md` = 3749 bytes <= 4096, so no rule had to be cut for space.
- No rule exists only in a reference file: each reference is named by an index
  line in `AGENTS.md`.

## Known, accepted overlaps

1. `AGENTS.md` <-> `~/.pi/agent/AGENTS.md`: 12 verbatim lines — the D12 authorized
   duplication (pi cannot import), now the terse hard rules and order of operations.
2. `AGENTS.md` <-> `references/memory-clarify.md`: 1 sentence,
   "Never resolve ambiguity by silent assumption." — the reference is the original
   wording of the rule that `AGENTS.md` must state inline.
3. Inside `references/memory-never-block.md`, the two superseded cmd sections are
   quoted under "Folded originals (kept for traceability)" so that no original
   imperative is unaccounted for; they are not separate rules.

Nothing else is repeated between files.

## Did not fit

Nothing. 347 bytes remain under the cap.
