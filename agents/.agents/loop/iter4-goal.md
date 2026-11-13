# iter4 — goal lens: one agent, one vague sentence, no skill named

Method: three fresh `pi` sessions via `hc run --bg --name`, each in its own clean
`git clone` under `/tmp/r4`, one message from a user, nothing else (no skill, no hint,
no "I can help"). 20-minute window. Transcripts read from
`~/.pi/agent/sessions/--tmp-r4-*/`, not from the previous rounds.

| run | repo | message |
|---|---|---|
| w47-slow | aur-prefetch (Rust, own AGENTS.md, NEXT.md tracker) | `this thing is slow, fix it` |
| w48-deploy | ryoku-arch (2636 commits, .github, deploy.sh) | `the deploy broke, find out why` |
| w49-export | font-feature-explorer (single-file HTML) | `add a way to export the table` |

All three: idle from ~14:09Z, 1 minute of a 20-minute budget used, **0 files edited,
0 commands that measure anything, 0 tests**. Each ended its turn with a question and
waited. Nothing in the setup told them a human would ever answer.

## Per run

### w47-slow — start found, asked before measuring
- Right starting point: **yes**, unaided. `NEXT.md` T4 "2,000-package performance
  pass" is the repo's own perf item, and it cited it.
- Question timing: **wrong order**. Four zero-cost probes existed (own bench/sim,
  `./ci.sh`, time one CLI command) and none was run. Ambiguity scored 8/10 at 14:09:36
  without one timing taken.
- Own proof: **half**. Acceptance criteria appeared, but only as question 4
  ("which numbers count as acceptance"), not as a claim it would test.
- Real work: none. Drift point: the final message at 14:09:36, which is the gate at
  `~/.pi/agent/AGENTS.md:9` ("if higher, do not start") applied to a prompt whose
  ambiguity a 30-second run would have collapsed.

### w48-deploy — best recon, then stopped one step short
- Right starting point: **yes**. Clean tree, HEAD `85aa550b`, `deploy.sh` syntax ok,
  recent shell commits don't touch it, `ryoku` not on PATH, host is not Ryoku.
- Question timing: **one step early**. Its own `find` listed the only two deploy logs
  (`./.scratch/baseline-hub.log`, `./.scratch/baseline-compile.log`); it opened
  neither, then asserted "no failed-deploy log in `.scratch/`" from the filenames.
- Own proof: **no**. Named what it checked, not what would settle it.
- Real work: none. Drift point: after the `.scratch` listing it called
  `intercom list-cwd` then `hc read t6r --lines 25` — i.e. it went looking for a
  session to ask and then read **itself** — instead of opening the two log files it had
  just found. A competent person steers exactly there: "read those logs".

### w49-export — right answer worked out, not executed
- Right starting point: **yes**. No `<table>` in `index.html`; it found `#features`,
  `#showcase`, `#compareGrid`, and the existing export affordance (`Copy config`
  button, `index.html:712`), which is the reusable pattern.
- Question timing: **wrong**. It reached a concrete default that is one button in one
  file ("Export CSV … downloads `features.csv`… if you just say go") and still asked,
  scoring 6/10.
- Own proof: **no** — no statement of how it would check the CSV is right.
- Real work: none. Drift point: 14:09:42, the score line itself; nothing in the rule
  lets a reversible one-file default proceed.

## Findings, ranked by recurrence

1. **An unattended session has no path past the gate.** `memory-clarify.md:8-9`
   ("above 3, do not start the task") plus `AGENTS.md:9` has exactly one escape and it
   requires being *told* (`memory-clarify.md:16`, `AGENTS.md:13`). Nobody is there to
   tell. Recurrence: **3/3**, and it will be 3/3 of every `hc`-delegated or
   background run, which is most of them.

2. **The cost argument is wrong for that case and the rule still uses it.**
   `memory-clarify.md:29` — "one question costs one line". With no human, one question
   costs the entire job; here it cost 19 of 20 minutes each. This single sentence is
   why the gate feels safe. Recurrence: **3/3** (all three cited the trade implicitly,
   none noticed that a reply was impossible).

3. **Evidence in hand does not re-score.** All three did recon first and still scored
   from the prompt: w47 had the exact perf item (8/10), w48 had narrowed it to "not in
   the tree, need the machine" (7/10), w49 had identified the reuse target (6/10).
   Scores were set at the top and never revised down by what was found. Recurrence:
   **3/3**.

4. **No cheap-and-reversible branch.** w49's default is one button, one file, trivially
   revertible; w48's is an unknown machine and an unknown deploy mode. The rule prices
   them identically. Consequence: 3/3 asked about work a competent dev would have done
   and shown. Recurrence: **3/3** in form, **2/3** in the strong sense (w47's is the
   arguable one: wrong target choice is genuinely expensive).

5. **A stated default is inert unless the user says "go".** w49 wrote the whole
   reading out and stopped anyway, because the only override in
   `memory-clarify.md:18-20` is triggered by being told to start. A default already
   named on the record satisfies the rule's stated purpose ("stop silent guessing") and
   still does not satisfy its wording. Recurrence: **3/3** will state the default; 0/3
   will act on it.

6. **No proof standard at entry.** 0/3 named the check that would prove their fix. The
   proof vocabulary lives in `ds-verify-loop` / `ds-mode`, downstream of a skill
   choice a vague sentence never triggers. w47 got nearest only because its own
   question template happened to ask for acceptance. Recurrence: **3/3**, and it is
   invisible until a diff exists.

7. **The skill layer is unreachable from a symptom.** `flow` claims "real repo work
   starts here" and 0/3 invoked it, or any skill. Nothing maps "slow / broke / export"
   to an entry point, so recon is improvised (well, in w48's case). Not fatal here;
   fatal for proof, phases and stop conditions. Recurrence: **3/3**.

8. **"Checked" lists contain checks that were not run.** w48's summary said "no
   failed-deploy log in `.scratch/`" while its own discovery had printed two `.log`
   paths it never opened, then it spent two calls looking for a peer to ask. The
   question then inherits the gap, so the human answers a question about the wrong
   evidence. Recurrence: **1/3 observed**, but it is the failure mode the clarify gate
   is supposed to prevent, so it recurs wherever the gate replaces a probe.

## The defect, in one line

The gate is evaluated on the prompt instead of on the next cheapest action, and its
only exit requires a human. Every vague ask on this machine therefore ends as a
question in an empty room — the recursion risk is not that agents guess, it is that
they stop.
