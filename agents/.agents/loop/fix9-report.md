# FIX-9 — project orientation for /home/prm

Status: done. Files: `/home/prm/AGENTS.md` (59 lines), `/home/prm/CLAUDE.md`
(2 lines, pointer only). Nothing else touched.

## 1. What each harness loads from a project directory

**pi** (`@earendil-works/pi-coding-agent`)
- Loads one context file per directory, first match wins, in this order:
  `AGENTS.override.md`, `AGENTS.md`, `AGENTS.MD`, `CLAUDE.md`, `CLAUDE.MD`.
  Source: `dist/core/resource-loader.js:129-134`.
- Directories are the agent dir, then cwd and every parent, so a file applies
  below its directory. Source: `dist/core/resource-loader.js:184,193`;
  `docs/configuration.md:43`.
- `AGENTS.override.md` replaces a sibling `AGENTS.md`/`CLAUDE.md` only in the
  same directory. Source: `docs/configuration.md:45`.
- Context loading needs no project trust. Source: `docs/configuration.md:47`;
  `docs/security.md:57`.
- Disable switch: `--no-context-files` / `-nc`. Source: `docs/cli.md:217`.
- Consequence: at `/home/prm` pi loads `~/.pi/agent/AGENTS.md` then
  `/home/prm/AGENTS.md`, and skips `/home/prm/CLAUDE.md` — no double load.

**Command Code** (`command-code`)
- `discoverRecursiveMemoryFiles` walks cwd upward and loads, per directory,
  `<dir>/AGENTS.md` and `<dir>/.commandcode/AGENTS.md`.
  Source: `dist/cli.mjs:2` (minified bundle; single line, function name is the
  stable locator).
- User memory is `~/.commandcode/AGENTS.md` (`getUserMemoryPath`), enterprise
  is `/etc/.commandcode/AGENTS.md` (`getEnterpriseMemoryPath`). Same line.
- No `CLAUDE.md` discovery (only an import term-rewrite, `rewriteClaudeTerms`).

**Claude Code** — reads `CLAUDE.md`; `/home/prm/CLAUDE.md` is `@AGENTS.md` plus
one comment. Convention checked before writing: `/home/prm/firstmate/CLAUDE.md`
and `/home/prm/curr/career-ops/CLAUDE.md` do exactly this, so a pointer is the
house style, not a copy.

## 2. Verification

- Line count: `wc -l` → 59 (`AGENTS.md`), 2 (`CLAUDE.md`).
- Every backticked absolute path resolves from `/home/prm`: 22/22 checked with
  a loop over `grep -oE '\`/home/prm[^\`]*\`'`, brace-globs removed so no
  pattern poses as a path.
- No duplication of `~/.agents/AGENTS.md`: grepped for each rule heading
  ("clarify until ambiguity", "harness-agnostic", "Never block", "Lookup
  before reading", "Subagents", "Tool economy") — only pointer lines remain.
- pi loader proven empirically for cwd `/home/prm`:
  `loadProjectContextFiles({cwd:"/home/prm",agentDir:"/home/prm/.pi/agent"})`
  returns `~/.pi/agent/AGENTS.md` then `/home/prm/AGENTS.md`. `CLAUDE.md`
  absent from the set, confirming no duplicate context.
- Stranger read, real harness: `cd /home/prm && cmd -p "<3 questions>"` (cwd
  `/home/prm`, no extra prompt) answered correctly:
  1. run first → the `flow` skill;
  2. must not edit → `.agents/skills/`, `.agents/LEDGER.md`, app state
     (`~/.pi/agent/{npm,git,sessions}`, `~/.commandcode/{sessions,projects,history.jsonl}`),
     `~/.jcode` outside its updater;
  3. rules live → `/home/prm/.agents/AGENTS.md`.
- Note: `pi -p` was refused by
  `~/.pi/agent/extensions/herdr-interactive-only.ts` (herdr guard). That is
  the behaviour the AGENTS.md guard bullet warns about, verified live.

## 3. Deliberate omissions

- No restatement of the global rules; one pointer, except the herdr
  interactive-only guard, restated because a hook enforces it.
- No skill inventory: `/home/prm/.agents/skills/README.md` already generates
  the table (126 `SKILL.md`, 135-line manifest).
- No tool/MCP catalogue, no provider or model config, no repo listing under
  `~/projects` — each is one `ls` or `pi list` away.
- No `~/.commandcode/AGENTS.md` or `~/.pi/agent/AGENTS.md` edits: not owned.
