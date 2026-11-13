#!/usr/bin/env bash
# IT3-5 proof: a failing skill step must return non-zero whether or not the
# caller inherited `set -o pipefail`, and it must still print its own error line
# under `set -e`. Old form: `cmd | tee || rc=1`.
# Run: bash ~/.agents/loop/it3-5-pipestatus-proof.sh
set -u
NEW="$HOME/dotfiles/jcode/update-all.sh"
OLD=/tmp/update-all.head.sh
git -C "$HOME/dotfiles" show HEAD:jcode/update-all.sh > "$OLD"

STUB=$(mktemp -d)
printf '#!/bin/sh\necho "STUB python3 $*"\nexit 3\n' > "$STUB/python3"
chmod +x "$STUB/python3"

# case_run FILE pipefail(0|1) label errexit(0|1)
# Sources FILE, sets the caller's shell options, calls the real apply_skill_cap
# with a python3 that exits 3, and reports its status plus whether its own
# "skill catalogue cap failed" line reached the log.
case_run() {
  env HOME="$HOME" PATH="$STUB:$PATH" bash -c '
    set -u
    [ "$4" = 1 ] && set -e
    [ "$2" = 1 ] && set -o pipefail || set +o pipefail
    source "$1"
    LOG=/tmp/it3-5-stub.log; CHECKLIST_TMP=/tmp/it3-5-stub.tsv
    : > "$LOG"; : > "$CHECKLIST_TMP"
    st=0
    apply_skill_cap >/dev/null 2>&1 || st=$?
    if grep -q "skill catalogue cap failed" "$LOG"; then said=yes; else said=no; fi
    printf "=> %s: returned %s, own error line printed: %s\n" "$3" "$st" "$said"
  ' _ "$1" "$2" "$3" "${4:-0}"
}

echo "--- the stub really fails:"
"$STUB/python3" x; echo "stub exit=$?"
echo
echo "--- OLD file (HEAD), pre-fix line: python3 ... | tee -a LOG || rc=1"
case_run "$OLD" 0 "old, set +o pipefail"
case_run "$OLD" 1 "old, set -o pipefail"
echo
echo "--- CURRENT file, run_logged reads PIPESTATUS itself"
case_run "$NEW" 0 "new, set +o pipefail"
case_run "$NEW" 1 "new, set -o pipefail"
case_run "$NEW" 1 "new, set -euo pipefail (run_jobs child)" 1
case_run "$OLD" 1 "old, set -euo pipefail (run_jobs child)" 1
rm -rf "$STUB"
