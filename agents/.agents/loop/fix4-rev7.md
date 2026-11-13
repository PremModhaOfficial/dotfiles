# FIX-4 rev7 / FIX-6 residual — the copies shrink, the authority does not

Two tickets, one edit set. FIX-6 made `~/.agents/references/memory-clarify.md` the
single full definition of the ambiguity gate; both `AGENTS.md` files still carried that
definition, which is what made the duplication check red.

| file | before | after | cap |
|---|---|---|---|
| `~/.agents/AGENTS.md` | 4083 B | **3965 B** (−118) | 4096, headroom **131 B** (13 required) |
| `~/.pi/agent/AGENTS.md` | 5630 B | **5506 B** (−124) | none |
| `~/.agents/references/memory-clarify.md` | 1371 B | **1371 B** (untouched) | — |

The reference was not shrunk: it is the authority, and the duplication drops because the
copies shrink. `git diff` on it is empty.

## 1. What the gate now says in an always-loaded file

`~/.agents/AGENTS.md` — the six imperatives plus one pointer, and nothing else:

```
## HARD RULE: clarify until ambiguity <= 3
- Score each prompt 0-10 before starting.
- Act at 3 or lower; if higher, do not start.
- Up to 4 questions that move the score, in one message, then re-score.
- Announce the score and what you weigh before asking.
- Questions must be about what alters the work, never about taste.
- Never fill a gap by quiet assumption.
- Full scale, refusal path and retry detail: `~/.agents/references/memory-clarify.md`.
```

Cut from the shared block: the two scale anchors (`0 = one reading …10 = no usable
reading`), the scope clause (`short ones and follow-ups included`), the `round`/`re-score`
retry detail, `competing readings`, `preferences`, and the whole refusal path
(`Told to skip: state score, open readings, assumption; proceed only on confirm`).
All of it still exists, verbatim, at `~/.agents/references/memory-clarify.md:7-20`.

Nothing was added to the reference to compensate — the file is byte-identical to the
FIX-6 version.

## 2. The pi file: which is which, in one line

**Kept inline in pi: the six imperatives (byte-identical to the shared block) and one
pi-only start-anyway line; cut from pi: the pointer line, the scale anchors and the
retry detail — those three are the ones that only pay off if something reads the
reference, and a pointer is inert in pi.**

Reasoning, since this is the one place the ticket's two instructions pull apart:
`pi` loads only `~/.pi/agent/AGENTS.md` (`~/.agents/AGENTS.md` is not in its context),
so every duty must be physically present there — that is the authorized H2 exception and
the file's own second paragraph says why. But "physically present" stops at duties:

- The scale anchors are not a duty. `score 0-10` still fires; the anchors only make the
  score reproducible, and they are exactly the "duplicated scale" the ticket names.
- The refusal path is the "refusal detail" the ticket names. Its *action* survives in
  pi in pi's own words — `If told to start anyway: state the score and the reading you
  guessed, then go.` — so a pi session told "just start" is not left without a rule,
  without re-copying the reference's sentence.
- The pointer line is inert in pi; the References section already names the file for
  the case where a session chooses to read it.

Pi's six imperatives are byte-identical to the shared six on purpose: that keeps them
claimable as the D12 copy (no new row per bullet) and guarantees the two files cannot
say different things while both are always loaded.

## 3. Verify

Duplication, `python3 ~/.agents/loop/fix4-rev5-dup.py ~/.agents` (refs vs `AGENTS.md`,
cutoff 0.65, byte-weighted):

```
BEFORE                                  AFTER
memory-clarify.md  1273  597  46.9%      memory-clarify.md  1273    0   0.0%
memory-code-lookup.md 700 102 14.6%      memory-code-lookup.md 700 102 14.6%
memory-flow.md      177    0   0.0%      memory-flow.md      177    0   0.0%
memory-harness-home.md 329 65 19.8%      memory-harness-home.md 329 65 19.8%
memory-never-block.md 533   0   0.0%      memory-never-block.md 533   0   0.0%
memory-subagents.md 584   65  11.1%      memory-subagents.md 584  13   2.2%
memory-web-access.md 381  26   6.8%      memory-web-access.md 381  26   6.8%
WITHOUT pi copy  855 B / 3977 B = 21.5%  WITHOUT pi copy  206 B / 3977 B = 5.2%
```

Every reference is under the 25% bar; the highest is `memory-harness-home.md` at 19.8%,
which this ticket did not touch. `memory-clarify.md` goes 46.9% → **0.0%**, i.e. the
reference now restates nothing that an always-loaded file says.

`--with-pi` prints `pi-AGENTS.md 5079 B 3727 B 73.4%` and a `43.4%` denominator. That is
the authorized inline, not a defect: pi is measured as a copy of the shared file by
construction (H2 exception), and it is the denominator row the rev5 metric added, never
a bar. The bar applies to the reference rows.

Coverage, `python3 ~/.agents/loop/fix4-rev5-count.py`, exit **0**:

```
~/.agents/AGENTS.md          bullets= 47 unclaimed=0
~/.pi/agent/AGENTS.md        bullets= 51 unclaimed=0
~/.commandcode/AGENTS.md     bullets= 10 unclaimed=0
by class: {'obligation': 39, 'definition': 2, 'index': 9, 'syntax': 4, 'copy': 6, 'descriptive': 10}
shared content bullets: 39 = 38 obligations + 1 definitions
OBLIGATIONS: 39
NOT COUNTED: definitions=2 syntax=4 index=9 descriptive=10 d12-copies=6
failed proofs / unclaimed bullets: 0
```

39 classified, unclaimed 0, unchanged from rev6. What moved inside the script and why:

- `C1`-`C6` keep their ids and their class; only the proof substring follows the new
  wording. The six ambiguity bullets are still six obligations.
- `D1` (`Scale: 0 = one reading`) is **gone**, not re-classed: the scale line no longer
  exists in any always-loaded file, so there is no definition row left to claim.
  `definitions` 3 → 2.
- `C7p` (`copy`, pi) claims pi's start-anyway line, which is no longer byte-identical to
  anything shared. `d12-copies` 5 → 6.
- `I1b` (`index`) claims the new inline pointer bullet. `index` 8 → 9.

This is the one file outside the ticket's three that I edited, and it had to be edited:
its rows are proof substrings of bullets, so a re-wording that is not matched there exits
1 with `unclaimed=6`. The rows track the bullets; no row was invented to hold the count
at 39, and no obligation was folded into another to hide a drop.

One full definition, greps (count per file, blank = 0):

```
$ rg -c '0 = one reading'                 ~/.agents/AGENTS.md ~/.pi/agent/AGENTS.md ~/.agents/references/memory-clarify.md
.agents/references/memory-clarify.md:1
$ rg -c 'Told to skip'                    ~/.agents/AGENTS.md ~/.pi/agent/AGENTS.md ~/.agents/references/memory-clarify.md
.agents/references/memory-clarify.md:1
$ rg -c 'score-moving questions'          ~/.agents/AGENTS.md ~/.pi/agent/AGENTS.md ~/.agents/references/memory-clarify.md
.agents/references/memory-clarify.md:1
$ rg -c 'Up to 4 questions that move the score' ~/.agents/AGENTS.md ~/.pi/agent/AGENTS.md
.agents/AGENTS.md:1
.pi/agent/AGENTS.md:1
```

A read of the pi file alone (`sed -n 7,14p ~/.pi/agent/AGENTS.md`), which is all a pi
session gets:

```
## HARD RULE: clarify until ambiguity <= 3
- Score each prompt 0-10 before starting.
- Act at 3 or lower; if higher, do not start.
- Up to 4 questions that move the score, in one message, then re-score.
- Announce the score and what you weigh before asking.
- Questions must be about what alters the work, never about taste.
- Never fill a gap by quiet assumption.
- If told to start anyway: state the score and the reading you guessed, then go.
```

Present, self-contained, and it names a threshold, a budget, a place to ask and the
start-anyway path without any other file.

`bash ~/.agents/skills/flow/scripts/check.sh` → `OK: flow rules and skill references
valid`, exit **0**.

## Residuals, not fixed here

1. A cmd session that does not open the reference loses the scale anchors and the
   refusal path. That is the FIX-6 trade (one home, read on demand) and it is now the
   only cost: the previous state lost the same detail *and* kept three drifting copies.
2. `skills/flow/DESIGN.md:29` still says the scale "is inline now" — stale since FIX-6,
   outside this ticket's files.
3. The count script's class labels remain hand-written; 39 is coverage-enforced, not
   proven, honest range 37-39 as before.
4. Duplicate-check side effect: `memory-subagents.md` also fell (11.1% → 2.2%) because
   the shared file stopped containing `per`/`round`/`most`/`message`-adjacent tokens.
   That is the metric being honest about a smaller union, not an edit to that file.
