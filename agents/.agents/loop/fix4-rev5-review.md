# FIX-4 rev5 — antagonist review (falsification round)

**Verdict: PASS, with two defects found and one wording overreach. No claim in the
verdict set is arithmetically false, but "proven" is too strong for the counter,
and one tool name in the pi file does not exist in pi.**

| # | claim | result |
|---|---|---|
| 1 | counter fails on an unclaimed bullet | True on coverage, **false on classification** (T5/T6) |
| 2 | 39 obligations, trivials excluded honestly | 39 reproducible; **±2 classification slack** (N6, N7, C6, O2) |
| 3 | 51.2 % with-pi | Reproduces (4099/8008); **structural**, not a defect |
| 4 | one 25 % threshold, every file | Reproduces; **no file within 2 points**; decision-invariant for 19.8–42.1 |
| 5 | bash/intercom/hc real, no dead name left | bash/intercom/hc/hc-wait all real; **`donsetch` is dead in pi** |
| 6 | 28/28 paths; "long" defined once | 28/28 from /tmp; per-file once, no `slow` |

---

## 1. The counter-fails test (the whole point)

Baseline, live files, from `/tmp`: exit 0, `OBLIGATIONS: 39`, `unclaimed=0`.
Then six hostile edits on a `/tmp` copy of the tree with a fake `HOME` (the script
resolves every path through `Path.home()`, so `HOME=/tmp/fx5/h` is enough):

| test | edit | exit | output |
|---|---|---|---|
| T1 | add `- Never assume a tool exists…` to `~/.agents/AGENTS.md` | **1** | AssertionError: shared content bullets not 1:1 with rows |
| T2 | add `- Always use the shared file as the only source of truth…` to pi file | **1** | `unclaimed=1` |
| T3 | add one bullet to `~/.commandcode/AGENTS.md` | **1** | `unclaimed=1` |
| T4 | delete `- Never retry a denied built-in call.` from shared | **1** | AssertionError |
| T5 | re-class K1 `syntax` -> `obligation` | **0** | `OBLIGATIONS: 40` |
| T6 | re-class N8 `obligation` -> `descriptive` | **0** | `OBLIGATIONS: 38` |

The counter can fail, so it is not vacuous. But note what fails: coverage (every
bullet mapped to a row) and proof strings. What cannot fail is the **number**, and
that is what the claim calls "proven". `OBLIGATIONS: 39` is
`len([r for r in ROWS if r[1] == "obligation"])` — a hand-written label, printed
verbatim. T5 and T6 move it by ±1 with exit 0.

Correct wording for the report: **"39 bullets classified `obligation`; every bullet
in all three files is claimed by exactly one row; exit 1 on any unclaimed bullet or
missing proof."** Drop "proven by".

Second, smaller: the docstring's rule 2 says the only never-counted exception is a
pi bullet *byte-identical* to a shared one. There are two mechanisms. Measured:
47 shared content bullets, **43 byte-identical** in pi, **4 reworded** (`N1p`,
`N5p`, `S1p`, `S2p`) and claimed as explicit `class=copy` rows. Nothing is hidden —
they have their own lines — but rule 2 does not describe the method. `S1p` ("pi has
no in-process subagent tool: … never inline") is a duty, not a copy; it is correctly
*not added* (the same duty as shared S1), but the class name misdescribes it.

## 2. Is 39 the right number?

Load-bearing, all correctly `obligation`: **C1** (score gate), **C5** (no silent
assumption), **N1** (never block a shell command), **S1** (delegate, not inline),
**Q1** (interactive agents only). Plus H2, which is the rule this whole round
enforces.

Trivial end, all counted as obligations:
`N4` "Say one line about what is running" · `N6` "One wait alone, or none" ·
`N7` "User waiting on one delegated result: one event-wait, same turn" ·
`C6` "Told to skip: state score, open readings, assumption" · `O2` "Questions,
research and chat do not need it".

Were trivials smuggled in to inflate? The exclusions are honest — definitions (3),
syntax (4), index (7), descriptive (10), copies (4) are not duties, and the shared
census balances exactly (47 = 38 + 2 + 7). The pressure is at the *inclusion* edge,
not the exclusion edge:

- `N6` restates `N3`'s prohibition and adds a permission; two rows, one rule.
- `N7` and `C6` are shaped "condition: duty" — literally the script's own
  `descriptive` definition ("recorded fact **or recipe condition**").
- `O2` is a permission ("do not need it"), not a directive.

So 39 is defensible but not tight: 37–39 is the honest range, and the script would
not notice the move (T5/T6). Direction is conservative (over-counting duties
understates how small the rule set is), so no action needed beyond the wording.

## 3. The 51.2 % with-pi figure — where is the floor

Reproduced from `fix4-rev5-sets/after --with-pi`: `pi-AGENTS.md 5113 B sentences,
3841 duplicate, 75.1 %`; aggregate `4099/8008 = 51.2 %`. Before: `3048/7402 = 41.2 %`.
Exact-line copy also reproduces, 48 of 52 lines >20 chars, 3597 B.

Split of pi's 3841 duplicate bytes by kind:

| kind | bytes | share |
|---|---|---|
| rule text (the inline itself) | 3151 | 82 % |
| index/pointer lines (`References` x7 + `Detail`) | 690 | 18 % |

Of pi's 51 bullets, **43 are byte-identical copies, 4 are reworded copies, 4 are
pi-local** (`E1`, `E2`, `F1`, `F2`). A pi session reads `~/.agents/AGENTS.md` only
if a model chooses to; the header says so and H2 authorises it. So every shared
rule must be restated or pi is blind on that rule. There is no rule that can be
dropped: dropping C1 makes pi skip the ambiguity gate, dropping N1 makes it block,
dropping Q1 makes it spawn one-shot agents that cannot report back.

The only duplication that is **not forced** is the 690 B pointer block: 7 index
lines plus the `Detail` paragraph, which duplicate the shared index and carry no
rule. Deleting them moves the aggregate to ~42.6 % and leaves every rule intact,
but also removes pi's map to the command forms — so it is not free either.

**Ruling: the pi duplication is structural. Stop calling 51.2 % a defect.** It is
the cost of D12 (no `@` import), it is documented in the pi header, and the honest
per-harness metric excludes it (8.9 %). The one way to lower it is the
symlink + `APPEND_SYSTEM.md` route, which the report already lists as untested and
which risks silently disabling every pi rule.

## 4. Threshold table — every reference, one bar at 25 %

Cutoff 0.65, byte-weighted, from `fix4-rev5-dup.py`:

| file | before | after | vs 25 % | disposition |
|---|---|---|---|---|
| memory-clarify.md | 0.0 % | 0.0 % | under, 25.0 clear | kept |
| memory-code-lookup.md | 7.7 % | 14.6 % | under, 10.4 clear | kept |
| memory-flow.md | 0.0 % | 0.0 % | under, 25.0 clear | kept |
| memory-harness-home.md | 15.0 % | 19.8 % | under, **5.2 clear** | kept |
| memory-never-block.md | 17.5 % | 0.0 % | under | kept |
| memory-subagents.md | 10.7 % | 11.1 % | under, 13.9 clear | kept |
| memory-web-access.md | 6.8 % | 6.8 % | under, 18.2 clear | kept |
| memory-tool-economy.md | **42.1 %** | deleted | over, 17.1 above | deleted |

**Within 2 points of 25 %: none.** Nearest is `memory-harness-home` at 19.8 %,
5.2 points under. The 25 % bar sits inside a 22-point gap (19.8 -> 42.1), so every
threshold in that open interval produces the identical keep/delete split. 25 % is
therefore not a tuned number, and no file's fate is fragile.

Two caveats the report already declares, restated so they are not lost:
the 42.1 % is measured on a **304 B reconstruction** of a 414 B deleted file, and
`memory-never-block`'s 17.5 -> 0.0 is partly **rewording**, which a 0.65 token gate
cannot see. That is the metric's blind spot, not a hidden duplicate.

Robustness nit: `fix4-rev5-dup.py ~/.agents --with-pi` on the **live tree** prints
8.9 % twice, because it looks for `<set>/pi-AGENTS.md` and silently skips when it
is absent. 51.2 % reproduces only from `fix4-rev5-sets/after`. The script should
say "no pi file in <set>" instead of silently measuring without it.

## 5. Tool names in the pi file

| name | real in pi? | evidence |
|---|---|---|
| `bash` | yes | harness tool list; `bash-guard.ts` extension |
| `intercom` | yes | `pi-intercom` package in `settings.json`, tool live this session |
| `hc run --bg` / `hc send` / `hc read` / `hc wait` | yes | `/home/prm/.local/bin/hc`; `hc wait <t>` is a documented subcommand |
| `tail`, `nohup` | yes | `/usr/bin/tail`, `/usr/bin/nohup` |
| `oc` | yes | `/home/prm/.npm-global/bin/oc` |
| `codemode` | yes | `defaultTools: +codemode` |
| `deepwiki` | yes | `~/.pi/agent/mcp.json` -> `deepwiki` |
| `/skill:egm-*` | yes | package `git:…/elephant-goldfish-model`; 7 skills present; absent from the model-invocable list because `disable-model-invocation: true` (user-invoked only) |
| `graft` | conditional, absent | rule reads "If `graft` exists"; no graph here, so not a false claim |
| **`donsetch`** | **NO** | `~/.pi/agent/mcp.json` has only `deepwiki` (+ disabled `superlogical`); `donsetch` is registered in `~/.commandcode/mcp.json` only |

`shell_output`, `pubsub_fire`, `agent`, `run_in_background`, `monitor_command`,
`agent_output` are gone from both shared and pi — that part of the claim holds.

**Defect: the pi file's W2 bullet, `- If built-in search or fetch is denied, use
the donsetch MCP tools.`, points at three tools pi does not expose.** A pi session
whose fetch is denied has no fallback. `fix4-rev5-verify.py` misses it because
`donsetch` is not in its `FAKE` list — the list only contains the four names that
were removed. One pi-local clause fixes it (e.g. `pi: no donsetch; use
web_search/fetch_content`), and the bullet then becomes a fifth reworded copy
rather than a byte-identical one.

## 6. Portability and "long"

`python3 ~/.agents/loop/fix4-rev5-verify.py` from `/tmp`: **28/28 path checks PASS**
(9 in `~/.agents/AGENTS.md`, 15 in pi, 4 in cmd), index set-equal 7/7, no relative
`references/` path left, cmd's `@` target is the canonical file, 0 failed checks.
Risk note, not a defect: `~/.agents/AGENTS.md` is **4083 / 4096 B, 13 B spare** —
one short bullet from the cap.

`long`: defined once per file — `~/.agents/AGENTS.md:18`, byte-identical at
`~/.pi/agent/AGENTS.md:22` (the D12 inline, not a second definition). Used 2x per
file ("long work", "long job") plus the index's "before long work". `grep -w slow`
over shared, pi and all 7 references: **no match**.

---

## What I could not falsify

The 39 -> 38+1 arithmetic, the 8.9/51.2 and 9.4/41.2 pairs, the 42.1 vs 19.8
ordering, the 48/52-line 3597 B copy figure, 28/28 path resolution, and the
absence of `slow` and of the four removed tool names all reproduce byte-for-byte.
The `flow`-behind-a-pointer gap in `memory-code-lookup.md` is self-declared in §8,
so it is a known limit rather than a false claim.

## What must change before this is called done

1. **`donsetch` in the pi inline** — one clause, otherwise point 5 is false.
2. **Drop "proven"** for the counter; say "classified, coverage-enforced", and
   record the 37–39 range for N6/N7/C6/O2.
3. Optional: `--with-pi` should error, not silently degrade, when the set has no
   `pi-AGENTS.md`; and add `donsetch` to the verify `FAKE` list once fixed.
