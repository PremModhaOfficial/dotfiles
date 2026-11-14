# Retro: 7-thread `/skill:flow` fan-out on aur-prefetch, 2026-11-14

Retro of one orchestrator session (this one) that dispatched eight worker threads
in `/home/prm/project/aur-prefetch`, each briefed to run `/skill:flow` and stop
at `ds-ready` (PR opened, never merged). Written to be acted on, not admired:
every claim below cites a thread id and message position, a file and line, or is
marked **unconfirmed**.

## Method, and what this retro cannot see

- Read all eight transcripts with `t3_thread_read` (messages view, all pages).
- Read the shipped state with `gh pr list --state all`, `gh issue list`, and
  `git -C /home/prm/project/aur-prefetch status`.
- **Limit:** the transcript exposes prose only. Tool calls, `delegate_task`
  prompts, checkpoints and system notices are not readable
  (`view:"activity"` returned 24 `system_notice` + 1 `checkpoint` and no tool
  items). So "how many tool calls Locate took" is **unconfirmed** everywhere
  below; I only claim what an agent said in prose.
- Timestamps are UTC. Local clock is IST (+05:30).

## What actually shipped

| Thread | Issue(s) | PR | State |
|---|---|---|---|
| `mcp:e2f00197` | #40, #41 | 55 | open, head `d4f1087` |
| `mcp:d54f11bd` | #42, #46 | 53 | open, head `189fff5` |
| `mcp:79f2efa7` | #43, #44 | 54 | open, head `45079cc` |
| `mcp:3bfe80d0` | #45 | **57** | open, head on `fix/tui-stuck-flag` |
| `mcp:b045e5a5` | #27 | **56** | open, head `4ea1a2e` |
| `mcp:0b8146c9` | #33 | 58 | open, head `6f395a8` |
| `mcp:fe207498` | #28 | 52 | open, head `8afa7ea` |
| `mcp:f190cc67` | flaky sim 34 | **59** | open, head `cddb321` |

8 threads → 8 PRs, 0 merged. The operator's own list credited only five of the
eight (52–55, 58) and left #45 and #27 without a PR; PRs **56, 57 and 59 exist**
(`gh pr list`), so the mental ledger was stale. `mcp:f190cc67` was reported as
"still running": it was created 09:47:41, completed its only run at 10:37:11 and
opened PR 59 at 10:30:50. **That claim is refuted.**

## The six operator claims, judged

| # | Claim | Verdict | Evidence |
|---|---|---|---|
| 1 | Interrupted all 7 threads for a cheap API window; cost = one lost cycle | **Partly wrong** | 6 of 7 interrupted, not 7: six threads created 08:28:18, all interrupted at 08:30:36–08:30:42, resumed 08:35:07–08:35:08. `mcp:0b8146c9` was created 08:40:54, i.e. after the resume, and was never interrupted. 2026-11-14 **is a Saturday** (`date -d`), so the 08:28 UTC dispatch was already off-peak. |
| 2 | First briefs named file:line and the fix; one thread's Locate just confirmed it | **Confirmed, with a caveat** | `mcp:0b8146c9` p=0: "Find every use of `min_free_bytes` ... with file:line" and "Assume the answer is one shared source of truth". Its own parent correction at p=6: "Correction to my brief: I pre-decided the answer ... Treat that as a hypothesis, not a spec". Parent's p=99 summary: "Locate report accepted: anchors verified, single-source is reachable, and your space_floor decision is right". Caveat: the thread's final decision was *not* the brief's — it shipped two calls, not a rename ("The decision the code forced", p=256). So the waste was anchor re-verification, not a wrong fix. |
| 3 | A thread edited `src/commands/doctor.rs` in the project root because the brief opened with the root path; **it detected the stray diff itself** | **Cause confirmed, self-detection refuted** | Cause: `mcp:0b8146c9` p=0 is the only brief that opens "You own GitHub issue #33 in `/home/prm/project/aur-prefetch`". Detection order is against the claim: the *parent* flagged it at p=99 ("the project root ... now has an uncommitted 24+/7- edit to `src/commands/doctor.rs`, mtime 2026-11-14T14:15"), and only then did the thread answer at p=108 "Confirmed: my edits landed in the project root, not the worktree." Nothing in the thread mentions it before p=99. The stray edit is gone from the root now (`git status --porcelain -- src/commands/doctor.rs` empty). |
| 4 | Two threads ran sim concurrently on the shared `aur-prefetch-sim:local` tag; a third hit a stale `COPY` layer | **Confirmed, and it is a repo defect** | Shared tag: `mcp:e2f00197` p=247 "the full-run failures came from the *shared* `aur-prefetch-sim:local` tag (another thread builds the same tag)". Stale layer: `mcp:0b8146c9` p=214 "The image was stale — `COPY --from=builder` reused an old binary". Third casualty: `mcp:b045e5a5` p=485 "my final sim used the **shared** `aur-prefetch-sim:local` tag. Re-running with my own tag and `--no-cache`". Root cause is in the repo, not the brief: `sim/run.sh:30` is `IMAGE=${SIM_IMAGE:-aur-prefetch-sim:local}` and `sim/README.md` documents `--no-cache` (:22, :27) but **never mentions `SIM_IMAGE`**. |
| 5 | Two threads on adjacent issues in `src/report.rs`; one deleted types the other was wiring; ruling: types stay | **Confirmed** | `mcp:79f2efa7` p=189 "Issue 44: delete the sections nothing collects and the types that only they used." Parent ruling p=241: "Ruling: keep `Drift` and `PartialUpgrade`. Restore those two types and their `Snapshot` fields". Thread complied p=245, and paid a wasted suite: p=264 "Re-running the full suite on the committed tree, since `Drift` came back after that run started." Note the delivery was faithful — issue #44's text says those types are never collected; the *issue split* was the defect. |
| 6 | Fresh reviewer returned NOT PASS on 12 findings across 5 PRs; 10 fixed, 2 declined | **Counts confirmed, split off by one** | Review rounds exist for exactly 5 PRs: 55 (p=378, 1), 53 (p=283, 2), 54 (p=355, 4), 58 (p=318, 3), 52 (p=166, 2) = 12. All 12 were fixed except one: PR 54's "drift field being filled only by #41 is already disclosed in the body" was accepted as-is (p=355), and the other "disclosure-backed" finding was still fixed (p=385 item 3). So 11 addressed / 1 accepted-on-disclosure, not 10/2. PRs **56, 57, 59 got no second review round at all** — 5 of 8 covered. |

## What the delegation contract got right

1. **The stop line held 8/8.** Every brief said "Ship phase is `ds-ready` ...
   Do not merge" (`mcp:e2f00197` p=0) and every thread obeyed, including through
   three review rounds (`p=387` "PR #55 unchanged"). 8 PRs open, 0 merged.
2. **Issue-only scope produced the fix instead of a transcription.** Six of
   seven briefs named only issue ids. `mcp:3bfe80d0` p=17 noticed issue #45 has
   no "Smallest fix" heading and named the smallest fix itself; `mcp:79f2efa7`
   p=108 picked its own first target. None invented scope.
3. **"Report what you left out" was honoured, unasked.** `mcp:e2f00197` p=387
   disclosed the one thing it skipped ("I did not sweep the other tables for
   stale badge lists"); `mcp:0b8146c9` p=406 disclosed that its stderr silence
   was structural, not fd-2-asserted.
4. **Threads surfaced environment faults instead of absorbing them.**
   `mcp:e2f00197` p=247 named the shared docker tag rather than re-running until
   green.
5. **The collision notice worked as designed.** `mcp:e2f00197` p=208 answered
   with exact hunk ranges instead of a promise, and `mcp:79f2efa7` restored on
   instruction rather than re-litigating.
6. **The two-layer review earns its cost.** The thread-local delegate review plus
   the parent's PR review caught 12 real defects in 5 PRs, most of them of one
   kind an implementer cannot see: a PR body claiming more than the diff does.

## What it got wrong

**W1 — Interrupting on a stale price memory.** The 16:30–00:30 UTC window was
DeepSeek's off-peak discount, announced 2025-08-21 as ending 2025-09-06 00:00
Beijing time (2025-09-05 16:00 UTC), i.e. 14 months before this run — the
operator's own account is correct. Whether the routed provider here
(`commandcode-goat/deepseek/deepseek-v4.1-flash`) ever passed that discount
through is **unconfirmed**. Cost, measured: 6 threads × 2 min 10 s = ~13
thread-minutes, plus six resume turns. It was cheap only because nothing had
committed yet (all six reported an empty worktree at resume: `mcp:3bfe80d0` p=47
"Nothing was done yet", `mcp:79f2efa7` p=78 "Nothing landed in the worktree",
`mcp:d54f11bd` p=75 "Worktree is clean"), and the threads' context survived, so
Locate was not re-run. A later interrupt would have cost real work.

**W2 — The pre-decided brief, and a rule with nothing behind it.** The rule that
came out of it is `agents/.agents/skills/flow/rules.md` line 5 ("never file:line,
a diagnosis or the answer"), committed as `eb2d062` at 08:41:32 UTC — 38 seconds
*after* `mcp:0b8146c9` was created, so it did not cover the brief that caused it.
The next bespoke brief, `mcp:f190cc67` (created 09:47:41), still names the test
path and the suspected cause ("the first poll can catch the `.part` mid-copy").
Defensible for a debugging task, but it shows the rule is prose with no
enforcement: it was broken again 66 minutes after it landed.

**W3 — A path in the brief is a path the agent will use.** Event 3 is fully
explained by one line: the brief opened with the project root, and the edit tool
takes absolute paths happily. Isolation was never a model failure; it was an
instruction.

**W4 — Concurrency is not modelled in the harness.** `sim/run.sh:30` has a
single global default tag. Three threads lost a full sim run to it and one lost a
run to a stale `COPY` layer. The workaround existed (`SIM_IMAGE`) but was
undocumented, so each thread rediscovered it or was told, one at a time, after
the burn.

**W5 — Dispatch by issue, not by file.** #44 and #41 both own `src/report.rs`
states; the threads were correct to obey their issues and wrong to each other.
The ruling, not the delivery, saved it — and cost one full suite re-run
(`mcp:79f2efa7` p=264).

**W6 — Review coverage was partial and the finding class repeated.** 5 of 8 PRs
reviewed. Three of the twelve findings are one class: a claim in the PR body or a
doc that the diff does not support — PR 54 "so the ledger says why" (p=355 #2),
PR 53 "one place that turns a count into the verdict" (p=283 #1) and "the updated
sim 32/36" (p=283 #2), PR 55's missing `partial` in the badge row (p=378). A
class that recurs three times in one session is a check, not a note.

**W7 — Duplicate steers (not in the operator's list).** The identical "Resource
cap" message was delivered **twice to six of six live threads**:
`e2f00197` p=203/204, `d54f11bd` p=169/174, `79f2efa7` p=206/216, `3bfe80d0`
p=91/92, `b045e5a5` p=225/235, `0b8146c9` p=61/66. Every one cost a turn and one
landed mid-run.

**W8 — The shipped list came from memory.** Three PRs (56, 57, 59) were
invisible in the operator's recap and one thread was called still-running after
it had finished. One `gh pr list` would have been authoritative.

## Changes that would have prevented each failure

| Failure | Level (ds-lessons §3) | Concrete change | Where |
|---|---|---|---|
| W1 stale price window | rule (judgment only) | never interrupt on a remembered window; check the provider's *current* window against today's date and its timezone first, or cut thread count instead of run state | `flow/rules.md` (proposed R3) |
| W3 root-path edit | structure | brief template omits every path: cwd is already the worktree; one line "your cwd is your worktree, never edit `/home/prm/project/aur-prefetch`" | `flow/SKILL.md` brief template |
| W4 shared docker tag | **types/structure — highest value** | derive the tag from the worktree so concurrency is safe with no brief line: `IMAGE=${SIM_IMAGE:-aur-prefetch-sim:$(basename "$PWD")}` in `sim/run.sh:30`, and document `SIM_IMAGE` next to `--no-cache` in `sim/README.md:22-27` | aur-prefetch repo |
| W5 file collision | structure | dispatch by file when two issues name the same file: one thread, or a stated order, and the brief names the file as owned | `flow/SKILL.md` dispatch step |
| W6 body claims + review gaps | check | a PR body claim that names a symbol, file or count must cite the line that makes it true, and every PR gets one review round before its thread idles — a `Review` check that did not run is red, not skipped | repo `.pr_agent.toml` / review policy |
| W7 duplicate steers | structure | send once, then read the thread to confirm receipt; do not re-send a steer that has a delivered message id | orchestrator habit, no check |
| W8 memory vs ledger | check | derive the shipped list with `gh pr list --state all` and thread status, never from recap | orchestrator habit |

W2 is deliberately absent: the rule already exists (`rules.md` line 5). Adding
prose for it would repeat the symptom. Its fix is the brief template in W3's row.

## Proposed rules for `flow/rules.md` (not applied — ds-lessons writes that file)

Current file has 3 rules; the cap is 15, so three lines fit.

```
- 2026-11-14 | a worktree brief carries no path at all: cwd is already the worktree, and the one brief that named the project root wrote 24 lines into it
- 2026-11-14 | before dispatching, name the file each thread owns; two issues in one file go to one thread or in a stated order, or one deletes what the other is wiring
- 2026-11-14 | never interrupt a run for a price window read from an old article; check the window against today's date and timezone, or cut threads instead of state
```

## Unconfirmed

- Whether the routed provider ever applied DeepSeek's off-peak discount.
- How many tool calls each Locate took (tool items are not in the transcript).
- Whether the deleted schedule and the "resume immediately" were one action;
  only the 4.5-minute gap between interrupt and resume is observable.
- Whether PR 54 and PR 55 actually conflict in `src/report.rs` at merge time —
  the parent predicted they would (`mcp:e2f00197` p=378 names a `check.rs` import
  conflict with 53) but nothing was merged.
- Whether `SIM_IMAGE` reached every thread: `mcp:f190cc67`'s brief carries it
  unprompted (p=0), `mcp:b045e5a5` was told at p=482 *after* its final sim had
  already passed on the shared tag.
