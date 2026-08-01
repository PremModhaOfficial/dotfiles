#!/usr/bin/env bash
# ============================================================================
# babysitter-gate.sh — jcode turn_end_gate hook: bridge to a5c-ai/babysitter.
#
# jcode runs this after each turn when [hooks] turn_end_gate is configured.
# Contract (implemented in jcode crates/jcode-base/src/hooks.rs):
#   - stdout JSON {"decision":"block","followup_message":"<text>"}
#     => jcode injects <text> as the next turn's instruction (continuation)
#   - exit 0 with no stdout / malformed JSON => no injection
#
# Behavior:
#   - If no babysitter run is active for this repo, emit nothing (plain exit 0):
#     normal chat turns are completely unaffected.
#   - If an active run exists, ask the babysitter CLI for the next iteration's
#     effects and emit a followup that tells the agent to perform them.
#
# Enable it in ~/.jcode/config.toml:
#   [hooks]
#   turn_end_gate = "~/.jcode/hooks/babysitter-gate.sh"
#   turn_end_gate_timeout_ms = 5000
# ============================================================================
set -uo pipefail

# Find an active babysitter run in this repo or the global runs dir.
RUNS_DIR="${BABYSITTER_RUNS_DIR:-$HOME/.a5c/runs}"
if [ -d ".a5c/runs" ]; then
  RUNS_DIR=".a5c/runs"
fi

# The most recently touched run dir with a journal and a process assigned.
active_run=""
if [ -d "$RUNS_DIR" ]; then
  active_run=$(find "$RUNS_DIR" -maxdepth 1 -mindepth 1 -type d \
    -exec test -e '{}/journal.jsonl' \; -print 2>/dev/null \
    | sort | tail -1)
fi
[ -n "$active_run" ] || exit 0

# Only continue if the run is still in progress (not completed/failed).
if grep -q '"status":"completed"\|"status":"failed"' "$active_run/journal.jsonl" 2>/dev/null; then
  exit 0
fi

# Babysitter CLI: prefer a global install, fall back to npx.
if command -v babysitter >/dev/null 2>&1 && babysitter --version >/dev/null 2>&1; then
  CLI="babysitter"
else
  CLI="npm exec --yes --package @a5c-ai/babysitter-sdk@latest -- babysitter"
fi

# Ask babysitter for the next iteration effects (JSON).
# On failure, emit nothing so normal operation is preserved.
effects=$("$CLI" run:iterate "$active_run" --json 2>/dev/null) || exit 0

# Pull out the pending task summary for the followup message.
task_id=$(printf '%s' "$effects" | jq -r '.effects[0].taskId // .effects[0].task_id // ""' 2>/dev/null)
if [ -z "$task_id" ]; then
  # No pending effects => the run may be complete; let the agent conclude.
  exit 0
fi

# Emit the continuation instruction as the next turn's user message.
printf '{"decision":"block","followup_message":"[babysitter] Continue the orchestration run: perform the pending task '%s'. Read the task brief from the run journal at %s, execute it, then post the result with: babysitter task:post %s <effectId> --status ok --value <file> --json. If the run is complete, reply with your final summary and stop."}' \
  "$task_id" "$active_run" "$active_run"
