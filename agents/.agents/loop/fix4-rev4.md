# FIX-4 rev4 — dedup, pi stand-alone, graft conditional, recount

Response to `fix4-rev3-review.md`. All four REFUTED/defect findings are addressed on the
files themselves, and every number below is produced by a script in this directory that a
reviewer can rerun.

Files touched (all owned by me): `~/.agents/AGENTS.md`, `~/.agents/references/*.md`,
`~/.pi/agent/AGENTS.md`. `~/.commandcode/AGENTS.md` is unchanged (it already imports the
shared file with `@~/.agents/AGENTS.md`, so it picks up the new rules for free).

## 1. What changed

**Dedup (job 1).** Every reference file was rewritten against the new inline text, keeping
only sentences the inline file does not carry. What survives is command forms, pointer
forms, mechanics and rationale — no restated rules.

- `references/memory-tool-economy.md` was 100% duplicate in substance (both of its rules
  are inline verbatim). **Deleted**, and its index line removed. Now 7 files, 7 index lines.
- The "Folded originals (kept for traceability)" block in `memory-never-block.md` was a
  verbatim copy of the rules above it. Deleted — traceability lives in this loop, not in a
  second live copy.
- `memory-code-lookup.md` dropped the duplicated assertions (open-only-when, callers depth,
  tokens-saved) and kept the six command forms plus the deepwiki example.

**pi stand-alone (job 2).** `~/.pi/agent/AGENTS.md` now inlines all nine shared topics:
clarify, harness-home, never-block, code-lookup, subagents, tool-economy, web-access, order,
plus its two harness-local sections (EGM, herdr). Nothing rule-bearing sits behind a pointer
in pi any more. The authorized-duplication note is kept with its one line of justification
("pi has no `@` import… a rule behind a pointer fires only if a model chooses to go read
another file"). The closing paragraph now says what is true after the change: the references
add forms and rationale only, and no rule depends on reading them.

**Harvest (job 3).** Added to the shared inline file, and to pi with it:

- `Scale: 0 = one reading, complete requirements; 10 = no usable reading.` (72 B) — without
  it the trigger "read when a prompt looks ambiguous" cannot be judged. Fixed the F5
  paradox.
- `Long means builds, tests, watchers, servers, any headless agent run.` (69 B) — fixed the
  F5 scope loss that made "slow" undefined at decision time.
- pi got the reviewer's F3 list items 3–9 (never-block ×2, tool output, upstream paste,
  same-scope re-run, vendored dependency, oc/donsetch) as the never-block, tool-economy,
  subagents and web-access sections.

**graft conditional (job 4).** `graft` is not on PATH on this machine (`command -v graft`
is empty; `oc` and `hc` are present). Every graft rule is now conditional:

```
- If `graft` exists, use it for local code; otherwise grep and read.
- If `graft` exists: `graft build` once where no graph exists, `graft callers --depth 2`
  before a signature change, tokens-saved tally to close the turn.
```

Same conditional wording in pi and at the top of `memory-code-lookup.md`. The test asserts
that no line matches `^- (Use|Run) ` + backticked `graft` — result: 0 unconditional
assertions.

## 2. Byte counts

| file | before | after | cap |
|---|---|---|---|
| `~/.agents/AGENTS.md` | 3749 | **3789** | 4096 |
| `~/.pi/agent/AGENTS.md` | 2940 | **4839** | none |
| `~/.commandcode/AGENTS.md` | 2589 | 2589 | none |
| `references/` (7 files) | 8752 (8 files) | **3294** | none |

Shared file grew 40 B net: +141 B of new rules, −101 B recovered by merging six lookup
bullets into four. **Cap usage: 3789/4096, 307 B spare.** The cap forced nothing; the two
missing rules cost 141 B and 347 B were available, exactly as the reviewer measured.

## 3. Duplicate percentage, BEFORE and AFTER

Two measures, both scripted:

- **words** = share of a reference's words (len > 2) that also occur in
  `~/.agents/AGENTS.md`. This is the reviewer's measure — it reproduces their 61%
  (I get 60.1% on the pre-fix files).
- **duplicate %** = share of a reference's bytes in sentences whose content words are
  >= 70% present inline, i.e. near-verbatim paraphrase. This is the measure that decides
  "delete it".

| reference | before (words) | before (dup %) | after (words) | after (dup %) |
|---|---|---|---|---|
| memory-clarify.md | 71.0% | 33.7% | 62.9% | **0.0%** |
| memory-code-lookup.md | 54.2% | 9.1% | 51.6% | **0.0%** |
| memory-flow.md | 63.0% | 22.2% | 47.2% | **0.0%** |
| memory-harness-home.md | 66.1% | 35.6% | 59.0% | 15.0%* |
| memory-never-block.md | 59.2% | 10.6% | 52.8% | **0.0%** |
| memory-subagents.md | 59.2% | 20.2% | 47.6% | **0.0%** |
| memory-tool-economy.md | 67.2% (100% of its rules) | 24.5% | — deleted — | — |
| memory-web-access.md | 39.4% | 12.0% | 28.2% | **0.0%** |
| **overall, byte-weighted** | **60.1% words / 18.6% dup** | | **50.4% words / 2.3% dup** | |

Duplicated bytes in the reference set: **1628 B before → 75 B after** (−95%).

\* The one remaining flagged sentence is `Where the harness reads one fixed filename
instead, symlink it.` It is not a restatement: it decides *which* pointer form to use,
which the inline bullets do not. It scores high only because `harness` and `symlink` are the
topic's own vocabulary. Every other reference sentence that reuses inline wording is gone.

Word coverage cannot reach 0 while references name the tools the rules name (`codemode`,
`oc`, `graft`, `deepwiki`); 50.4% words is the floor for form files. The sentence measure,
which is what "duplicate" means, is at 2.3% and every file passes the unique-sentence test
below.

## 4. Test: read the pi file alone, list the 9 topics

`fix4-rev4-pi-check.py` reads only `~/.pi/agent/AGENTS.md`, probes one rule sentence per
topic (not a path, not a filename), and additionally asserts that every shared inline rule
appears in pi and that no graft line is unconditional.

```
COVERED  1 clarify          probe=Score each prompt 0-10
COVERED  2 harness-home     probe=harness-agnostic home
COVERED  3 never-block      probe=Never block on an agent
COVERED  4 code-lookup      probe=If `graft` exists
COVERED  5 subagents        probe=the native `agent` tool
COVERED  6 tool-economy     probe=Batch independent reads
COVERED  7 web-access       probe=Never retry a denied built-in call
COVERED  8 order            probe=starts with the `flow` skill
COVERED  9 EGM              probe=/skill:egm-*

topics covered: 9/9
COVERED  A herdr/hc              COVERED  C long definition
COVERED  B clarify scale         COVERED  D graft is conditional

unconditional graft assertions: 0 (none)
shared rules missing from pi: 0
```

## 5. Test: every remaining reference says something inline does not

`fix4-rev4-unique-check.py` — exit 0 only if each file has >= 1 sentence below the 70%
inline-coverage threshold:

```
OK  memory-clarify.md        unique sentences=3   e.g. A wrong assumption costs a whole turn of work…
OK  memory-code-lookup.md    unique sentences=13  e.g. `graft skeleton <file>` gives a file's API in ~200 tokens.
OK  memory-flow.md           unique sentences=4   e.g. `flow` lives at `~/.agents/skills/flow/SKILL.md`.
OK  memory-harness-home.md   unique sentences=7   e.g. Where the harness reads one fixed filename instead, symlink it.
OK  memory-never-block.md    unique sentences=6   e.g. `run_in_background=true` or `monitor_command`.
OK  memory-subagents.md      unique sentences=11  e.g. the native agent tool returns one result; several in one turn run concurrently.
OK  memory-web-access.md     unique sentences=7   e.g. `oc open <url>` returns a compact numbered view.
```

Index integrity: `ls references/` and the `references/memory-*.md` paths in § References are
set-equal (7 and 7, `diff` clean); no orphan file, no dangling entry; pi's Detail list names
the same 7 basenames.

## 6. Imperative recount — reviewer's method

Method, per the review: (1) keyword pass on `must|never|always|do not|don't|only|may only`;
(2) manual pass for keyword-free imperatives; (3) each rule unit counted once, however many
files carry it, with split rows where one bullet carries two obligations (e.g. "one wait
alone…" and "ends on the event").

Results: **63 unique rule units** = 25 keyword-bearing + 38 from the manual pass (36
keyword-free imperatives + 2 definitions that are load-bearing: the 0–10 scale and "long
means…"). The keyword pass produces 55 raw fragments across the 10 live files; 19 of those
are the authorized pi copies, and 11 are descriptive/index lines, leaving the 25 keyword
units in the table. Locations: **43 inline, 12 harness-local, 8 reference**.

The reviewer's ≈50 and this 63 are not the same quantity: they counted the union of the
originals' fragments at bullet granularity, this counts obligations after merging six lookup
bullets into four (−3) but splitting merged obligations (+11: N8, L2/L3/L4, S7, K3, R8…).

Every row is grep-proved: `fix4-rev4-count.py` asserts each `proof` substring occurs in the
file(s) the row claims and exits non-zero on any miss. Current run: **0 failed proofs**.

| id | rule unit | method | where | grep proof (must match the named file) |
|----|-----------|--------|-------|----------------------------------------|
| C1 | score each prompt 0-10 before acting; >3 do not start | kw | **inline** | `Score each prompt 0-10 before acting` |
| C2 | scale: 0 = one reading, 10 = no usable reading | manual(def) | **inline** | `Scale: 0 = one reading` |
| C3 | ask at most 4 score-moving questions, re-score, act at <=3 | manual | **inline** | `Ask at most 4 score-moving questions` |
| C4 | state score and competing readings in one line | manual | **inline** | `State the score and competing readings` |
| C5 | ask only work-changing ambiguities, never preferences | kw | **inline** | `Ask only about ambiguities that change the work` |
| C6 | applies to every prompt incl short ones and follow-ups | manual | **inline** | `Apply this to every prompt` |
| C7 | never resolve ambiguity by silent assumption | kw | **inline** | `Never resolve ambiguity by silent assumption` |
| C8 | told to skip: state score/readings/assumption, proceed on confirm | kw | **inline** | `Told to skip: state score` |
| H1 | always prefer ~/.agents over harness dirs | kw | **inline** | `Always prefer `~/.agents` over harness dirs` |
| H2 | keep canonical shared files under ~/.agents | manual | **inline** | `Keep canonical shared files under `~/.agents`` |
| H3 | harness files only import/symlink/point; no duplicated content | kw | **inline** | `Harness files may only import, symlink or point there` |
| H4 | fixed path -> content in ~/.agents + smallest pointer | manual | **inline** | `keep the content in `~/.agents` and add the smallest pointer` |
| N1 | long means builds, tests, watchers, servers, headless agent runs | manual(def) | **inline** | `Long means builds, tests, watchers, servers` |
| N2 | never block a shell command; background or monitor it | kw | **inline** | `Never block a shell command` |
| N3 | never sit in a blocking shell call | kw | **inline** | `Never sit in a blocking shell call` |
| N4 | never block on an agent; launch detached, wake on completion | kw | **inline** | `Never block on an agent` |
| N5 | no shell_output(wait) or poll loop around agent/long job | kw | **inline** | `Do not wrap `shell_output(wait)` or any poll loop` |
| N6 | say one line what is running, then stop | manual | **inline** | `Say one line about what is running` |
| N7 | peek with shell_output, report one line | manual | **inline** | `Peek with `shell_output` and report one line` |
| N8 | one wait alone or none; ends on event, never timer loop | kw | **inline** | `One wait alone, or none` |
| N9 | user waiting on one delegated result -> one event-wait same turn | manual | **inline** | `User waiting on one delegated result` |
| N10 | kill what you started before done; free ports | manual | **inline** | `Kill what you started before calling the task done` |
| L1 | if graft exists use it for local code, else grep and read | manual | **inline** | `If `graft` exists, use it for local code` |
| L2 | graft build once where no graph exists | manual | **inline** | ``graft build` once where no graph exists` |
| L3 | graft callers --depth 2 before a signature change | manual | **inline** | ``graft callers --depth 2`` |
| L4 | close a graft turn with its tokens-saved tally | manual | **inline** | `tokens-saved tally to close the turn` |
| L5 | deepwiki for dependencies or other repos | manual | **inline** | `Use deepwiki for dependencies or other repos` |
| L6 | never clone or grep a vendored dependency | kw | **inline** | `never clone or grep a vendored one` |
| L7 | open a file only when new, unindexed or truncated mid-span | kw | **inline** | `Open a file only when it is new` |
| S1 | native agent tool; several in one message run concurrently | manual | **inline** | `the native `agent` tool; several in one message run concurrently` |
| S2 | detached work: pubsub_fire | manual | **inline** | `Detached work: `pubsub_fire`` |
| S3 | hand off on disk with absolute artifact paths | manual | **inline** | `Hand off on disk with absolute artifact paths` |
| S4 | never paste upstream content into a prompt | kw | **inline** | `Never paste upstream content into a prompt` |
| S5 | bound scope: labelled slices, one artifact each | manual | **inline** | `Bound scope: labelled slices` |
| S6 | never re-run a failed task at the same scope | kw | **inline** | `Never re-run a failed task at the same scope` |
| S7 | delegations send build/test output to a file, return pass/fail+counts | manual | **inline** | `return pass/fail plus counts` |
| T1 | batch independent reads/greps/MCP into one codemode script | manual | **inline** | `Batch independent reads, greps and MCP lookups` |
| T2 | never print or return raw tool output; extracted fields only | kw | **inline** | `Never print or return raw tool output` |
| W1 | read pages with oc, not the built-in fetcher | manual | **inline** | `Read pages with `oc`` |
| W2 | denied built-in fetch -> donsetch MCP tools | manual | **inline** | `use the `donsetch` MCP tools` |
| W3 | never retry a denied built-in call | kw | **inline** | `Never retry a denied built-in call` |
| O1 | real repo work starts with the flow skill | manual | **inline** | `starts with the `flow` skill` |
| O2 | questions, research and chat do not need it | kw | **inline** | `Questions, research and chat do not need it` |
| E1 | EGM skills are /skill:egm-*; sources under the bundle root | manual | **harness-local** | `/skill:egm-*` |
| E2 | resolve bundle paths against the bundle root, never cwd | kw | **harness-local** | `against the bundle root, never against the working directory` |
| Q1 | never spawn an agent through hc/herdr in one-shot mode | kw | **harness-local** | `Never spawn an agent through `hc`/`herdr` in one-shot mode` |
| Q2 | interactive form hc run --bg, then send/read/wait | manual | **harness-local** | ``hc run --bg --name <name> pi`` |
| Q3 | spawned agent task text must tell it to report back | kw | **harness-local** | `must tell it to report back` |
| Q4 | check on it: hc ls, hc read --lines 80, session log | manual | **harness-local** | `Check on it rather than assuming` |
| K1 | the blocking shell tool to avoid waiting on is shell_command | manual | **harness-local** | `The blocking shell tool` |
| K2 | key background launches by toolCallId, do not parse the result | kw | **harness-local** | `do NOT parse the agent tool result` |
| K3 | wake via cmd.sendUserMessage or cmd.prompt.submit; queues never start a turn | kw | **harness-local** | `queues NEVER start a turn` |
| K4 | mods cannot agent_output, so the wake text must instruct collection | kw | **harness-local** | `the wake text must instruct the model to collect` |
| K5 | background manager is in-memory, per-session; nothing persists | manual | **harness-local** | `nothing persists across exit` |
| K6 | debug with herdr agent list / pane process-info; reload manifests | manual | **harness-local** | `Debug with `herdr agent list`` |
| R1 | graft skeleton/ask/grep/map forms | manual | **reference** | ``graft skeleton <file>`` |
| R2 | deepwiki ask_wiki_question repoName form; read_wiki_structure only when unsure | kw | **reference** | ``read_wiki_structure` first, only when you do not know what to ask` |
| R3 | oc open/do/find/read/next/raw forms and site shortcuts | manual | **reference** | ``oc next`, `oc raw [url]`` |
| R4 | donsetch tool names (web_search/web_fetch/web_crawl) | manual | **reference** | ``mcp__donsetch__web_crawl`` |
| R5 | pointer forms cheapest first: import, symlink, inline repeat | manual | **reference** | `An import line where supported` |
| R6 | flow skill path and what it names per phase | manual | **reference** | `names one default skill per` |
| R7 | agent-tool concurrency semantics and pubsub mechanics | manual | **reference** | `Why bound the scope` |
| R8 | wait/peek flags: run_in_background, monitor_command, from_offset, wait:exit | manual | **reference** | ``run_in_background=true` or `monitor_command`` |

## 7. What is still pointer-only

Nothing rule-bearing. The only pointers left are:

- pi's closing "Detail" paragraph — forms and rationale only; the pi test proves all 43
  inline rules are already in the file.
- the 8 reference rows in the table — command syntax, not obligations.
- `~/.commandcode/AGENTS.md` discusses *how* the background wake-up works; the rule ("never
  block on an agent") is inline in the shared file that cmd imports.

## 8. Reviewer findings, disposed

| # | Finding | Disposition |
|---|---|---|
| F1 | count irreproducible, 15 keyword-free imperatives missed | recounted with their method; keyword-free rows are labelled `manual` in the table (38 of 63) |
| F2 | 61% duplicate, tool-economy 100% | deduped: 2.3% sentence-duplicate after, duplicated bytes 1628 → 75; tool-economy deleted with its index line |
| F3 | pi loads 5 of 9 topics and refutes itself | 9/9 covered, tested by reading the pi file alone; 0 shared rules missing |
| F4 | index integrity | still confirmed: 7 files, 7 entries, set-equal |
| F5 | cap honesty, trigger paradox, undefined "slow" | 307 B spare and stated as such; scale and long definition now inline (141 B) |
| F6 | nothing points at the old layout | re-checked: no live file references `memory-tool-economy.md` (grep hits are session logs only) |
| F7 | `graft` does not exist | confirmed absent; all graft rules now conditional, 0 unconditional assertions |

## 9. Reproduce

```
python3 ~/.agents/loop/fix4-rev4-count.py        # 63 rows, grep-proof per location
python3 ~/.agents/loop/fix4-rev4-pi-check.py     # 9/9 topics, 0 shared rules missing
python3 ~/.agents/loop/fix4-rev4-dup.py          # per-file duplicate % before/after
python3 ~/.agents/loop/fix4-rev4-unique-check.py # every reference has a unique sentence
```

Skipped / not checked: did not run `oc` or `hc` to confirm their behaviour, only that they
are on PATH; did not re-audit FIX-1's file set. Risk: the one 15%-flagged harness-home
sentence is a vocabulary overlap, not a copied rule — if a future edit copies a rule into a
reference again, only the sentence measure will catch it, and it should be run before any
claim about duplication.
