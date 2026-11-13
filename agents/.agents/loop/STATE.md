# Loop state (resume here)

Goal, one line: one agent that does the right thing from the user's first sentence - no skill names, no setup, no remembering.

Stop rule (in LEDGER.md): keep looping while a round finds 3+ behaviour-changing defects with at least one
session-ruining; stop under that, or when fixes save <1% of per-request cost; hard stop after two quiet
rounds. Each round needs a new lens.

| round | lens | found | result |
|---|---|---|---|
| 1 | structure | 9 | all fixed + blind-reviewed |
| 2 | context cost + rule truth | 5 | all fixed, committed f0aeed3 |
| 3 | run it for real + skills as programs | 5 + 13 | IT3-1 done (9 fixes), IT3-2 running (6 fixes) |

Cost so far: 54,967 -> 50,216 B per request.

Open:
- IT3-2 in flight (w39-it3fix2): dead config claims, 5 phantom oc sites, wrong tool name, brag's missing
  skills, overlay false pass, 26 bare /name activations via post-sync transform.
- After it: blind review, commit, then round 4 with a lens nobody has used (candidates: agent behaviour
  under a vague prompt; failure recovery; what a brand-new machine gets).
- Human calls outstanding: 9 unused skills, 12 MB backup tarball, superwhisper/cua-driver outside sync.
- pi restart still pending to load the new guard and rules.

Gates that must stay green after every change: gen-pi-agents, flow check.sh, skills-audit, skills-cap-check,
guard suite 116/116.
