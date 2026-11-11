# Hill Climbing for AI Agents: Comprehensive Research

*Last Updated: 2026-10-30*

## Table of Contents

1. [What is Hill Climbing for AI Agents?](#1-what-is-hill-climbing-for-ai-agents)
2. [Anthropic's Hillclimb Implementation](#2-anthropics-hillclimb-implementation)
3. [How build-eval and hillclimb Work](#3-how-build-eval-and-hillclimb-work)
4. [Related Concepts & Resources](#4-related-concepts--resources)
5. [Tools & Patterns](#5-tools--patterns)
6. [Swarm Orchestration Connection](#6-swarm-orchestration-connection)
7. [Practical Implementation Advice](#7-practical-implementation-advice)
8. [References](#8-references)

## 1. What is Hill Climbing for AI Agents?

Hill climbing for AI agents is the iterative, measurement-driven process of improving an agent's performance on a specific task by systematically testing changes against evaluations and keeping improvements that increase success rate.

### Definition

- **Core concept**: Inspired by the hill climbing optimization algorithm - make incremental changes to an agent's configuration (prompts, tools, scaffolding/harness) and evaluate if each change improves performance on a target metric.
- **Goal**: Optimize agent performance through systematic iteration with empirical feedback, rather than relying solely on intuition or one-shot prompt engineering.
- **Key principle**: Treat agent improvement as an optimization problem where you need measurable feedback to know if you're going "up the hill" towards better performance.

### Workflow

1. **Define the task clearly** - Specific, well-scoped task with unambiguous success criteria
2. **Create evaluation set** - Build evals/test cases that accurately measure success/failure
3. **Establish baseline** - Run current agent configuration against evals to get baseline score
4. **Analyze failures** - Review traces, tool calls, and failure modes to understand what went wrong
5. **Make targeted changes** - Improve prompt, add tools, adjust scaffolding/harness based on failure analysis
6. **Measure impact** - Re-run evals to quantify if changes improve performance
7. **Iterate** - Repeat until diminishing returns, hitting a target, or budget exhaustion
8. **Validate & ship** - Test on held-out data and deploy improved agent

### Examples

- **Coding agents**: Iteratively improving a coding agent's ability to fix bugs or implement features on SWE-bench style tasks
- **Research agents**: Optimizing tool usage patterns based on eval failures (e.g., when to search, how to synthesize)
- **Tool use agents**: Improving reliability of tool calling and parameter formatting
- **Format adherence**: Tuning agents to follow specific output schemas more consistently

## 2. Anthropic's Hillclimb Implementation

Anthropic has built hill-climbing directly into their Claude API skill/tools, available in the [anthropics/skills](https://github.com/anthropics/skills) repository under `skills/claude-api/`.

### Key Components

The implementation consists of several interconnected parts:

- **`/claude-api hillclimb` subcommand** - The main entry point for hill-climbing on an existing eval
- **`shared/evals/eval-hillclimb.md`** - Comprehensive guide (69KB) detailing the full process
- **`shared/evals/build-eval.md`** - Guide for building eval sets (54KB)
- **`shared/evals/eval-audit.md`** - Health checklist for eval quality
- **`shared/evals/report/`** - Report generation tools (full viewer and lite version)
- **`shared/evals/report/runner-scaffold.mjs`** - Template for creating hillclimb-compatible eval runners

### Accessing it

In Claude Code with the Anthropic skills plugin installed:
```bash
/plugin marketplace add anthropics/skills
/plugin install example-skills@anthropic-agent-skills
```

Then invoke via `/claude-api hillclimb` in Claude Code when working with Claude API code.

## 3. How build-eval and hillclimb Work

### build-eval Workflow

The `build-eval` subcommand guides you through creating a trustworthy eval:

**Steps:**
1. **Understand what's being evaluated** - Pin down the specific flow/use case and entry point
2. **Find/build input set** - Source from production logs, bug reports, hand-written cases, or synthesize; aim for 15-100 cases
3. **Decide how to grade** - Choose between programmatic checks, pairwise comparison, model-graded rubrics, or human spot-checks
4. **Make it runnable** - Create a script that runs the app, grades outputs, writes results in the standard format
5. **Validate** - Review pilot results with the user and get sign-off

**Key principles:**
- Get explicit user sign-off on inputs and grading method
- Grade the end state/outcome, not just the transcript
- Keep evals focused on one flow
- Use held-out data or proper train/test splits
- Record full traces, usage, model, and grades

### hillclimb Workflow

The hillclimb process is more sophisticated with state management:

**Step 0: Confirm runnable eval**
- Verify eval script exists and produces the right format
- Check it captures full transcripts, model, usage, and grades per case
- Run eval-audit to ensure eval is trustworthy

**Step 0.5: Prove eval can be climbed**
- Calculate noise floor vs headroom
- Verify mechanism is wired correctly
- Spot-check grading on failures
- Check model substitution and retry behavior
- For stochastic builds, measure build variance

**Step 1: Agree on goal and scope**
- Define optimization target (raise metric, cut cost, cut latency, migrate model)
- Decide what to iterate on (prompt, tools, harness, etc.)
- Set off-limits
- Determine how changes reach the model

**Step 2: Agree on stopping condition and budget**
- Choose cadence: until plateau, one-by-one, or N rounds
- Set budget if cost matters
- Get plan approval from user

**Step 3: Set up state and baseline**
- Create directory structure under `.claude/hillclimb/<flow>/`
- Split data into train/test (or just score all if small set)
- Run baseline on full set with chosen rep count
- Record environment fingerprint

**Step 4: The loop (analyze -> apply -> run -> record)**
- **Analyze**: Spawn fresh analyzer subagent that reads only train split traces/scores, proposes one change with rationale
- **Apply**: Apply the change (with user approval if `approve_each_round` is true)
- **Run**: Execute eval in background, verify results written
- **Record**: Generate reports, update state, decide next change

**State structure:**
```
.claude/hillclimb/<flow>/
  _state.json            # loop state, split, goal, best
  metrics.md             # metric definitions
  narrative.md           # running summary
  baseline/              # baseline results
    results.jsonl
    summary.json
    traces/
  v1/, v2/, ...          # each round
    change.md            # what changed and why
    change.patch         # diff
    results.jsonl
    summary.json
    traces/
  trajectory/scores.tsv  # cross-round scores
```

**Key features:**
- **Train/test split** to prevent overfitting - analyzer only sees train data
- **Fresh analyzer per round** to avoid context pollution
- **Background execution** so user isn't blocked
- **Harness integrity checking** - detects if eval runner/harness changed
- **Cost tracking** - tracks spend per run
- **Replicates** for statistical significance
- **Support for different goals** (quality, cost, latency)

## 4. Related Concepts & Resources

### Daniel Miessler - Optimize
- Focuses on systematically improving AI workflows and prompts
- Emphasizes measurement and iteration
- Related to "systematic prompt optimization"

### Murat Cankoylan - Self-Improvement Loops
- Explores agents that improve themselves
- Concepts around meta-learning and recursive improvement
- Self-modifying agents and feedback loops

### OpenAI Testing Agent Skills
- OpenAI's approach to evaluating and improving agent capabilities
- Focus on skill-based evaluation and improvement
- Related to their function calling and agent frameworks

### Harness Engineering
- Building better scaffolding/harnesses around models
- Includes tool design, context management, error handling
- Often more impactful than just prompt changes

### Other related work
- **DSPy** - Programmatic prompt optimization (MIPRO, COPRO, etc.)
- **Promptfoo** - Eval and red teaming framework
- **LangSmith** - Tracing and evaluation platform
- **SWE-bench** - Benchmark that drives coding agent improvement
- **SWE-agent, OpenHands** - Agents improved through hill-climbing on benchmarks

## 5. Tools & Patterns

### hillclimb.sh patterns
While not a single canonical script, common patterns include:
```bash
# Run eval, capture results
./eval.sh --output results.jsonl

# Analyze failures
python analyze_failures.py results.jsonl

# Apply changes to prompt/config
# Re-run
./eval.sh --output results_v2.jsonl

# Compare
python compare.py results.jsonl results_v2.jsonl
```

### Harness Hill-Climbing Patterns

Effective patterns from the Anthropic implementation:

1. **Separation of concerns**: Analyzer (proposes changes) separate from executor (runs eval)
2. **Information asymmetry**: Only show analyzer train data, report on test data
3. **Fresh context**: New analyzer subagent each round prevents overfitting to conversation history
4. **State persistence**: Track all rounds for learning and reproducibility
5. **Incremental changes**: Make one focused change per round for clear attribution
6. **Statistical rigor**: Use noise floors, confidence intervals, reps
7. **Artifact tracking**: Save diffs, traces, and rationales
8. **Background execution**: Don't block user during long eval runs

### Report Generation
The full viewer provides:
- Summary dashboard with scores across rounds
- Per-case analysis with full traces
- Harness changes view showing diffs
- Trajectory tracking
- Cost/latency metrics

## 6. Swarm Orchestration Connection

Hill climbing connects naturally to swarm/orchestration patterns:

### Synergies

- **Parallel exploration**: Multiple agents can test different improvement hypotheses simultaneously
- **Specialized roles**: 
  - Analyzer agent: Reviews failures and proposes changes
  - Implementer agent: Applies changes to codebase
  - Tester agent: Runs evals
  - Critic agent: Reviews proposed changes before applying
- **Distributed eval running**: Run evals across multiple workers
- **Diverse strategies**: Different agents try different optimization strategies (prompt rewriting vs tool changes vs harness modifications)

### Swarm Patterns for Hill Climbing

```python
# Conceptual swarm approach
swarm = {
  "analyzers": [analyze_failures_by_category(failures) for cat in categories],
  "proposers": [generate_hypotheses(analysis) for analysis in analyses],
  "implementers": [apply_change(prop) for prop in top_proposals],
  "evaluators": [run_eval(impl) parallel for impl in implementations],
  "selector": select_best_by_test_score(results)
}
```

### Integration Ideas
- Use swarm to explore solution space in parallel (breadth-first) before committing to hill climbing (depth-first)
- Have swarm debate proposed changes
- Coordinate eval runs across multiple environments
- Share learnings across swarm members via shared memory/context

## 7. Practical Implementation Advice

### Getting Started

1. **Start simple**: Don't build the full Anthropic system from scratch. Start with manual hill climbing.
2. **Good eval is critical**: Spend time on build-eval. A bad eval leads to optimizing the wrong thing.
3. **One change at a time**: Easier to attribute improvements/failures
4. **Track everything**: Save prompts, diffs, results for each iteration
5. **Use train/test split**: Essential to avoid overfitting

### Best Practices

- **Focus on failures**: Don't optimize for cases that already pass
- **Read traces, not just scores**: Understand *why* something failed
- **Generalize fixes**: Avoid case-specific hacks that won't generalize
- **Consider the harness**: Often tool design or scaffolding matters more than prompt wording
- **Mind the noise floor**: Don't chase improvements smaller than statistical noise
- **Budget awareness**: Track costs, especially with judge models
- **Preserve what works**: Keep a git history or snapshots

### Common Pitfalls

- **Overfitting to train set**: Always validate on held-out data
- **Chasing noise**: Without proper stats, you'll think random variation is improvement
- **Vague evals**: If you can't clearly define success, you can't optimize for it
- **Changing too much**: Multiple changes make attribution impossible
- **Ignoring negative results**: Learning from failures is as important as successes
- **Eval contamination**: Ensure test data isn't seen during development

### Quick Start Template

```bash
# 1. Create eval
mkdir -p evals/mytask
# Write eval cases and runner

# 2. Baseline
./evals/mytask/run.sh > results/baseline.jsonl

# 3. Iterate
for i in 1 2 3 4 5; do
  echo "=== Round $i ==="
  # Analyze failures
  python analyze.py results/round$((i-1)).jsonl
  # Make changes (manually or with agent)
  # Run eval
  ./evals/mytask/run.sh > results/round$i.jsonl
  # Compare
  python compare.py results/round$((i-1)).jsonl results/round$i.jsonl
done
```

## 8. References

### Official Sources
- [Anthropic Skills Repository](https://github.com/anthropics/skills) - Source for claude-api skill with hillclimb
- [Agent Skills Documentation](https://docs.anthropic.com/claude/docs/agent-skills) - Anthropic's agent skills docs
- [Claude API Documentation](https://docs.anthropic.com/claude/reference/) - API reference

### Key Files from Anthropic Skills
- `skills/claude-api/SKILL.md` - Main skill file with hillclimb subcommand
- `skills/claude-api/shared/evals/eval-hillclimb.md` - Full hillclimb guide
- `skills/claude-api/shared/evals/build-eval.md` - Eval building guide
- `skills/claude-api/shared/evals/eval-audit.md` - Eval quality checklist

### Related Projects & Articles
- [Promptfoo](https://github.com/promptfoo/promptfoo) - Eval framework
- [DSPy](https://github.com/stanfordnlp/dspy) - Prompt optimization
- [LangSmith](https://www.langchain.com/langsmith) - Tracing and evals
- [SWE-bench](https://www.swebench.com/) - Software engineering benchmark
- [OpenHands](https://github.com/All-Hands-AI/OpenHands) - Open source coding agent

### Community Resources
- Daniel Miessler's work on optimizing AI workflows
- Murat Cankoylan's writings on self-improving systems
- Various blog posts on "agentic evals" and systematic improvement

---

*This research was compiled from Anthropic's skills repository, their eval-hillclimb documentation, and broader knowledge of AI agent optimization practices.*
