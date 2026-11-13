# FIX-4 rev2 — restore full tool-neutral memory

No byte cap. Originals: `/tmp/fix4/orig-{agents,cmd,pi}.md`. No git commit.

## Byte counts (before = rev1 on disk, after = now)

| File | Original | rev1 (before) | rev2 (after) | Delta vs rev1 |
|---|---|---|---|---|
| `~/.agents/AGENTS.md` | 1673 | 4092 | 6639 | +2547 |
| `~/.commandcode/AGENTS.md` | 8130 | 2589 | 2589 | 0 |
| `~/.pi/agent/AGENTS.md` | 1320 | 532 | 3158 | +2626 |

## Placement decision

- `~/.agents/AGENTS.md` = original hard rules verbatim + every tool-neutral section from
  orig-cmd verbatim (examples, exact tool names: `graft skeleton/ask/grep/callers/map/build`,
  `ask_wiki_question`/`read_wiki_structure` with `repoName: "nats-io/nats.rs"`,
  `~/.cargo/registry`, `node_modules`, `agent`, `pubsub_fire`, `codemode`,
  `glob`/`grep`/`read_file`, `oc *`, `mcp__donsetch__web_{search,fetch,crawl}`,
  `run_in_background=true`, `monitor_command`, `shell_output(from_offset,max_chars)`,
  `wait:"exit"`/`wait:"output"`, `go build`/`go test`/`npm`).
- `~/.commandcode/AGENTS.md` = genuinely cmd-specific only: Herdr
  `commandcode.integration` plugin section, background-sub-agent wake-up recipe
  (`cmd.on`, `sendUserMessage`, `prompt.submit`, `bg-<n>-<8hex>`), the
  `shell_command` tool-name mapping, and the trailing pointer `@~/.agents/AGENTS.md`.
- `~/.pi/agent/AGENTS.md` = pi's own EGM + Herdr/`hc` sections (restored from
  orig-pi in full) plus an inline repeat of the two HARD RULES and Order of
  operations, with one line stating why the duplication exists (pi has no `@`
  import, so a pointer is inert — `docs/configuration.md`).

Deduplication: the two near-identical never-block sections in orig-cmd
(`NEVER block — background everything, agents included` and
`Long commands: never block, always report`) were folded into one section; the
duplicate `One wait alone, or none` bullet kept the fuller wording.

## Imperative accounting (must / never / always / do not / only)

37 imperative lines in the originals, 37 accounted for: 34 restored in place,
3 kept in the cmd-specific file.

| # | Original | Imperative line (abridged) | Lands in | Status |
|---|---|---|---|---|
| 1 | agents | do not start when ambiguity > 3 | agents | restored |
| 2 | agents | Never ask about preferences | agents | restored |
| 3 | agents | Never resolve ambiguity by silent assumption | agents | restored |
| 4 | agents | proceed only after the user confirms | agents | restored |
| 5 | agents | Always prefer `~/.agents` | agents | restored |
| 6 | agents | may only import, symlink, or point | agents | restored |
| 7 | agents | chat/research do not need flow | agents | restored |
| 8 | cmd | Never block on a shell command | agents | restored |
| 9 | cmd | Never sit in a blocking `shell_command` | agents | restored |
| 10 | cmd | Never block on an agent | agents | restored |
| 11 | cmd | Do not wrap `shell_output(wait)` / poll loop | agents | restored |
| 12 | cmd | wait must end on the event, never a timer loop | agents | restored |
| 13 | cmd | Kill what you start | agents | restored |
| 14 | cmd | killed before done / ports come back clean | agents | restored |
| 15 | cmd | user waiting → ONE `wait:"exit"` | agents | restored |
| 16 | cmd | Go detached only when user not blocked | agents | restored |
| 17 | cmd | Detached first / must start backgrounded, never block | agents | merged (§Never block) |
| 18 | cmd | "Long commands: never block, always report" (heading) | agents | folded (duplicate heading) |
| 19 | cmd | session never blocks on them (intro) | agents | folded (duplicate intro) |
| 20 | cmd | peek with `shell_output`, must tell user | agents | restored |
| 21 | cmd | One wait alone, or none (2nd copy) | agents | folded (duplicate bullet) |
| 22 | cmd | must open file only when new/unindexed/truncated | agents | restored |
| 23 | cmd | must run `graft build` once | agents | restored |
| 24 | cmd | must never paste upstream content | agents | restored |
| 25 | cmd | never re-run failed task at same scope | agents | restored |
| 26 | cmd | must instruct delegation to redirect output | agents | restored |
| 27 | cmd | Do not fire independent reads one per message | agents | restored |
| 28 | cmd | never print or return raw tool output | agents | restored |
| 29 | cmd | built-ins may be blocked (web_search/web_fetch) | agents | restored |
| 30 | cmd | do not retry a denied built-in call | agents | restored |
| 31 | cmd | do NOT parse the agent tool result | cmd | kept (cmd-specific) |
| 32 | cmd | queues NEVER start a turn | cmd | kept (cmd-specific) |
| 33 | cmd | Mods cannot invoke `agent_output` | cmd | kept (cmd-specific) |
| 34 | pi | must resolve paths against bundle root | pi | restored |
| 35 | pi | Never spawn via `hc` one-shot | pi | restored |
| 36 | pi | task text must tell it to report back | pi | restored |
| 37 | pi | must talk back / no reporting = no visibility | pi | restored |

## Duplication check

- Sentence-level (>= 40 chars) verbatim overlap: `agents <-> cmd` **0**, `cmd <-> pi` **0**.
- `agents <-> pi`: **15** sentences — all inside the authorized inline block
  (clarify rule, harness-agnostic rule, order of operations) plus its why-line.

## Authorized duplication list

1. `~/.pi/agent/AGENTS.md`: `## HARD RULE: clarify until ambiguity <= 3` — whole section.
2. `~/.pi/agent/AGENTS.md`: `## HARD RULE: harness-agnostic home` — whole section.
3. `~/.pi/agent/AGENTS.md`: `## Order of operations` — whole section.
4. `~/.pi/agent/AGENTS.md`: the `Why this block is duplicated:` line.

Nothing else is repeated anywhere. Never-block is not repeated in
`~/.pi/agent/AGENTS.md` because its text is cmd-tool-shaped (`run_in_background`,
`monitor_command`, `wait:"exit"`); it stays single-source in `~/.agents`.

## Still missing

None from the originals. Verifier parsed 37 imperative lines; 37 accounted for
(34 restored/folded in place + 3 cmd-specific kept in cmd).
