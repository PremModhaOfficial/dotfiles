# FIX-4 rev4 — antagonist review

**VERDICT: REFUTED on the dedup headline and on the 63-unit imperative count; CONFIRMED on the byte totals, the 7/7 index set-equality, the tool-economy file's removal from disk, and 0 failed grep proofs; UNVERIFIABLE on every "before" figure.** Reviewer read FIX-4 rev4 against the files on disk. Nothing edited.

## 1. The four scripts, rerun

All four exit 0. Byte totals reproduce exactly: `~/.agents/AGENTS.md` 3789, `~/.pi/agent/AGENTS.md` 4839, `~/.commandcode/AGENTS.md` 2589, `references/` 3294. Index 7 files / 7 entries, `diff` clean. `memory-tool-economy.md` is gone, no live pointer to it.

The deductions do not reproduce as stated:

- `fix4-rev4-dup.py` is scoped to `references/` only and excludes pi. Pi is 4839 B of which **3001 B is verbatim copy of the shared file** (49 of 82 lines match `~/.agents/AGENTS.md` one-for-one). Add pi to the denominator and duplicated bytes are 3001 + 65 = 3066 of 8133 = **37.7%**, not 2.3%. The 2.3% is a references-only number presented as a system number.
- The script labels itself "byte-weighted" but weights `len(str)` (characters). True byte weighting: **1.97%, 65 B**, not 2.3%/75 B. The report's own `references/` row (3294 B) and the script's total (3275) are different units.
- The 70% cutoff decides the answer. Rerun at 0.65 → **8.4%**; at 0.60 → **15.9%**. The surviving restatements sit at 0.60–0.67, i.e. one notch below the cutoff (see §2).
- "before 1628 → after 75" cannot be reproduced: `/tmp/fix4` keeps `dup-before.txt` (output) but **no pre-fix reference set** exists anywhere (`find /tmp ~/.agents -name 'memory-*.md'` → only the current files). The claim "every number is produced by a script a reviewer can rerun" is false for the whole before column.
- `fix4-rev4-count.py` is a hardcoded 63-row table; "0 failed proofs" proves 63 literal substrings exist, nothing about what they mean. `fix4-rev4-pi-check.py:51-58` is the only strong test, and what it actually proves is that every shared bullet appears verbatim in pi — i.e. full duplication.

## 2. Recount: 63 is 49 obligations, ~45 unique

`~/.agents/AGENTS.md` has **8 content headings plus References**, 47 bullets = 40 rule bullets + 7 index lines. "All nine shared topics" (report §1, §4) is a count error: the nine probes include EGM, which is harness-local (`fix4-rev4-pi-check.py:24`). It is 8 shared topics + EGM + herdr.

The 63 rows contain 14 rows that are not imperatives, and the report says so in its own words:

- **8 reference rows** (R1–R8): report §7 — "command syntax, not obligations".
- **2 definitions**: C2 (`AGENTS.md:5`), N1 (`AGENTS.md:20`).
- **4 descriptive harness rows**: E1 (pi:68), K1 (`~/.commandcode/AGENTS.md:23`), K3 (cmd:16), K5 (cmd:18).

63 − 14 = **49 obligations**. Then the clear double/split rows:

| rows | same rule | evidence |
|---|---|---|
| N2 + N3 | one obligation, stated twice | `AGENTS.md:21` and `:22` |
| C1 + C6 | C6 is C1's scope, not a new duty | `AGENTS.md:4` and `:9` |
| H1 + H2 | one rule, two objects | `AGENTS.md:14` and `:15` |
| L2 + L3 + L4 | **one sentence** split into three rows | `AGENTS.md:33-34` |

That leaves **~45 unique obligations**, not 63. Difference 18 > 3, so it must be explained rather than waved through. The honest ledger: growth 42 → 50 was real discovery of keyword-free imperatives; growth 50 → 63 is 15 discovery + 14 non-imperatives + 4 splits relabelled as "rule units".

The reconciliation arithmetic is broken twice: the report says 50 − 3 + 11 = 63, but **50 − 3 + 11 = 58**; and "merging six lookup bullets into four" is **−2**, not −3.

## 3. Paraphrase duplication: the 2.3% is a threshold artifact

Same rule, different words, all scoring under 0.70 and so reported as 0.0%:

1. `references/memory-subagents.md:4-6` — "several in one turn run concurrently — that is the parallelism control, so put genuinely independent work in a single message on purpose" = `AGENTS.md:39`. Score 0.67.
2. `references/memory-never-block.md:7` — "One wait: `wait:"exit"` / `wait:"output"`, in its own message." = `AGENTS.md:27`. Score 0.67.
3. `references/memory-flow.md:3-5` — "which is why repo work starts there and chat does not" = `AGENTS.md:57-58`. Score 0.60.
4. `references/memory-harness-home.md:7-9` — "pi is the one authorized case, because it cannot `@`-import" = the same exception already stated at `~/.pi/agent/AGENTS.md:5`. Score 0.50.
5. `references/memory-harness-home.md:5-6` restates H3/H4 (`AGENTS.md:16-17`) as forms.

So deduped is **not** "no restated rules"; it is "no restatement whose vocabulary overlap reaches 0.70". The ledger's own rule (`~/.agents/LEDGER.md` D12) says duplication is legal only in pi and "everywhere else duplication stays a defect" — rows 1–3 above are defects under D12, not forms.

The deletion standard is also inconsistent. `memory-tool-economy.md` was removed as "100% duplicate"; the report's own table records it at **24.5%** by the sentence measure. So a file measured 75.5% unique was deleted, while `memory-harness-home.md` at **15.0%** duplicate was kept. One threshold for the file being removed, another for the file being defended.

**Is the pi block authorized or a copy?** Both. It is authorized by `~/.pi/agent/AGENTS.md:5` and `LEDGER.md` D12, but it is a full verbatim copy (3001 B), not "the harness-critical rules" D12 permits. The exception is recorded only in pi's own copy and in the loop ledger; the canonical `~/.agents/AGENTS.md:16` still says "do not duplicate content" with no exception, so the one file every harness loads carries the rule that the change violates. A cheaper form H3 itself ranks above inline repeat is available and untested: a symlink at `~/.pi/agent/AGENTS.md` to the shared file, with EGM/herdr in `<agent-dir>/APPEND_SYSTEM.md` (`docs/configuration.md:20`). Caveat: a project `.pi/APPEND_SYSTEM.md` suppresses the agent one (`docs/configuration.md:39`).

## 4. Split-brain: read each file alone

`~/.pi/agent/AGENTS.md` alone covers 8 shared topics + EGM + herdr (10 headings). `~/.commandcode/AGENTS.md` alone covers its 3 local sections and, at load time, all 8 shared topics via recursive `@` expansion (confirmed in the shipped loader: `command-code/dist/cli.mjs`, `expandMemoryImports`, resolves `@~/...` and recurses). So both see the shared rules.

The rules each side **needs and lacks**:

- **pi lacks tools, not text.** Pi inlines `shell_output` (`pi:28`, `pi:30`), the native `agent` tool (`pi:43`) and `pubsub_fire` (`pi:44`). Pi's built-ins are `read, bash, powershell, edit, write, grep, find, ls` plus `codemode`/`tool_search` (`docs/settings.md:46`); `~/.pi/agent/settings.json` adds none of the three, and no installed extension registers them. So the copied never-block/subagent rules are unexecutable in pi, and `Never block a shell command` (`pi:25`) has no background flag in pi's `bash`. **9/9 is word coverage, not capability coverage.**
- **cmd lacks the pointers' base.** The shared index uses relative paths (`AGENTS.md:61-67`, `references/memory-*.md`). The cmd loader expands only `@`-refs and leaves backticked paths untouched, so a cmd session in any project dir resolves them against cwd → dead. pi's copy is the one that carries the absolute directory (`pi:82`). The harness that imports the file cannot follow its index.
- **cmd lacks the herdr delegation rules.** `~/.commandcode/AGENTS.md:3-6` shows cmd uses herdr, but the never-one-shot rule and the must-report-back rule exist only at `pi:75`, `pi:77`. A cmd session can spawn a one-shot `hc ... cmd -p` agent and has no rule against it and no instruction to make it report.
- **pi has a dead cross-pointer.** `pi:3` declares `~/.commandcode/AGENTS.md` "not read in pi", while `references/memory-subagents.md:12-13` sends the reader to exactly that file.

## 5. The 8 reference rows: triggers

In `~/.agents/AGENTS.md` every reference has a read trigger (`:61-67`), so R1–R8 are reachable there. In pi, `pi:82` lists the same 7 basenames with **no triggers**, and pi has no shared index. Under that index line, three rows never get looked for:

- **R2** — `read_wiki_structure` "only when you do not know what to ask" (`references/memory-code-lookup.md:14`). Keyword-bearing rule, absent from pi's inline code-lookup section (`pi:35-41`), and the basename "code-lookup" does not announce a deepwiki ordering rule. **REFUTED row for pi.**
- **R5** — pointer forms cheapest first (`memory-harness-home.md:3-9`): a rule about *which* pointer form to use, reachable in pi only by guessing that "harness-home" holds it.
- **R8** — wait/peek flags (`memory-never-block.md:5-7`): needed at the moment of waiting, when nothing prompts a file read; and the flags are cmd-style, so in pi they are wrong anyway.

This contradicts report §7 "nothing rule-bearing" and `pi:82` "no rule depends on reading them".

## 6. Cap and ambiguity (307 B spare, so terse is a choice)

Confirmed 3789/4096. Quotable two-reading lines:

- `AGENTS.md:20` "**Long** means builds, tests, watchers, servers, any headless agent run." — but the rule it was added for says "**slow** work" (`AGENTS.md:21`). F5's undefined term is still undefined; the fix defines a word the rule does not use. Two readings: slow = long, or slow = latency-sensitive (a 2 s command).
- `AGENTS.md:27` "One wait **alone**, or none" — three readings: the only call in the message; at most one wait per turn; never wait at all.
- `AGENTS.md:24` "Do not wrap ... any **poll loop**" vs `:26` "**Peek** with `shell_output`" — no boundary between a peek and a poll loop, and both actions are described in two lines counted as two rules (N6/N7).
- `AGENTS.md:33-34` "If `graft` exists: build …, callers …, tokens-saved tally to close the turn." — the colon makes the tally read as a graft subcommand; second reading: the tally is unconditional. `graft` is absent (`command -v graft` empty), so the whole section is dead weight on this machine.

## Exact rows that must change

1. `fix4-rev4.md` §6 and §9: recount to **49 obligations / ~45 unique**; label R1–R8 syntax, C2/N1 definitions, E1/K1/K3/K5 descriptive; merge N3→N2, C6→C1, L2-L4→one, H2→H1. Fix 50−3+11 and "six into four".
2. `fix4-rev4.md` §3 headline: publish **65 B / 1.97% byte-weighted** for references, and **37.7%** with pi included; state the 0.70 cutoff and the 0.65/0.60 values. Delete or annotate every "before" number as unreproducible.
3. `references/memory-tool-economy.md` disposition: correct "100% duplicate" to the measured 24.5%, or re-admit the file. Do not apply 24.5% as a delete threshold while keeping 15.0%.
4. `~/.agents/AGENTS.md:16`: record the pi exception in the canonical file, or move the exception citation to `LEDGER.md` D12 and say so at `pi:5`.
5. `~/.agents/AGENTS.md:61-67`: absolute paths (`~/.agents/references/...`).
6. `~/.pi/agent/AGENTS.md:28,30,43,44`: replace `shell_output`/`agent`/`pubsub_fire` with pi's actual tools, or mark the section cmd-only. `:25` must not claim backgrounding pi cannot do.
7. `references/memory-subagents.md:12-13`: make the cmd pointer conditional (`in cmd: …`), or drop it.
8. `references/memory-subagents.md:4-6`, `memory-never-block.md:7`, `memory-flow.md:3-5`, `memory-harness-home.md:7-9`: cut the restated rule clause, keep form/rationale (D12).
9. `~/.pi/agent/AGENTS.md:82`: add per-file read triggers, or accept R2/R5/R8 as rules behind a pointer and correct §7.
10. `~/.agents/AGENTS.md:20-21`: make the defined term and the used term the same word.

Skipped: did not run `oc` or `hc`, did not test the symlink+APPEND_SYSTEM route, did not audit FIX-1. Risk: the 63 and the 2.3% are the two numbers most likely to be quoted downstream, and both are wrong as stated.
