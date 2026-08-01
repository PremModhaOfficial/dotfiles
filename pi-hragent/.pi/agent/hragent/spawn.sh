#!/usr/bin/env bash
# hragent-spawn — spawn a named subagent pi session via herdr
# Usage: ./spawn.sh <name> [--cwd DIR] [--main MAIN_NAME] [--task TASK]
# Creates a tab, starts pi in it, sets the name, sends the task.
# Prints pane_id on stdout.

set -euo pipefail

NAME="${1:?usage: spawn.sh <name> [--cwd DIR] [--main MAIN_NAME] [--task TASK]}"
shift
CWD="$PWD"
MAIN=""
TASK=""

while [ $# -gt 0 ]; do
  case "$1" in
    --cwd) CWD="$2"; shift 2 ;;
    --main) MAIN="$2"; shift 2 ;;
    --split) echo "ERROR: --split removed. Workers always get their own tab." >&2; exit 1 ;;
    --task) TASK="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

# Create tab
TAB_OUT=$(herdr tab create --cwd "$CWD" --no-focus 2>&1)
TAB_ID=$(echo "$TAB_OUT" | jq -r '.result.tab.tab_id // .tab.tab_id // empty') || true
PANE_ID=$(echo "$TAB_OUT" | jq -r '.result.root_pane.pane_id // .result.pane.pane_id // .pane_id // empty') || true

if [ -z "$TAB_ID" ]; then
  echo "ERROR: herdr tab create failed" >&2; echo "$TAB_OUT" >&2; exit 1
fi
if [ -z "$PANE_ID" ]; then
  echo "ERROR: could not parse pane_id from tab create" >&2; echo "$TAB_OUT" >&2; exit 1
fi

echo "spawned $NAME tab=$TAB_ID pane=$PANE_ID" >&2

# Start pi agent in the tab's pane
START_OUT=$(herdr agent start "$NAME" --kind pi --pane "$PANE_ID" --timeout 60000 2>&1)
AGENT_STATUS=$(echo "$START_OUT" | jq -r '.result.agent.agent_status // empty') || true

if [ "$AGENT_STATUS" != "idle" ] && [ "$AGENT_STATUS" != "working" ]; then
  echo "WARNING: agent status is '$AGENT_STATUS', expected idle or working" >&2
fi

# Set name — /name alone doesn't trigger a turn, need a follow-up message
herdr pane run "$PANE_ID" "/name $NAME" 2>/dev/null || true

# Send task — prepends main agent name so worker knows who to send results to
if [ -n "$TASK" ]; then
  FULL_TASK="$TASK"
  if [ -n "$MAIN" ]; then
    FULL_TASK="Your main agent is '${MAIN}'. Send ALL intercom messages (status updates, [DONE], [FAIL], [HELP]) to '${MAIN}' via intercom send. Never read herdr panes. $TASK"
  fi
  herdr pane run "$PANE_ID" "$FULL_TASK" 2>/dev/null || true
  echo "task sent to $NAME" >&2
else
  echo "WARNING: no --task. Send a message later to sync intercom name." >&2
fi

echo "$PANE_ID"
