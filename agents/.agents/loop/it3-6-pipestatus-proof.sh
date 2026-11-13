#!/usr/bin/env bash
# IT3-6 proof: a failing skill step must still return non-zero whether or not
# the caller inherited `set -o pipefail`, and it must print its own error line
# under `set -e`. Both the transform (apply_skill_activation) and the cap
# (apply_skill_cap) are exercised with a python3 that exits 3.
# Run: bash ~/.agents/loop/it3-6-pipestatus-proof.sh
set -u
NEW="$HOME/dotfiles/jcode/update-all.sh"
RUN="$HOME/.agents/loop/it3-6-run/proof"
rm -rf "$RUN"; mkdir -p "$RUN/tmp"
export TMPDIR="$RUN/tmp"
STUB="$RUN/stub"
mkdir -p "$STUB"
printf '#!/bin/sh\necho "STUB python3 $*"\nexit 3\n' > "$STUB/python3"
chmod +x "$STUB/python3"

# case_run FILE pipefail(0|1) errexit(0|1) function label
# Sources FILE, sets the caller's shell options, calls the real function with a
# python3 that exits 3, and reports its status plus whether its own error line
# reached the log.
case_run() {
  env HOME="$HOME" PATH="$STUB:$PATH" bash -c '
    set -u
    [ "$3" = 1 ] && set -e
    [ "$2" = 1 ] && set -o pipefail || set +o pipefail
    source "$1"
    LOG="$6/stub.log"; CHECKLIST_TMP="$6/stub.tsv"
    : > "$LOG"; : > "$CHECKLIST_TMP"
    st=0
    "$4" >/dev/null 2>&1 || st=$?
    if grep -q "ERROR:" "$LOG"; then said=yes; else said=no; fi
    printf "=> %-28s pipefail=%s errexit=%s: returned %s, own error line: %s\n" \
      "$5" "$2" "$3" "$st" "$said"
  ' _ "$1" "$2" "$3" "$4" "$5" "$RUN"
}

echo "--- the stub really fails:"
"$STUB/python3" x; echo "stub exit=$?"
echo
echo "--- apply_skill_activation (the transform under test)"
case_run "$NEW" 0 0 apply_skill_activation "activation, pipefail off"
case_run "$NEW" 1 0 apply_skill_activation "activation, pipefail on"
case_run "$NEW" 1 1 apply_skill_activation "activation, -euo pipefail"
echo
echo "--- apply_skill_cap (the reviewed swallow)"
case_run "$NEW" 0 0 apply_skill_cap "cap, pipefail off"
case_run "$NEW" 1 0 apply_skill_cap "cap, pipefail on"
case_run "$NEW" 1 1 apply_skill_cap "cap, -euo pipefail"
echo
echo "--- the phase's own gate: update_skills must not report success"
env HOME="$HOME" PATH="$STUB:$PATH" bash -c '
  set -u
  set +o pipefail
  source "$1"
  DOTFILES="$HOME/dotfiles"
  LOG="$2/stub2.log"; CHECKLIST_TMP="$2/stub2.tsv"
  : > "$LOG"; : > "$CHECKLIST_TMP"
  st=0
  apply_skill_activation || st=1
  apply_skill_cap || st=1
  printf "=> phase-style rc=%s (want 1)\n" "$st"
' _ "$NEW" "$RUN"
rm -rf "$STUB"
