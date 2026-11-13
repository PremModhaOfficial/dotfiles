# FIX-4 rev5 — memory set: count, threshold, duplication, tools, portability

Files changed (all owned by this ticket):

| file | before | after |
|---|---|---|
| `~/.agents/AGENTS.md` | 3789 B | **4083 B** (cap 4096, 13 spare) |
| `~/.pi/agent/AGENTS.md` | 4839 B | 5540 B |
| `~/.commandcode/AGENTS.md` | 2589 B | 2663 B |
| `~/.agents/references/` (7 files) | 3294 B | 3258 B |
| `~/.agents/references/memory-tool-economy.md` | deleted by rev4 | still deleted, justified in §2 |

New, reproducible, under `~/.agents/loop/`:

```
fix4-rev5-count.py     obligation recount          (exit 1 on any unclaimed bullet)
fix4-rev5-dup.py       one duplication metric      (per file, per set, --with-pi)
fix4-rev5-verify.py    9 checks, runs from any cwd (exit 1 on any failure)
fix4-rev5-pairs.py     the five restatements, before/after
fix4-rev5-sets/        before-live/, before/, after/ snapshots the numbers are taken from
```

Rev4 claims not repeated here. Where a rev4 number appears below it is quoted only
to say what replaced it.

---

## 1. COUNT — 39 classified obligations (coverage-enforced), not 63

**Method** (`fix4-rev5-count.py`, rerun with `python3 ~/.agents/loop/fix4-rev5-count.py`):

1. A bullet is a line starting with `- ` in the three memory files.
2. Every bullet is claimed by exactly one row in the script's table, which carries
   a class and a proof substring. The script fails if any bullet is unclaimed or
   any proof is missing. The one exception is a pi bullet byte-identical to a
   shared bullet: that is the D12 authorised copy of a rule already counted, so it
   is claimed silently and never added.
3. Classes: `obligation` (a standing directive that constrains behaviour),
   `definition` (fixes a term or scale), `syntax` (a command form, no duty),
   `index` (one pointer line), `descriptive` (recorded fact or recipe condition).
4. **The published number is the count of `obligation` rows.** No definition,
   syntax form, index line, descriptive note or D12 copy is ever summed in.
   It is **classified, not proven**: the class is a hand-written label, so
   re-classing a row moves the number with exit 0. Coverage is enforced (every
   bullet claimed by a row, every proof substring present); classification is
   not. Honest range **37-39**, because N6, N7, C6 and O2 are condition-shaped and
   could be read as `descriptive`.

### Result (script output, exit 0, 0 unclaimed, 0 failed proofs)

```
OBLIGATIONS: 39
CLASSIFIED, NOT PROVEN: hand-labelled class; coverage enforced, class not. Honest range 37-39 (N6, N7, C6, O2 are condition-shaped).
NOT COUNTED: definitions=3 syntax=4 index=8 descriptive=10 d12-copies=5
shared content bullets: 40 = 38 obligations + 2 definitions
failed proofs / unclaimed bullets: 0
```

Bullet census: shared 47 (40 content + 7 index), pi 51 (41 identical copies +
5 harness-specific rules + 1 harness-specific index line + 4 local), cmd 10.

### The 39 classified obligations (37-39 honest range)

| # | shared `~/.agents/AGENTS.md` (38) |
|---|---|
| 1-6 | C1 score 0-10 incl. short prompts and follow-ups · C2 at most 4 questions · C3 state score+readings · C4 only work-changing ambiguities · C5 never assume · C6 told to skip: state, confirm |
| 7-9 | H1 prefer `~/.agents`, canonical files there · H2 harness files import/symlink/point only (pi exception named) · H3 fixed path -> content in `~/.agents` + smallest pointer |
| 10-17 | N1 never block a shell command (merged with "never sit in a blocking call") · N2 never block on an agent · N3 no wait/poll loop · N4 say one line then stop · N5 peek the log, report one line · N6 one wait alone or none · N7 user waiting -> one event-wait same turn · N8 kill what you started |
| 18-21 | L1 graft if present · L2 graft build/callers/tally (absorbs rev4 L3+L4) · L3 deepwiki, never clone a vendored dep · L4 open a file only when new/unindexed/truncated |
| 22-28 | S1 harness subagent tool, concurrent in one message · S2 detached spawn · S3 absolute artifact paths · S4 never paste upstream content · S5 labelled slices · S6 never re-run at the same scope · S7 output to a file, return pass/fail + counts |
| 29-30 | T1 batch into one `codemode` script · T2 never return raw tool output |
| 31-33 | W1 `oc` over the built-in fetcher · W2 denied -> a fallback MCP fetch server only when one is configured (pi: none, so report the denial) · W3 never retry a denied call |
| 34-35 | O1 repo work starts with `flow` · O2 chat does not need it |
| 36-38 | Q1 interactive agents only, never one-shot · Q2 task text must tell it to report back · Q3 check on it |

| # | pi-local (1) |
|---|---|
| 39 | E2 resolve EGM `agents/`, `resources/`, `docs/` against the bundle root, never cwd |

Cmd-local contributes **0 obligations**: its sections are a hook's behaviour, a mod
recipe and tool names — `descriptive` (10) and `syntax` (2).

### Not counted, listed separately by design

- **definitions 3** — `AGENTS.md:5` scale, `AGENTS.md:18` what "long" means,
  `pi:78` what `/skill:egm-*` names.
- **syntax 4** — `pi:85-86` herdr command forms, `cmd:24` `shell_command` is the
  blocking tool, `cmd:8` `cmd -p` is the one-shot form.
- **index 8** — `AGENTS.md:62-68` (7, one per reference file) + pi's reworded
  web-access pointer (`I6p`).
- **descriptive 10** — the cmd hook/manifest/wake-up notes (`cmd:5-8, 12-21`).
- **d12 copies 5** — the five pi rule bullets whose wording is harness-specific
  (`N1p`, `N5p`, `S1p`, `S2p`, and `W2p`, added in rev6: pi has no denied-fetch
  fallback).

### Merged before counting (history, so the drop is auditable)

| rev4 rows | now | why |
|---|---|---|
| C6 -> C1 | one bullet | C6 was C1's scope, not a duty |
| H2 -> H1 | one bullet | "keep canonical files there" is H1's object |
| N3 -> N1 | one bullet | "never sit in a blocking call" is the same shell rule |
| L3 + L4 -> L2 | one bullet | one sentence (`AGENTS.md:30`) was split into three rows |
| R1-R8 -> syntax | not counted | command forms, never duties |
| K1, K3, K5 -> descriptive | not counted | facts about cmd's hooks, not standing rules |

The rev4 arithmetic breaks twice and is not reused: 50-3+11 is 58, not 63, and
"six lookup bullets into four" is -2.

---

## 2. THRESHOLD — one number for the whole set: 25 %

**The rule, applied to every file without exception:**

> A reference file is deleted when **>= 25 % of its sentence bytes** restate a
> sentence of `~/.agents/AGENTS.md` at the **0.65** token-containment cutoff
> (byte-weighted). Below 25 % it is kept and trimmed. No second bar exists.

Measurement is §3's metric, unchanged, so the deletion decision and the headline
come from one number.

### Per-file, before -> after

| file | before (0.65) | after (0.65) | vs 25 % | disposition |
|---|---|---|---|---|
| memory-clarify.md | 0.0 % | 0.0 % | under | kept |
| memory-code-lookup.md | 7.7 % | 14.6 % | under | kept (rise is canonical growth, see note) |
| memory-flow.md | 0.0 % | 0.0 % | under | kept, one restating clause cut |
| memory-harness-home.md | 15.0 % | 19.8 % | under | kept, one restating clause cut |
| memory-never-block.md | 17.5 % | **0.0 %** | under | kept, the one above-cut restatement cut |
| memory-subagents.md | 10.7 % | 11.1 % | under | kept, one restating clause cut |
| memory-web-access.md | 6.8 % | 6.8 % | under | kept |
| **memory-tool-economy.md** | **42.1 %** | — | **over** | **deleted**, survivor is `AGENTS.md:44-45` |

Note on the two rises: neither file gained a restatement. `code-lookup` is
unmodified; its score rises because the canonical file gained the herdr section
and absolute path tokens. `harness-home` lost 104 B while one 65 B sentence stayed
flagged, so the ratio rose. Both stay under the bar.

### The deletion, justified against the same 25 %

- rev3 recorded the file at 414 B and its reviewer at `/tmp`-independent evidence:
  "`memory-tool-economy.md` adds no rule at all… 100 % of its rules inline".
- Its rules are `orig-cmd.md:73-78` (the pre-merge source): "Do not fire
  independent reads, greps, or lookups one per message. Put them in a single
  `codemode` script and return only the extracted fields; never print or return
  raw tool output." Both are inline today at `AGENTS.md:44-45`.
- The reconstruction in `fix4-rev5-sets/before/refs/memory-tool-economy.md` is that
  source text, and measures **42.1 %**. Even if all of the ~110 B that rev3's byte
  count implies but no record quotes were unique, the file stays above 25 %
  (>= 26 %). It cannot be kept under the bar the kept files satisfy.
- `memory-harness-home.md` at 15.0 % was kept, so rev4's 24.5 %-vs-15.0 % pair is
  replaced by one cutoff, one metric, one threshold, and the ordering it produced
  is preserved.

If the loop prefers to re-admit the file, the only honest path is to lower the
bar below 26 % for every file, which would delete nothing else today — no file
after this revision exceeds 19.8 %.

---

## 3. DUPLICATION HEADLINE — 0.65 cutoff, both numbers labelled

**Metric** (`fix4-rev5-dup.py`, rerun as shown in §7): sentences = body lines split
on `[.!?]`; tokens = lowercase `[a-z0-9_./-]` runs > 2 chars minus stopwords; a
sentence is duplicate when >= **0.65** of its tokens appear in the canonical text;
percentage is byte-weighted. This is the reviewer's containment rule, parameterised
at the cutoff the review used.

| set | measured | denominator |
|---|---|---|
| **WITHOUT the pi copy**, rev4 live set (7 refs) | **9.4 %** (275 B) | refs sentence bytes 2922 |
| **WITHOUT the pi copy**, plus the deleted file | **12.0 %** (381 B) | 3174 |
| **WITH the pi copy** (refs + pi), before | **41.2 %** (3048 B) | 7402 |
| **WITHOUT the pi copy**, after | **8.9 %** (258 B) | 2895 |
| **WITH the pi copy**, after | **51.2 %** (4099 B) | 8008 |

Both after-numbers, labelled as the ticket asks: **8.9 % without the pi copy**,
**51.2 % with it**. The `union` column that produces them is the same one that gave
8.4 % in the review; the small difference on the live set is the deleted file's
reconstruction and the herdr section, not a changed method.

**The with-pi number rose, and the reason is defect 6, not a new copy:** moving the
herdr rules into the shared file forces pi to repeat them under D12 (a pi session
would otherwise have no delegation rule), and the canonical file grew by 269
sentence bytes, which raises union containment for every file. Exact-line copy is
**48 of 52 shared lines, 3597 B** (`python3 - <<…` in §7); rev4 reported 3001 B,
the difference is the herdr and absolute-path lines. That copy is a D12
authorisation cost. The untested alternative that would remove it is a symlink at
`~/.pi/agent/AGENTS.md` plus `<agent-dir>/APPEND_SYSTEM.md` for EGM and herdr
(`docs/configuration.md:20`, and `:39` warns a project `.pi/APPEND_SYSTEM.md`
suppresses the agent one). Not attempted here: the ticket did not authorise the
layout change, and a wrong symlink would silently stop every pi rule.

### The five restatements — fixed, with the score each carried

Scores are the same metric on the exact before-line (`fix4-rev5-pairs.py`).

| # | before | score | fix |
|---|---|---|---|
| R1 | `memory-subagents.md` "…that is the parallelism control, so put genuinely independent work in a single message on purpose" | 0.29 line / 0.60 clause | clause cut; file keeps the mechanic (one call per turn chains) |
| R2 | `memory-never-block.md` "One wait: `wait:"exit"` / `wait:"output"`, in its own message." | **0.67** | rule clause cut; `wait:` forms stay on the commandcode line |
| R3 | `memory-flow.md` "which is why repo work starts there and chat does not" | 0.60 | cut; file keeps the phase mechanics |
| R4 | `memory-harness-home.md` "pi is the one authorized case, because it cannot `@`-import" | 0.14 | cut; the exception now appears once, in canonical H2 |
| R5 | `memory-harness-home.md` form bullet echoing H2/H3 scope | 0.50 | rewritten as forms only, no rule clause |

Only R2 was above the cutoff, and it is the only one the old headline could see —
which is the real defect: a 0.65 gate hides rewording, so these were fixed by
reading, and the table above is the evidence, not a percentage drop.

---

## 4. FALSE CAPABILITY — pi's real tools

`~/.pi/agent/AGENTS.md` ships `read, bash, powershell, edit, write, grep, find, ls`
plus `codemode` and `tool_search` registered inactive (`docs/settings.md:46`);
`~/.pi/agent/settings.json` enables only `+codemode`, `+grep`, `+find`, `+ls`; no
extension registers `shell_output`, `agent` or `pubsub_fire`. The four lines that named them:

| line | before | after |
|---|---|---|
| 28 | `shell_output(wait)` / poll loop | "Do not wrap a wait call or any poll loop…" (harness-neutral) |
| 30 | "Peek with `shell_output`" | "Peek with `bash` (`tail -n 20 <log>`)" |
| 43 | "the native `agent` tool" | "pi has no in-process subagent tool: delegate with `intercom` … or `hc`" |
| 44 | "Detached work: `pubsub_fire`" | "Detached work: `hc run --bg`" |

The shared file was made harness-neutral for the same reason, since cmd and pi both
read it: "the harness's own subagent tool" / "the harness's detached spawn" / a
peek at "the job's log". Harness-specific names now live only in the harness file
or on a `commandcode:`-labelled line — `references/memory-never-block.md:6`,
`references/memory-subagents.md:6`, `cmd:24`.

Proof (grep over shared + pi, exit 1 = no match):

```
$ grep -n "shell_output\|pubsub_fire\|run_in_background\|monitor_command\|shell_command\|agent_output\|native \`agent\`" \
    ~/.agents/AGENTS.md ~/.pi/agent/AGENTS.md
$ echo $?
1
$ grep -rn "shell_output\|pubsub_fire\|run_in_background\|monitor_command\|shell_command\|agent_output" ~/.agents/references/
memory-never-block.md:6:- commandcode: shell `run_in_background=true` or `monitor_command`; peek `shell_output` …
memory-subagents.md:6:- `pubsub_fire` (commandcode): the `pubsub` mod spawns a headless run …
```

`fix4-rev5-verify.py` enforces both forms (no fake name in shared/pi; in a
reference only on a line carrying `commandcode`).

---

## 5. CONTRADICTION — one word

`AGENTS.md:18` defines "Long"; `:19` used to say "slow". Now the defined word and
the used word are the same, and the double-stated no-wait rule is one bullet:

```
- Long means builds, tests, watchers, servers, any headless agent run.
- Never block a shell command: start long work backgrounded or monitored, then return;
  never sit in a blocking call waiting on it.
```

`grep -n "slow" ~/.agents/AGENTS.md ~/.pi/agent/AGENTS.md` -> no match. The
reference index also says "before long work".

---

## 6. PORTABILITY — absolute paths, herdr rules shared

**Index paths.** `AGENTS.md:62-68` now names each file absolutely
(`~/.agents/references/memory-*.md`). cmd's loader expands only `@`-refs and leaves
backticked paths alone, so a relative path was dead in every project directory.

**`Test: every path in the three files resolves from a foreign cwd`**
(`python3 ~/.agents/loop/fix4-rev5-verify.py`, run in `/tmp/foreign-cwd`):

```
cwd: /tmp/foreign-cwd
PASS  path resolves: ~/.agents/references/memory-clarify.md  (in AGENTS.md)
   … one line per path, 28 paths (9 in AGENTS.md, 15 in pi, 4 in cmd), all PASS …
PASS  path resolves: /home/prm/.pi/agent/git/github.com/google/elephant-goldfish-model
PASS  path resolves: ~/.pi/agent/extensions/herdr-interactive-only.ts
PASS  path resolves: ~/.config/herdr/plugins/config/commandcode.integration/agent-detection/cmd.toml
PASS  no relative references/ path in AGENTS.md
PASS  index set: 7 entries, 7 files
PASS  index set equals references/*.md
PASS  @-import target resolves: ~/.agents/AGENTS.md
PASS  @-import target is the canonical file
PASS  @-import target carries the shared rules
failed checks: 0
```

The test resolves every `~/` and `/home/` path appearing in `AGENTS.md`,
`~/.pi/agent/AGENTS.md` and `~/.commandcode/AGENTS.md`, rejects any remaining
`references/memory-*` relative path, and checks cmd's `@` target is the canonical
file.

**Herdr rules moved to shared.** `AGENTS.md:56-59` now carries the three rules
(interactive only; task text must tell the agent to report back; check on it);
they were pi-only while `cmd:3-8` showed cmd also drives herdr. Only command names
stayed local:

- pi: `~/pi` `hc run --bg --name <name> pi`, `hc send`, `hc read`/`hc wait`, and
  the one-shot the extension blocks (`pi -p`).
- cmd: `cmd -p` named as its one-shot form (`cmd:8`).

---

## 7. Reproduce

```bash
python3 ~/.agents/loop/fix4-rev5-count.py          # 39 classified, coverage-enforced (range 37-39), exit 0
python3 ~/.agents/loop/fix4-rev5-verify.py         # 9 checks; red only on external drift, see fix4-rev6.md

python3 ~/.agents/loop/fix4-rev5-dup.py ~/.agents                              # after, without pi
python3 ~/.agents/loop/fix4-rev5-dup.py ~/.agents/loop/fix4-rev5-sets/before-live             # before, live 7
python3 ~/.agents/loop/fix4-rev5-dup.py ~/.agents/loop/fix4-rev5-sets/before --with-pi        # before, with pi
python3 ~/.agents/loop/fix4-rev5-dup.py ~/.agents/loop/fix4-rev5-sets/after  --with-pi        # after, with pi
python3 ~/.agents/loop/fix4-rev5-pairs.py          # the five restatements, before/after

# exact pi copy of shared lines
python3 - <<'EOF'
from pathlib import Path
a=[l for l in Path.home().joinpath(".agents/AGENTS.md").read_text().splitlines() if len(l)>20]
p=Path.home().joinpath(".pi/agent/AGENTS.md").read_text()
hit=[l for l in a if l in p]
print(len(hit), "of", len(a), "lines,", sum(len(l)+1 for l in hit), "bytes")
EOF
```

`fix4-rev5-sets/before/refs/memory-tool-economy.md` is a reconstruction from
`/tmp/fix4/orig-cmd.md:73-78`; the real file was deleted by rev4 and no copy
survives on disk or in git (`git log --all -- '*tool-economy*'` is empty). Any
before-number that depends on it is labelled as such above.

---

## 8. What I did not do, and the risk

- Did not test the symlink + `APPEND_SYSTEM.md` route that would cut the 3597 B pi
  copy; the ticket did not authorise a layout change and a wrong symlink silently
  disables every pi rule.
- Did not add per-file read triggers to pi's closing `Detail` paragraph. The claim
  that "no rule depends on reading them" is removed from that paragraph rather than
  defended, because R2 in `memory-code-lookup.md` is a rule behind a pointer.
- Did not re-measure `~/.agents/references/memory-code-lookup.md`'s deepwiki
  ordering rule (R2). It is a rule in a reference file; fixing that is FIX-2's
  duplication scope, not this ticket's six defects.
- Threshold evidence for the deleted file rests on a 304 B reconstruction of a
  414 B file. It clears the bar even under the worst case (26 %), but a reviewer
  should record the reconstruction rather than treat 42.1 % as measured on the
  original.
- The pi duplication share rose from 41.2 % to 51.2 % as a direct consequence of
  moving the herdr rules to shared. If the loop treats that as a regression, the
  fix is the symlink route, not removing the rules from shared.
