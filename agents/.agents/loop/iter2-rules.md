# Iter 2 — correctness of the rules themselves (read-only)

Lens: do the instructions an agent obeys hold up when executed, and do they contradict each other.
Scope read: `~/.agents/AGENTS.md`, `~/.agents/references/*.md` (7), `~/.agents/skills/flow/SKILL.md`,
`cavecrew/SKILL.md`, `coordinator/SKILL.md`, `/home/prm/.pi/agent/AGENTS.md`,
`/home/prm/.pi/agent/extensions/{bash-guard,herdr-interactive-only}.ts`, `/home/prm/AGENTS.md`,
plus `/home/prm/.pi/agent/{mcp.json,settings.json,skills/}` and pi's own docs to settle capability claims.
Nothing edited. One stray test process was killed (`nohup sleep 300`, see #8).

---

## 1. The clarify HARD RULE says both "then go" and "proceed only on confirm"

**Files.** `/home/prm/.pi/agent/AGENTS.md:14` vs `/home/prm/.agents/references/memory-clarify.md:15`

- pi copy: `- If told to start anyway: state the score and the reading you guessed, then go.`
- authoritative: `- Told to skip: state score, open readings, assumption; proceed only on confirm.`
- and `memory-clarify.md:5` forbids the copy existing at all: `Do not restate this wording elsewhere.`

**Proof**

```bash
grep -n 'If told to start anyway' /home/prm/.pi/agent/AGENTS.md
grep -n 'proceed only on confirm'   /home/prm/.agents/references/memory-clarify.md
```

**Consequence.** Every session starts under this rule, so this is the widest blast radius here.
A pi agent that reads its inline copy proceeds on a bare "just start"; the reference says it must
re-ask. The same user sentence produces opposite behaviour per harness, and an agent that reads
both files has no tiebreak (nothing in either names which wins; `memory-clarify.md` only settles
disagreement with the old `flow` one-liner).

---

## 2. The denied-fetch fallback names MCP tools that are not registered in pi

**Files.** `/home/prm/.agents/AGENTS.md:49`, `/home/prm/.agents/references/memory-web-access.md:8-9`
vs `/home/prm/.pi/agent/AGENTS.md:53`

- canonical: ``- If built-in search or fetch is denied, use the `donsetch` MCP tools.``
- reference: ``mcp__donsetch__web_search``, ``mcp__donsetch__web_fetch``, ``mcp__donsetch__web_crawl``
- pi copy: `pi has none (deepwiki is repo Q&A), so report the denial.`

**Proof**

```bash
cat /home/prm/.pi/agent/mcp.json            # only "deepwiki"; "superlogical" is enabled:false
grep -l donsetch /home/prm/.commandcode/mcp.json /home/prm/.pi/agent/mcp.json
```

`donsetch` exists as a CLI (`/home/prm/.npm-global/bin/donsetch`) and is wired as an MCP server in
**.commandcode** only. Three tool names in the canonical rule therefore do not exist in pi, while
the pi copy of the same rule says the opposite.

**Consequence.** A denied `web_search`/`fetch_content` in pi sends the agent to a tool that is not
in its tool list: it either errors, fabricates a call, or silently gives up, and the two files
disagree about whether a fallback exists at all.

---

## 3. "one event-wait, delivered in the same turn" is impossible under pi's own reference — and capped at 600s

**Files.** `/home/prm/.agents/AGENTS.md:24-25`, `/home/prm/.pi/agent/AGENTS.md:28-29`,
`/home/prm/.agents/references/memory-never-block.md:4,7`, `/home/prm/.pi/agent/extensions/bash-guard.ts:21,38`

- rule: `One wait alone, or none; it ends on the event, never a timer loop.`
- rule: `User waiting on one delegated result: one event-wait, delivered in the same turn.`
- reference: `pi: ... has no wait tool.` and `A harness not listed has no wait tool: end the turn`
- pi's own AGENTS.md tells the agent to use `hc wait <name>` — and `hc wait` exists:

```bash
hc --help | grep -n 'wait'
grep -n 'has no wait tool' /home/prm/.agents/references/memory-never-block.md
grep -n 'hc wait' /home/prm/.pi/agent/AGENTS.md
```

**Consequence.** Three mutually exclusive statements about one capability. The agent that believes
the reference ends its turn with no result (violating "delivered in the same turn"); the agent that
waits through `bash` is killed at 600s by `bash-guard` (`DEFAULT_TIMEOUT_S = 600`, line 21/38) and
reports a stale "still running"; and the only uncapped wait is `intercom ask`, which the never-block
rule forbids by name ("never sit in a blocking call").

---

## 4. Headless agent runs are prescribed by one rule and blocked by another

**Files.** `/home/prm/.agents/AGENTS.md:18` and `:57`, `/home/prm/.agents/skills/flow/SKILL.md:41`,
`/home/prm/.pi/agent/extensions/herdr-interactive-only.ts:51,230`

- `- Long means builds, tests, watchers, servers, any headless agent run.` then background it.
- `- Interactive agents only, never one-shot: a one-shot agent cannot report back.`
- flow fresh-context ladder: `| another agent CLI (cmd, claude, codex) | run it as the reviewer and capture its output |`
- hook: `AGENTS = new Set(["pi","claude","codex","opencode","goose","amp"])`, `codex -> exec` is non-interactive → **block**

**Proof**

```bash
command -v codex            # /home/prm/.local/bin/codex
command -v claude           # MISSING
grep -n 'const AGENTS\|agent === "codex"' /home/prm/.pi/agent/extensions/herdr-interactive-only.ts
sed -n '41p' /home/prm/.agents/skills/flow/SKILL.md
```

**Consequence.** The never-block section's own example ("any headless agent run", backgrounded) and
flow's third fallback row for a fresh-context review both describe a command the hook rejects. The
agent gets a block message mid-review and re-plans; the ladder's `claude` entry is doubly dead
(not installed). `cmd` is *not* in the AGENTS set, so the same table row is safe only for cmd —
the table gives no hint of that.

---

## 5. Two skills installed in pi require a `Task`/`Explore` subagent tool pi does not have

**Files.** `/home/prm/.agents/skills/cavecrew/SKILL.md:9`, `/home/prm/.agents/skills/coordinator/SKILL.md:4`,
`/home/prm/.pi/agent/AGENTS.md:39`

- pi: `pi has no in-process subagent tool: delegate with intercom or hc`
- cavecrew: `Cavecrew = three subagent presets ... Same job as Anthropic defaults (Explore, edit-style agents, reviewer)`
- coordinator frontmatter: `allowed-tools: Bash, Write, Read, Task` — `allowed-tools` is not a pi
  frontmatter field (pi reads `name`, `description`, `disable-model-invocation`), so the gate is
  silently ignored while the body still assumes `Task`.

**Proof**

```bash
ls -d /home/prm/.pi/agent/skills/cavecrew /home/prm/.pi/agent/skills/coordinator
sed -n '4p' /home/prm/.agents/skills/coordinator/SKILL.md
grep -n 'no in-process subagent tool' /home/prm/.pi/agent/AGENTS.md
```

**Consequence.** A pi agent loads `/skill:cavecrew` (it is advertised in pi's skill list) and is told
to delegate to a preset it cannot spawn, or loads coordinator and is told to spawn agents it cannot
spawn. The failure is silent: no error, just a skill that cannot be executed as written.

---

## 6. `/flow` is not a command in pi

**Files.** `/home/prm/AGENTS.md:25`

- `- Entry point for repository work is the flow skill (/flow): it names one skill per phase.`

**Proof**

```bash
ls /home/prm/.pi/agent/prompts /home/prm/.agents/prompt-templates 2>&1   # both: No such file
grep -n 'skill:name' /home/prm/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent/docs/slash-commands.md
```

pi exposes skills only as `/skill:<name>` (`docs/skills.md:50`, `docs/slash-commands.md:59`); there is
no prompt-template that would make `/flow` resolve. pi's own AGENTS.md already uses the correct form
(`/skill:egm-*`).

**Consequence.** The advertised entry point to all repository work does not start: the agent types
`/flow`, gets an unknown command, and (per the ambiguity rule) may then ask instead of working.

---

## 7. `memory-code-lookup.md` sends the agent to a deepwiki tool this machine hides

**File.** `/home/prm/.agents/references/memory-code-lookup.md:14`

- ``read_wiki_structure`` first, only when you do not know what to ask.

**Proof**

```bash
cat /home/prm/.pi/agent/mcp.json    # toolExposure: ask_wiki_question "direct"; read_wiki_structure/read_wiki_contents "hidden"
```

**Consequence.** The one tool the reference names for "I don't know what to ask" is not exposed; the
agent has `ask_wiki_question` only and is told to reach for something hidden instead. Cost is one
wasted turn or a bogus-tool error.

---

## 8. `nohup ... &` — the never-block recipe — escapes bash-guard's hard deadline, while `kill what you started` has no PID to kill

**Files.** `/home/prm/.agents/AGENTS.md:19` (pi copy `/home/prm/.pi/agent/AGENTS.md:23`),
`/home/prm/.pi/agent/extensions/bash-guard.ts:12,36-40`

- guard comments promise `timeout  a hard deadline, then SIGTERM, then SIGKILL after 5s`
- guard wraps each call as `timeout -s TERM -k 5 600 setsid bash -c '<cmd>'`
- rule: `- Kill what you started before done; free the ports.`

**Proof** (run in this session)

```bash
nohup sleep 300 >/tmp/bgtest.log 2>&1 & echo $!     # started 551003
ps -o pid,ppid,stat,cmd -p 551003                    # still S, ppid 742 — guard's timeout already exited
kill 551003
```

**Consequence.** The prescribed backgrounding pattern is exactly the shape the guard cannot police:
the wrapper exits the moment `bash -c` returns, so the child runs unbounded with no supervisor. The
rules never say to record `$!` or the log path, so "kill what you started" is unfulfillable from the
next turn — the agent has no handle and the harness has no list. Result: orphaned watchers/servers
and free port conflicts the agent cannot attribute.

---

## 9. The reporting check reads the spawn command, not the task text the rule governs

**Files.** `/home/prm/.agents/AGENTS.md:58` vs `/home/prm/.pi/agent/extensions/herdr-interactive-only.ts:109,462`

- rule: `- Every spawned agent's task text must tell it to report progress, findings and questions back.`
- hook: `const REPORTING = /intercom|hc send|send-keys|report back|report progress|message me|notify the parent/i;`
  tested against `event.input.command`, i.e. the **bash command**, not the task sent later.

**Proof**

```bash
grep -n 'REPORTING' /home/prm/.pi/agent/extensions/herdr-interactive-only.ts
```

**Consequence.** The documented two-step (`hc run --bg --name n pi`, then `hc send <name> '<task with the
reporting line>'`) emits a warning on the first step every single time, because the task text is not
in that command yet. A rule that is right, policed wrongly: the agent learns to ignore the warning
(the only signal for a real violation) or to stuff reporting words into the spawn command.

---

## 10. The one authorized duplicate has already drifted in four places

**Files.** `/home/prm/.pi/agent/AGENTS.md` vs `/home/prm/.agents/AGENTS.md`, plus
`/home/prm/.agents/references/memory-clarify.md:5` (`Do not restate this wording elsewhere.`)

**Proof**

```bash
diff <(sed -n '/## HARD RULE: clarify/,/^## EGM/p' /home/prm/.agents/AGENTS.md) \
     <(sed -n '/## HARD RULE: clarify/,/^## EGM/p' /home/prm/.pi/agent/AGENTS.md)
```

Divergences: refusal path (#1), never-block recipe, peek command, subagents section, web-access
fallback (#2). Three of the five are justified harness adaptations; the refusal path and the
donsetch one are substantive contradictions, and both were introduced by editing one copy.

**Consequence.** Two files claim to be the same rule set while carrying different obligations. Any
future fix lands in one and the drift widens with no test to catch it — `flow/scripts/check.sh`
validates flow's skill references and `rules.md`, not this duplication.

Side note, same category: `/home/prm/AGENTS.md:16` calls `.pi/agent/skills` a "generated mirror" of
`~/.agents/skills`; it is 34 hand-made symlinks, and pi reads `~/.agents/skills` natively anyway
(`docs/skills.md:61`).

---

## 11. The skill count is stated as 126; it is 128

**Files.** `/home/prm/AGENTS.md:27`

- `- Do not re-derive the tree by reading the 126 SKILL.md files.`

**Proof**

```bash
ls /home/prm/.agents/skills/*/SKILL.md | wc -l      # 128
grep -c '^| ' /home/prm/.agents/skills/README.md    # 129 = header + 128 rows
ls /home/prm/.agents/skills | wc -l                 # 128 dirs, none missing from README
```

**Consequence.** Cosmetic on its own, but the rule's whole point is "trust the README, don't recount".
The number is the one thing in that line that can be checked without work, and it is wrong — an agent
that spot-checks it concludes the generated table has drifted when it has not. (By contrast the "83
symlinks" claim for `.commandcode/skills` is exactly right: `ls -l /home/prm/.commandcode/skills | grep -c '^l'` → 83.)

---

## 12. The graft rules can never fire here, and the step they guard has no named substitute

**Files.** `/home/prm/.agents/AGENTS.md:29-30`, `/home/prm/.agents/references/memory-code-lookup.md:3`,
`/home/prm/AGENTS.md:59`

- `- If graft exists, use it for local code; otherwise grep and read.`
- `- If graft exists: build once where no graph exists, callers --depth 2 before a signature change, tokens-saved tally to close the turn.`
- `/home/prm/AGENTS.md`: `No graft here; rg and fd come from /home/prm/.pi/agent/bin on PATH.`

**Proof**

```bash
command -v graft || echo MISSING
```

**Consequence.** Both bullets are dead weight on this machine, so 3 lines of every session's context
describe a workflow that cannot happen — and the one safety step in them (callers of a symbol before
changing its signature) has no replacement named anywhere. `flow`'s Locate phase says only "plain
grep, find and read calls", which finds the definition, not the callers. An agent that follows the
rule literally skips blast-radius unless it invents the check itself.

---

### Not findings (checked, held up)

- `~/.pi/agent/skills` really does expose flow and the ds-\* skills (pi scans `~/.agents/skills`,
  `docs/skills.md:61`), so "starts with the flow skill" resolves as a skill — only the `/flow`
  spelling is wrong (#6).
- `flow/scripts/check.sh` passes on the EGM bundle and its `rules.md` format (exit 0).
- `memory-clarify.md`'s 4-question budget agrees with both AGENTS.md copies; only the refusal path disagrees.
- `/home/prm/AGENTS.md` layout claims all resolve: `.agents` symlink → `dotfiles/agents/.agents`,
  `update-all.sh`, its log, `skills-overlay/host`, `LEDGER.md`, `loop/`, 83 commandcode symlinks.
- `hc` and `herdr` both exist; the hook's "covered deliberately" shapes match its code.
