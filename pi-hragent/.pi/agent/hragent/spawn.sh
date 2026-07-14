#!/usr/bin/env bash
# hragent-spawn — spawn a named subagent pi session via herdr
# Usage: ./hragent-spawn.sh <name> [--cwd DIR] [--split window|right|down] [--task TASK]
#
# Spawns a new herdr pane running pi with the given name.
# If --task is provided, sends it as the first message after /name.
# This triggers a turn → syncPresenceIdentity → worker becomes routable by name.
# Prints the pane_id on stdout.

set -euo pipefail

NAME="${1:?usage: hragent-spawn.sh <name> [--cwd DIR] [--split right|down] [--task TASK]}"
shift
CWD="$PWD"
SPLIT="window"
TASK=""

while [ $# -gt 0 ]; do
  case "$1" in
    --cwd) CWD="$2"; shift 2 ;;
    --split) SPLIT="$2"; shift 2 ;;
    --task) TASK="$2"; shift 2 ;;
    *) echo "unknown: $1"; exit 1 ;;
  esac
done

# Spawn via herdr agent start
START_OUT=$(herdr agent start "$NAME" --cwd "$CWD" --split "$SPLIT" --no-focus -- env TERM=xterm-256color pi)

# Parse pane_id from herdr JSON: result.agent.pane_id (primary), result.pane.pane_id (fallback)
PANE_ID=$(echo "$START_OUT" | python3 -c '
import sys, json
d = json.load(sys.stdin)
r = d.get("result", d)
if isinstance(r, dict) and "agent" in r and isinstance(r["agent"], dict) and "pane_id" in r["agent"]:
    print(r["agent"]["pane_id"])
elif isinstance(r, dict) and "pane" in r and isinstance(r["pane"], dict) and "pane_id" in r["pane"]:
    print(r["pane"]["pane_id"])
elif isinstance(r, dict) and "pane_id" in r:
    print(r["pane_id"])
else:
    print("")
' 2>/dev/null || echo "")

if [ -z "$PANE_ID" ]; then
  echo "ERROR: could not parse pane_id from herdr output" >&2
  echo "$START_OUT" >&2
  exit 1
fi

echo "spawned $NAME at pane $PANE_ID" >&2

# Wait for pi to start (agent_status: idle = ready)
herdr wait agent-status "$PANE_ID" --status idle --timeout 30000 2>/dev/null || true

# Send /name to set pi session name
herdr pane run "$PANE_ID" "/name $NAME" 2>/dev/null || true
sleep 1

# Wait for /name to be processed
herdr wait agent-status "$PANE_ID" --status idle --timeout 15000 2>/dev/null || true

# Send first task (non-command) to trigger a turn → syncPresenceIdentity → name registers in intercom
if [ -n "$TASK" ]; then
  herdr pane run "$PANE_ID" "$TASK" 2>/dev/null || true
  # Worker is now working on the task AND routable via intercom by name
  echo "task sent to $NAME via pane run (triggers intercom name sync)" >&2
else
  echo "WARNING: no --task provided. Intercom name won't sync until a turn starts." >&2
  echo "Send a non-command message via 'herdr pane run $PANE_ID \"<message>\"' to trigger sync." >&2
fi

# Print pane_id for the caller
echo "$PANE_ID"
