# FIX-6 — one home for the ambiguity threshold

Rev 1 worker. Files touched: `~/.agents/references/memory-clarify.md`,
`~/.agents/skills/flow/SKILL.md`. Nothing else. `AGENTS.md` left alone (w23 owns it).

## What the two files actually contained

The ticket assumes two definitions: one in `references/memory-clarify.md`, one in
`skills/flow/SKILL.md`. Reality at rev 1:

| File | Before |
| --- | --- |
| `skills/flow/SKILL.md:12` | one-line full statement of scale, threshold, budget, re-score |
| `references/memory-clarify.md` | **no definition at all** — three lines of rationale ("a wrong assumption costs a turn, one question costs a line"), the file `AGENTS.md` points at for the rule |
| `AGENTS.md` (both `~/.agents/` and `~/.pi/agent/`) | the eight-bullet full rule block — the real second copy, not mine to edit |

So the drift was flow vs `AGENTS.md`, and the reference that both name carried no rule to
drift from. That gap is now closed in the reference's direction.

## Differences, one by one, and the direction chosen

Authority = the fuller wording already in the `AGENTS.md` rule block (it is the version
every session loads). No third wording was written; the bullets are copied verbatim.

| # | Dimension | `flow/SKILL.md` said | `AGENTS.md` said | Direction |
| --- | --- | --- | --- | --- |
| D1 | 0-anchor | "0 is one reading" | "0 = one reading, complete requirements" | kept AGENTS: a 0 means the ask is fully stated, not merely single-reading |
| D2 | Scope | "the request" | "each prompt … short ones and follow-ups included" | kept AGENTS: a follow-up can carry new ambiguity |
| D3 | 10-anchor | "10 is no usable reading" | same | no difference |
| D4 | Threshold | "Above 3 … Act at 3 or lower" | "above 3" / "act at <= 3" | same set, not a disagreement; canonical form written `<= 3` once so the boundary is not re-derived |
| D5 | Questions | "up to four questions and re-score" | "at most 4 score-moving questions per round, re-score" | kept AGENTS: flow's wording admits a preference question and drops the per-round reset |
| D6 | What counts as a real question | absent | "only about ambiguities that change the work; never about preferences" | kept AGENTS — the substantive gap; without it the budget is spendable on taste |
| D7 | Announcement | absent | "state the score and competing readings in one line before asking" | kept AGENTS: an unstated score cannot be pushed back on |
| D8 | Refusal / silent assumption | absent | "never resolve ambiguity by silent assumption"; "told to skip: state score, open readings, assumption; proceed only on confirm" | kept AGENTS: this is the only path for "just start", and flow had none |

Retry rule: `flow` said "re-score" once with no bound; AGENTS said "per round". Kept the
bounded per-round loop (D5). Silent-assumption retry: none in either, correctly.

## Home chosen

`~/.agents/references/memory-clarify.md` is authoritative. It holds the only full definition;
`flow` keeps **one line** that names the file and adds only what is phase-specific: the gate
runs before Locate, and the escape hatch skips Plan, never the gate.

Reason it is the reference and not the skill: the rule must fire before any skill is loaded,
so it cannot be owned by one skill that most sessions never load; `AGENTS.md:62` already names
this file as the rule's detail, and `flow` is one consumer of it.

Reverse direction considered, with evidence, and rejected: `skills/flow/DESIGN.md:29` records
inlining the scale as a fix for an "uncomputable ambiguity <= 3", and the rule block lives in
the file every session loads — both argue for `AGENTS.md`. Rejected on two grounds: `AGENTS.md`
is w23's file this round (edit conflict), and its own pointer line already delegates the detail
here, so making the reference real is the direction the wiring was built for. The pointer now
names a file that actually contains the rule, which is what made the old note necessary.

## Verification

```
$ rg -c '0 = one reading' references/memory-clarify.md skills/flow/SKILL.md
references/memory-clarify.md:1          # flow absent = 0 ⇒ one full scale
$ rg -c '4 score-moving questions' references/memory-clarify.md skills/flow/SKILL.md
references/memory-clarify.md:1
$ rg -c -i 'ambiguity' skills/flow/SKILL.md
1                                        # flow keeps one line
$ bash ~/.agents/skills/flow/scripts/check.sh; echo $?
OK: flow rules and skill references valid
0
$ bash ~/dotfiles/jcode/skills-audit.sh | grep -c 'manifest drift'
0                                        # README rows == installed dirs, both directions
$ grep -c '^| flow ' ~/.agents/skills/README.md
1
```

`skills-audit.sh` exits 1 with `AUDIT-TOTAL: 2` — `overlay not applied: ponytail` and
`overlay not applied: tiger-style`. Both were present before this edit; neither is manifest
drift, so the README still passes.

`flow/SKILL.md`'s new line carries no backticks on purpose: `check.sh` treats every backticked
token in that file as a skill name and would fail on a path.

## Residuals, not fixed here

1. `~/.agents/AGENTS.md` and `~/.pi/agent/AGENTS.md` still carry the full eight-bullet rule,
   so the machine still holds three copies of the text; the reference is only authoritative
   once those shrink to the threshold plus the existing pointer line at `AGENTS.md:62`. w23's
   files, w23's call — the wording was copied verbatim so nothing is lost when they cut.
2. `skills/flow/DESIGN.md:29` still says the scale "is inline now". Stale after this change;
   it is a decision record and outside this ticket's files.
3. The reference is read on demand, so a session that only reads the `AGENTS.md` summary gets
   the threshold but not D5–D8. That is the cost of one home, and it is why the pointer must
   stay in the always-loaded file.
