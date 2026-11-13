# FIX-4 rev3 — antagonist review

**VERDICT: REFUTED on the accounting, CONFIRMED on the index and the byte count, CONFIRMED on content survival.**
`~/.agents/AGENTS.md` is 3749 B and every reference path resolves, but "5 imperatives inline", "27 more live in those references" and "42 parsed" do not describe the files on disk. 0 rules were lost — verified independently, not taken from the worker. Reviewer saw FIX-4 rev3.

## F1 — the count is irreproducible (REFUTED)

Re-parsed `/tmp/fix4/orig-{agents,cmd,pi}.md` on the stated rule (must|never|always|do not|don't|only|may only): **41 fragments, 40 unique** (8 agents, 27 cmd, 6 pi; 1 exact repeat of "Never sit in a blocking `shell_command`…" inside `orig-cmd.md`). The worker's 42 cannot be produced from that rule.

Worse, the rule does not parse imperatives. **15 keyword-free imperatives were never counted**, e.g. `Ask at most 4 at a time.` / `State the score and the competing readings in one line before asking.` / `Stop the task before reporting done.` / `Run graft build once where there is no graph yet.` / `Ask deepwiki instead.` / `Close any turn that used graft with its one-line tokens-saved tally.` / `Check on it rather than assuming: hc ls…`. Three table rows are descriptive, not imperatives (30 "Site shortcuts…", 33 "Monitors get a wake-up…", 40 "An extension hook blocks that"), and row 42 is the fragment "Pointer only;". Two rows are the same rule twice (12/18 identical, 10/17 same section).

Real inventory is ≈40 keyword units + 15 keyword-free = **≈50 rule units, not 42**. The 42 is an artefact of a keyword filter.

**0 lost: CONFIRMED.** All 40 keyword fragments reached ≥60% token coverage somewhere, and I hand-traced all 15 keyword-free imperatives into the current files. Nothing dropped.

## F2 — "5 imperatives inline" is false, and the refs are duplicates, not detail (REFUTED)

`~/.agents/AGENTS.md` holds **40 imperative bullets under 7 content headings plus 8 index lines** (`grep -c '^- '` = 48). `loop/fix4-rev3.md` says so itself: "48 short imperative lines under 9 headings". The claim says 5. These cannot both be true; 5 is only the count of rows whose *verbatim original sentence* survived.

Same defect on the other side: of the 27 rows marked REF, **18 are ≥70% token-present inline**, and the other 9 have inline paraphrases ("proceed only on confirm", "Open a file only when it is new, unindexed or truncated mid-span", "one wait… ends on the event, never a timer loop"). Nothing was "moved into a reference"; it was compressed inline **and** copied to a reference. Measured duplication against the inline file: 61% of reference tokens overall, `memory-tool-economy.md` **100%**, `memory-clarify.md` 75%, `memory-harness-home.md` 67%.

Consequences:
- D12 ("duplication allowed in exactly one case: pi") is breached on the shared path. The verbatim-duplication grep missed it only because the inline copy is paraphrased.
- D13 says references hold *verbose material*; instead they restate about 61% imperative text. Two live copies of each rule = drift defect at the next edit.
- `references/memory-tool-economy.md` (414 B) adds no rule at all. Either fold its one unique line into another reference or drop it and its index line.

## F3 — the real risk: refuted for the shared path, confirmed for pi

I tested the 16 trigger-free negative rules (never block shell/agent/poll, kill what you started, never print raw output, batch, never paste upstream content, never re-run at same scope, output redirect, absolute paths, never clone/grep a vendored dependency, open-file-only-when, callers depth 2, never retry a denied call, oc) against the always-loaded files. **In `~/.agents/AGENTS.md` every one scores 1.00.** No REFUTED row on that axis: the compressed inline set does cover safety-, authorization- and "what NOT to do" rules. The originals contain no privacy or destructive-action authorization rule at all, so that category cannot be refuted — it does not exist in this memory set.

But `~/.pi/agent/AGENTS.md` loads only 5 of the 9 topics (clarify, harness-home, order, EGM, herdr). **Never-block, code-lookup, subagents, tool-economy and web-access are absent.** In pi those 16 rules are reachable only through the file's closing paragraph — and that file's own second paragraph says "a pointer line is inert… these rules only fire if a model chooses to go read another file, and these must fire without that choice." The pi file refutes itself. It has no byte cap (2940), so nothing forced the omission.

Fair attribution: this is **not a rev3 regression** — `orig-pi.md` never carried those rules either, and the ref directory is strictly more reachable than the old cmd-only layout. It is still a live defect in what the claim presents as solved.

## F4 — index integrity: CONFIRMED

8 index entries in `~/.agents/AGENTS.md` § References, 8 files in `~/.agents/references/` (`memory-clarify, -code-lookup, -flow, -harness-home, -never-block, -subagents, -tool-economy, -web-access`), set-equal by diff; all 8 resolve relative to `~/.agents`; no orphan file, no non-`memory-*` file, no dangling entry. Every entry carries path + read trigger. `~/.pi/agent/AGENTS.md` lists the same 8 basenames under the absolute directory (resolvable) but **without triggers** — for a harness that cannot import, the filename is the only routing signal. `~/.commandcode/AGENTS.md` ends with `@~/.agents/AGENTS.md`, which is valid: command-code's bundled `reference/memory.md` documents recursive `@path` expansion with `~/` support, so cmd does load all 40 inline rules.

## F5 — cap honesty: bytes true, claim incomplete

`wc -c` = **3749**, cap 4096, 347 spare. Confirmed. Nothing important was cut *for space*: the two load-bearing items missing from the inline text would cost **141 B** together, so the cap was never the binding constraint — the inline/ref classification was.

1. **Trigger paradox in the clarify rule.** Inline says "Score each prompt 0-10 before acting" without the anchors (0 = one reading / 10 = no usable reading), which live only in `memory-clarify.md`. The index line's trigger is "read when a prompt looks ambiguous" — the exact judgement you cannot make without the scale. The rule cannot fire as written.
2. Never-block loses its scope ("builds, tests, watchers, servers, any headless agent run"), so "slow" is undefined at the moment the decision is made.

## F6 — nothing points at the old layout

`grep -rn` over `~/.agents/skills`, `~/.pi/agent/extensions`, `~/.pi/agent/skills` for `NEVER block`, `§ Subagents`, `HARD RULE`, `references/memory`, `.agents/AGENTS`: two hits, both legitimate — `flow/DESIGN.md:22` (states the pointer-is-inert principle, still true) and `worktree/SKILL.md:14` (an unrelated HARD RULE). No line- or section-addressed pointer is stale. `references/memory-subagents.md:19` → `~/.commandcode/AGENTS.md § Background sub-agent wake-up` resolves.

## F7 — one referenced tool does not exist

`graft` is **not on PATH** and no binary exists under `~/.local/bin`, `~/.cargo/bin`, `~/.npm-global/bin` (deepwiki is an MCP server, present in `~/.pi/agent/mcp.json`). Four inline rules and most of `memory-code-lookup.md` are unexecutable as written. Pre-existing, not rev3's doing, but it makes "27 imperatives live in the references" a weaker claim than it reads.

## Rules that must move inline

Shared `~/.agents/AGENTS.md` (347 B spare, 141 B needed):

1. `Scale: 0 = one reading, complete requirements; 10 = no usable reading.` (72 B) — nothing else makes the scoring rule usable.
2. `Long means builds, tests, watchers, servers, any headless agent run.` (69 B).

`~/.pi/agent/AGENTS.md` (no cap — add ~10 lines, never-block / tool-economy / subagents / web):

3. Never block a shell command: start slow work backgrounded or monitored, then return; never sit in a blocking call.
4. Never block on an agent: launch detached, wake on completion; no `shell_output(wait)`, no poll loop; kill what you started.
5. Never print or return raw tool output; batch independent reads, greps and MCP lookups into one `codemode` script.
6. Never paste upstream content into a prompt; hand off on disk with absolute artifact paths.
7. Never re-run a failed task at the same scope; make every delegation send build/test output to a file and return pass/fail plus counts.
8. Never clone or grep a vendored dependency; use deepwiki. Open a file only when new, unindexed or truncated; map callers at depth 2 before a signature change.
9. Read pages with `oc`; never retry a denied built-in call — fall back to `donsetch`.

Skipped: did not verify `oc`/`hc` behaviour by running them; did not audit FIX-1's file set. Risk if shipped as-is: two live copies of every rule will drift, and pi silently loses the never-block and tool-economy rules.
