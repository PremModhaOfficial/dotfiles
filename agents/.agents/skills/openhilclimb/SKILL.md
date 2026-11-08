---
name: openhilclimb
description: "Eval-driven hill climbing for AI agents. Use when the user wants to iteratively improve an agent or prompt or harness performance on a task by measuring against evals, proposing one change per round, and keeping only improvements that raise the held-out test score. Triggers include hill climb, hillclimb, optimize agent, improve eval score."
---

# OpenHillClimb

You have access to the `openhilclimb` Python harness in this repo. Use it to run the hill-climbing loop instead of improvising.

## When to use

- User wants to improve an agent/prompt/harness on a measurable task.
- There is (or can be built) an eval set with expected outputs.
- User mentions "hill climbing", "hillclimb", "optimize", "improve success rate".

## Workflow you should drive

1. **Define the task + success metric.** Ask what "better" means (accuracy, pass rate, cost, latency). Pin down the agent entry point and how it's invoked.

2. **Build the eval.** Create `cases.jsonl` with `{id, input, expected, grader}` lines. Graders: `exact_match`, `contains`, `regex`, `numeric_tolerance`. Aim for 15-100 cases mixing easy/hard/edge. Split 70/30 train/test (use `openhilclimb.split.split_cases`).

3. **Write the agent function.** Signature: `def agent(config, case_input) -> (output, trace, usage)` where usage has `cost_usd` and `latency_ms`. The config dict controls behavior (prompt, model, flags) so changes can be applied.

4. **Baseline.** Run `HillClimber.baseline()` to record starting scores on train + test.

5. **Climb.** `HillClimber.climb(N)` runs N rounds. Each round: analyze train failures → propose one change → apply → re-run train + test → **keep only if train improves beyond noise AND held-out test does not regress**, else revert. One change per round for clean attribution.

6. **Finalize.** `final_test_eval()` + `write_report()` → `.hillclimb/<flow>/report.md`.

## Hard rules (do not violate)

- **One change per round.** Never bundle multiple edits — attribution breaks.
- **Keep condition is both train AND test.** Train-only gain = overfitting → revert.
- **Analyzer only sees train data.** Never feed test cases/transcripts into the analyzer or prompt.
- **Held-out test is never used for decisions** beyond the keep/revert gate; don't peek at its failures to craft fixes.
- **Read failures, not just scores.** Cluster failure modes before proposing.
- **Stop when stalled** (2 rounds with < noise-threshold gain).
- **Guard against gameable scorers** — spot-check outputs by hand.

## Key files in this repo

- `openhilclimb/eval.py` — `EvalCase`, graders, `EvalRunner`
- `openhilclimb/split.py` — `split_cases`, `save_split`/`load_split`
- `openhilclimb/state.py` — `State`, `StateManager` (`.hillclimb/<flow>/`)
- `openhilclimb/analyzer.py` — `analyze_failures`, `propose_change`, `ChangeProposal`
- `openhilclimb/loop.py` — `HillClimber` (`baseline`, `climb`, `final_test_eval`)
- `openhilclimb/report.py` — `generate_report`, `write_report`
- `examples/coding_task/` — runnable end-to-end demo

## Quick code template

```python
from openhilclimb.state import State, StateManager
from openhilclimb.loop import HillClimber

sm = StateManager(root=".hillclimb", flow="myflow")
sm.init(State(flow="myflow", train_ids=train_ids, test_ids=test_ids, noise_floor=0.0))

hc = HillClimber(sm, agent_fn, cases, config, noise_floor=0.0, metric="pass_rate")
hc.baseline()
hc.climb(5)
hc.final_test_eval()
from openhilclimb.report import write_report
write_report(sm, sm.load())
```

## Metrics to track

Accuracy/pass rate (train + held-out), latency, cost (tokens/$), plus domain-specific (hallucination rate, static-analysis issues, security vulns). Set thresholds relative to baseline (e.g. ≥2% held-out gain, ≥20% cost cut).

## Pitfalls to watch

- Overfitting to train set (always validate on held-out)
- Noise mistaken for progress (use reps, noise floor)
- Gameable scorer (spot-check by hand)
- Local maxima (occasionally try a big change)
- Eval contamination (don't leak test answers into prompts)

See `RESEARCH_HILL_CLIMBING.md` and `HILL_CLIMBING_RESEARCH.md` for full background.