#!/usr/bin/env python3
"""FIX-4 rev4 imperative inventory.

Method: reviewer's, not the worker's.
  1. keyword pass  -> lines matching (must|never|always|do not|don't|only|may only)
  2. manual pass  -> imperatives with none of those keywords
  3. each rule unit listed once (cross-file copies are ONE unit)
Every row is grep-proved: `proof` must be a substring of the claimed file(s),
so a row cannot claim a location it is not in.
"""
import sys
from pathlib import Path

A = Path.home() / ".agents" / "AGENTS.md"
P = Path.home() / ".pi" / "agent" / "AGENTS.md"
C = Path.home() / ".commandcode" / "AGENTS.md"
R = Path.home() / ".agents" / "references"

# (id, rule, kind, location, [files], proof-substring)
ROWS = [
 # --- clarify
 ("C1", "score each prompt 0-10 before acting; >3 do not start", "kw", "inline", [A, P], "Score each prompt 0-10 before acting"),
 ("C2", "scale: 0 = one reading, 10 = no usable reading", "manual(def)", "inline", [A, P], "Scale: 0 = one reading"),
 ("C3", "ask at most 4 score-moving questions, re-score, act at <=3", "manual", "inline", [A, P], "Ask at most 4 score-moving questions"),
 ("C4", "state score and competing readings in one line", "manual", "inline", [A, P], "State the score and competing readings"),
 ("C5", "ask only work-changing ambiguities, never preferences", "kw", "inline", [A, P], "Ask only about ambiguities that change the work"),
 ("C6", "applies to every prompt incl short ones and follow-ups", "manual", "inline", [A, P], "Apply this to every prompt"),
 ("C7", "never resolve ambiguity by silent assumption", "kw", "inline", [A, P], "Never resolve ambiguity by silent assumption"),
 ("C8", "told to skip: state score/readings/assumption, proceed on confirm", "kw", "inline", [A, P], "Told to skip: state score"),
 # --- harness-home
 ("H1", "always prefer ~/.agents over harness dirs", "kw", "inline", [A, P], "Always prefer `~/.agents` over harness dirs"),
 ("H2", "keep canonical shared files under ~/.agents", "manual", "inline", [A, P], "Keep canonical shared files under `~/.agents`"),
 ("H3", "harness files only import/symlink/point; no duplicated content", "kw", "inline", [A, P], "Harness files may only import, symlink or point there"),
 ("H4", "fixed path -> content in ~/.agents + smallest pointer", "manual", "inline", [A, P], "keep the content in `~/.agents` and add the smallest pointer"),
 # --- never block
 ("N1", "long means builds, tests, watchers, servers, headless agent runs", "manual(def)", "inline", [A, P], "Long means builds, tests, watchers, servers"),
 ("N2", "never block a shell command; background or monitor it", "kw", "inline", [A, P], "Never block a shell command"),
 ("N3", "never sit in a blocking shell call", "kw", "inline", [A, P], "Never sit in a blocking shell call"),
 ("N4", "never block on an agent; launch detached, wake on completion", "kw", "inline", [A, P], "Never block on an agent"),
 ("N5", "no shell_output(wait) or poll loop around agent/long job", "kw", "inline", [A, P], "Do not wrap `shell_output(wait)` or any poll loop"),
 ("N6", "say one line what is running, then stop", "manual", "inline", [A, P], "Say one line about what is running"),
 ("N7", "peek with shell_output, report one line", "manual", "inline", [A, P], "Peek with `shell_output` and report one line"),
 ("N8", "one wait alone or none; ends on event, never timer loop", "kw", "inline", [A, P], "One wait alone, or none"),
 ("N9", "user waiting on one delegated result -> one event-wait same turn", "manual", "inline", [A, P], "User waiting on one delegated result"),
 ("N10", "kill what you started before done; free ports", "manual", "inline", [A, P], "Kill what you started before calling the task done"),
 # --- lookup
 ("L1", "if graft exists use it for local code, else grep and read", "manual", "inline", [A, P], "If `graft` exists, use it for local code"),
 ("L2", "graft build once where no graph exists", "manual", "inline", [A, P], "`graft build` once where no graph exists"),
 ("L3", "graft callers --depth 2 before a signature change", "manual", "inline", [A, P], "`graft callers --depth 2`"),
 ("L4", "close a graft turn with its tokens-saved tally", "manual", "inline", [A, P], "tokens-saved tally to close the turn"),
 ("L5", "deepwiki for dependencies or other repos", "manual", "inline", [A, P], "Use deepwiki for dependencies or other repos"),
 ("L6", "never clone or grep a vendored dependency", "kw", "inline", [A, P], "never clone or grep a vendored one"),
 ("L7", "open a file only when new, unindexed or truncated mid-span", "kw", "inline", [A, P], "Open a file only when it is new"),
 # --- subagents
 ("S1", "native agent tool; several in one message run concurrently", "manual", "inline", [A, P], "the native `agent` tool; several in one message run concurrently"),
 ("S2", "detached work: pubsub_fire", "manual", "inline", [A, P], "Detached work: `pubsub_fire`"),
 ("S3", "hand off on disk with absolute artifact paths", "manual", "inline", [A, P], "Hand off on disk with absolute artifact paths"),
 ("S4", "never paste upstream content into a prompt", "kw", "inline", [A, P], "Never paste upstream content into a prompt"),
 ("S5", "bound scope: labelled slices, one artifact each", "manual", "inline", [A, P], "Bound scope: labelled slices"),
 ("S6", "never re-run a failed task at the same scope", "kw", "inline", [A, P], "Never re-run a failed task at the same scope"),
 ("S7", "delegations send build/test output to a file, return pass/fail+counts", "manual", "inline", [A, P], "return pass/fail plus counts"),
 # --- tool economy
 ("T1", "batch independent reads/greps/MCP into one codemode script", "manual", "inline", [A, P], "Batch independent reads, greps and MCP lookups"),
 ("T2", "never print or return raw tool output; extracted fields only", "kw", "inline", [A, P], "Never print or return raw tool output"),
 # --- web
 ("W1", "read pages with oc, not the built-in fetcher", "manual", "inline", [A, P], "Read pages with `oc`"),
 ("W2", "denied built-in fetch -> donsetch MCP tools", "manual", "inline", [A, P], "use the `donsetch` MCP tools"),
 ("W3", "never retry a denied built-in call", "kw", "inline", [A, P], "Never retry a denied built-in call"),
 # --- order
 ("O1", "real repo work starts with the flow skill", "manual", "inline", [A, P], "starts with the `flow` skill"),
 ("O2", "questions, research and chat do not need it", "kw", "inline", [A, P], "Questions, research and chat do not need it"),
 # --- pi harness-local
 ("E1", "EGM skills are /skill:egm-*; sources under the bundle root", "manual", "harness-local", [P], "/skill:egm-*"),
 ("E2", "resolve bundle paths against the bundle root, never cwd", "kw", "harness-local", [P], "against the bundle root, never against the working directory"),
 ("Q1", "never spawn an agent through hc/herdr in one-shot mode", "kw", "harness-local", [P], "Never spawn an agent through `hc`/`herdr` in one-shot mode"),
 ("Q2", "interactive form hc run --bg, then send/read/wait", "manual", "harness-local", [P], "`hc run --bg --name <name> pi`"),
 ("Q3", "spawned agent task text must tell it to report back", "kw", "harness-local", [P], "must tell it to report back"),
 ("Q4", "check on it: hc ls, hc read --lines 80, session log", "manual", "harness-local", [P], "Check on it rather than assuming"),
 # --- cmd harness-local
 ("K1", "the blocking shell tool to avoid waiting on is shell_command", "manual", "harness-local", [C], "The blocking shell tool"),
 ("K2", "key background launches by toolCallId, do not parse the result", "kw", "harness-local", [C], "do NOT parse the agent tool result"),
 ("K3", "wake via cmd.sendUserMessage or cmd.prompt.submit; queues never start a turn", "kw", "harness-local", [C], "queues NEVER start a turn"),
 ("K4", "mods cannot agent_output, so the wake text must instruct collection", "kw", "harness-local", [C], "the wake text must instruct the model to collect"),
 ("K5", "background manager is in-memory, per-session; nothing persists", "manual", "harness-local", [C], "nothing persists across exit"),
 ("K6", "debug with herdr agent list / pane process-info; reload manifests", "manual", "harness-local", [C], "Debug with `herdr agent list`"),
 # --- reference-only forms (what inline does not carry)
 ("R1", "graft skeleton/ask/grep/map forms", "manual", "reference", [R / "memory-code-lookup.md"], "`graft skeleton <file>`"),
 ("R2", "deepwiki ask_wiki_question repoName form; read_wiki_structure only when unsure", "kw", "reference", [R / "memory-code-lookup.md"], "`read_wiki_structure` first, only when you do not know what to ask"),
 ("R3", "oc open/do/find/read/next/raw forms and site shortcuts", "manual", "reference", [R / "memory-web-access.md"], "`oc next`, `oc raw [url]`"),
 ("R4", "donsetch tool names (web_search/web_fetch/web_crawl)", "manual", "reference", [R / "memory-web-access.md"], "`mcp__donsetch__web_crawl`"),
 ("R5", "pointer forms cheapest first: import, symlink, inline repeat", "manual", "reference", [R / "memory-harness-home.md"], "An import line where supported"),
 ("R6", "flow skill path and what it names per phase", "manual", "reference", [R / "memory-flow.md"], "names one default skill per"),
 ("R7", "agent-tool concurrency semantics and pubsub mechanics", "manual", "reference", [R / "memory-subagents.md"], "Why bound the scope"),
 ("R8", "wait/peek flags: run_in_background, monitor_command, from_offset, wait:exit", "manual", "reference", [R / "memory-never-block.md"], "`run_in_background=true` or `monitor_command`"),
]

bad = 0
print(f"{'id':4} {'kind':11} {'where':14} proof")
for rid, rule, kind, where, files, proof in ROWS:
    ok = all(proof in f.read_text() for f in files)
    bad += 0 if ok else 1
    print(f"{rid:4} {kind:11} {where:14} {'OK' if ok else 'FAIL'}  {proof[:58]}")

kinds = {}
wheres = {}
for _, _, k, w, _, _ in ROWS:
    kinds[k] = kinds.get(k, 0) + 1
    wheres[w] = wheres.get(w, 0) + 1
print(f"\nunique rule units: {len(ROWS)}   failed proofs: {bad}")
print(f"by method: {kinds}")
print(f"by location: {wheres}")
sys.exit(1 if bad else 0)
