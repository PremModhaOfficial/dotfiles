#!/usr/bin/env bash
# The updater's own skill-activation phase, run against $HOME. Sourcing
# update-all.sh is legal: its main() is behind a BASH_SOURCE guard, so only the
# variable block and the functions are defined. This is the same call
# update-all.sh:687 makes, through the same run_logged wrapper.
set -uo pipefail
source /home/prm/dotfiles/jcode/update-all.sh
mkdir -p "$LOG_DIR" "$(dirname "$CHECKLIST_TMP")"
: > "$CHECKLIST_TMP"
apply_skill_activation
rc=$?
echo "PHASE_EXIT=$rc"
echo "CHECKLIST=$(tr '\n' ';' < "$CHECKLIST_TMP")"
exit "$rc"
