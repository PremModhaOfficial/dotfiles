# `flow` — decision record

Not a specification. SKILL.md is the instruction; this file records what was rejected and
why, so a later session does not rebuild the same mistakes. Written after two fresh-context
reviews (egm-zoom-out, egm-implementation-readiness) returned blockers against the first draft.

## What this is

One skill that gives the order of operations for real repo work and points each phase at an
already-installed skill's own stop condition. It does not restate those skills, does not
look up skills (`ds-help` does that), and does not carry a second copy of their rules.

## Rejected, with the reason

| Rejected | Why |
| --- | --- |
| A custom lesson store (lessons.md, promotion thresholds, caps, a validator) | `ds-lessons` already does it, and prefers a structural fix over prose. Two prose stores, one of them empty, invite rot. One dated rules file, written only through `ds-lessons`, is the smallest thing that learns. |
| Seven phases (frame, locate, plan, build, prove, review, ship, learn) | Six of them named an existing skill's trigger. Vocabulary to memorise, which is the problem the skill exists to solve. Five rows, exits delegated. |
| A second task-to-skill lookup table | `ds-help` owns lookup. A phase table that repeated it would drift from it, and two routers compete with the skills they route to. |
| Reading memory on every task | Empty memory costs tokens for nothing. Read it only when it has rows; exempt the escape hatch. |
| Memory outside the skills tree, justified by update-all.sh | The justification was unproven and the skill file sat in the "regenerated" tree anyway. One file beside the skill, assertions in check.sh. |
| Wiring by description alone | `~/.agents/AGENTS.md` is not loaded by pi. The pointer line lives in the file pi loads. A design that depends on a file nothing reads is an unfinished design. |
| A Command Code adapter | No second harness is in use. Build it when one is. |

## What the two reviews changed

Both agreed on three defects, now fixed: no reachable fresh context (pi has no subagent tool,
so the reviewer is a spawned session and the design says what to do with no herdr), an
uncomputable "ambiguity <= 3" (the scale is inline now), and a wiring line in a file that is
never loaded. Also fixed: a fail-open checker, a hardcoded EGM path, an unmeasurable escape
hatch, unvalidated rule rows, `herdr` offered without its precondition, and a Ship phase that
would have filed and watched the same PR twice.

## What is still weak

- The self-check runs when someone remembers to run it. No hook enforces it.
- A rule can be right for this harness and wrong after an upgrade; the ten-task expiry is a
  speed limit, not detection.
- `rules.md` is untracked in the dotfiles repo. A fresh clone starts with no learned rules.
- Reaching the right build skill still depends on the model reading a table correctly. The
  only test of that is a fresh session; run it after any edit to SKILL.md.

## Harness is a variable, not a constant

The first draft hardcoded herdr as the way to get a fresh reviewer, and assumed pi's toolset in
phases that T3 Code owns. Toolset differs by host: T3 Code brings `delegate_task` and
`watch_pull_request`, herdr brings panes and background spawns, plain Pi brings neither. So the
skill probes once (`$HERDR_ENV`, and which agent CLIs are on PATH) and picks the mechanism it
finds, and the report must name the mechanism used. A missing tool is stated, never simulated.

## Acceptance test

Start a fresh session in a repo and say, in two sentences, that a `TypeError` is thrown in
one named file. Pass: the session states it will locate the callers first, then names
`surgical-patch` (or `ds-tdd` if it proposes a failing test first) and says the fix is proven
when the reproduction stops. Fail: it starts editing without locating, or names no check.

**Result 2026-11-13: pass.** A fresh session started from `flow`, put Locate before any edit,
named a Build skill and its proof, delegated the stop condition, and declined `ds-ship`
because the ask was a fix, not a merge. It also found a gap the design had: for a bug whose
cause is unknown it reached for `diagnosing-bugs` first, which the Build row did not offer.
That skill is in the row now, and the lesson is in `rules.md`.
