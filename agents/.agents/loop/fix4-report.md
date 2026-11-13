# FIX-4 rev 1 — one shared memory, two pointer files

Status: done. No git commit, no file outside the three touched (`/tmp/fix4/orig-*.md` holds the originals).

## Convention cited

[agents.md](https://agents.md) (stewarded by the Agentic AI Foundation): "**One AGENTS.md works across many agents**", and "AGENTS.md is just standard Markdown. Use any headings you like; the agent simply parses the text you provide." Closer files are overlays, not copies — so one canonical file plus harness overlays that only point at it is the intended shape. That is exactly what the shared `HARD RULE: harness-agnostic home` already demanded.

## Byte counts

| file | before | after |
|---|---|---|
| `~/.agents/AGENTS.md` | 1673 | **4092** (cap 4096) |
| `~/.commandcode/AGENTS.md` | 8130 | **2589** |
| `~/.pi/agent/AGENTS.md` | 1320 | **532** |

## Section map — `~/.commandcode/AGENTS.md` (9 sections in rev 1)

| section | bytes before | verdict | one-line reason |
|---|---|---|---|
| NEVER block — background everything, agents included | 1361 | **moved** → shared `## Never block` | tool-neutral; all 7 rules kept, cmd tool names kept inline as `(cmd: run_in_background, monitor_command)` / `wait:"exit"` / `shell_output` |
| Long commands: never block, always report | 987 | **moved**, merged into `## Never block` | restated rules already in NEVER block; its one unique rule ("peek and report: finished, running, next") survives verbatim in intent |
| Understanding code: look it up, don't read it in | 1322 | **moved** → `## Understand code by lookup` | `graft` is a global CLI and deepwiki an MCP server, not cmd features |
| Subagents | 1070 | **moved** → `## Subagents` | the `agent`/`pubsub_fire` names travel with the rule; slicing and report-back rules are harness-neutral |
| Tool economy: batch with codemode | 297 | **moved** → `## Tool economy` | `codemode` exists in both harnesses; rule is pure batching economics |
| Web access | 608 | **moved** → `## Web access` | `oc` is a global CLI and donsetch an MCP server; no cmd wiring involved |
| Herdr integration (commandcode.integration plugin) | 595 | **kept local** | cmd-only plugin paths (`~/.config/herdr/plugins/config/commandcode.integration/agent-detection/cmd.toml`), the cmd hook names in `~/.commandcode/settings.json`, and `herdr agent list` debug steps mean nothing to another harness |
| Background sub-agent wake-up (proven against cmd 1.88.2) | 1830 | **kept local** | a cmd bug plus cmd mod API (`cmd.on('subagent_start')`, `cmd.sendUserMessage`, `bg-<n>-<8hex>` id lifetime, the TUI settle row) — unusable and wrong for pi |
| Shared rules (canonical) | 50 | **kept**, now the terminal pointer | `## Shared rules (canonical)` + `@~/.agents/AGENTS.md`, still the last line of the file |
| cmd tool names *(new)* | 104 | **added** | the shared no-block rule needs cmd's blocking shell name `shell_command`; naming it is cmd-specific |

Nothing was **dropped**. No section failed to re-home.

`~/.pi/agent/AGENTS.md` content was re-homed as: its `## EGM` path rule and `## Herdr / hc delegation` rules → shared `## Subagents` (the general herdr rule, with the interactive `hc run --bg --name` form, report-back requirement and `hc ls` check) plus the bundle's own `AGENTS.md`/`docs/harnesses.md` which the file now points at; its `## Order of operations` → already in shared, duplicate removed.

## Verification (run after the change)

```
$ wc -c ~/.agents/AGENTS.md ~/.commandcode/AGENTS.md ~/.pi/agent/AGENTS.md
 4092 /home/prm/.agents/AGENTS.md
 2589 /home/prm/.commandcode/AGENTS.md
  532 /home/prm/.pi/agent/AGENTS.md

$ grep -v '^$' ~/.commandcode/AGENTS.md | tail -1
@~/.agents/AGENTS.md
```

- shared file 4092 ≤ 4096 — pass
- commandcode file ends with a pointer line — pass (last non-empty line is `@~/.agents/AGENTS.md`)
- pi file contains no rule text — pass: 4 sentences total, all path facts plus one pointer instruction ("read it before acting"); no shared rule is restated there
- duplication grep, all three files, sentences ≥ 40 chars:

```
$ python3 dup.py
sentences >=40 chars compared per file: {'.agents/AGENTS.md': 30, '.commandcode/AGENTS.md': 18, '.pi/agent/AGENTS.md': 4}
verbatim sentence appearing in two files: 0
```

A 10-word shingle check over the same three files also returned 0 shared shingles.

- rule survival, every tool/flag named in the moved sections, still present in the shared file: `run_in_background`, `monitor_command`, `shell_output`, `shell_command` (cmd file), `wait:"exit"`, `wait:"output"`, `graft` (`skeleton`, `ask`, `grep`, `callers`, `map`, `build`), `ask_wiki_question`, `read_wiki_structure`, `~/.cargo/registry`, `node_modules`, `agent`, `pubsub_fire`, `codemode`, `oc open/do/find/read/next/raw/sites`, `donsetch`, `web_search`, `web_fetch`, `web_crawl`.

## What I could not do / judgement calls

1. **Heavy compression was forced by the 4096 cap.** The moved rules were 5645 bytes of prose; the shared file had 2423 bytes free (4096 − 1673). Every imperative and every tool name survived, but illustrative extras did not: `oc hn top`, the `mcp__donsetch__` prefix, "~200 tokens", "that is a copy of someone else's repo". If a lost example counts as a lost rule, the cap and the no-drop rule are in direct conflict and the cap has to rise.
2. **`graft` is not on this shell's PATH** (`which graft` → not found), so I carried the rule as written and could not re-verify it today.
3. **The EGM bundle-root rule has no shared home.** It is pi-only, so putting it in `~/.agents` would mislead every other harness. It stays in the pi file as one *factual* pointer sentence ("these paths resolve against that root, not the working directory"). If the verifier counts that as rule text, the honest fix is to move it into the EGM bundle's own `AGENTS.md` — a fourth file, outside this ticket's scope. The same sentence is what makes "pointer-only" lossless rather than a deletion.
4. **One insertion beyond the section list:** the 104-byte `## cmd tool names` note, because the shared rule would otherwise not name the tool it forbids blocking on.
