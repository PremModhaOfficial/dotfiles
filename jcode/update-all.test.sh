#!/usr/bin/env bash
# Regression test for the skills phases of update-all.sh.
#
#   bash jcode/update-all.test.sh [path-to-update-all.sh]
#
# exit 0 = pass, 1 = fail, 77 = could not test (missing clone, lock held).
# 77 is deliberately not green: a test that cannot run must not look like a pass.
#
# Assertion 1 fails on the pre-enumeration script (7 hardcoded caveman skills
# instead of the 22 upstream ships) and on any future skill upstream adds.
# Assertion 2 runs the real write_manifest against a fixture, so a reverted
# source case fails here instead of passing on an already-generated README.
set -uo pipefail

SCRIPT="${1:-$(dirname "${BASH_SOURCE[0]}")/update-all.sh}"
CAVEMAN_SRC="$HOME/.jcode/updater-src/caveman/skills"

fail=0
ok() { echo "PASS: $*"; }
bad() { echo "FAIL: $*"; fail=1; }

[ -d "$CAVEMAN_SRC" ] || { echo "SKIP: no caveman clone at $CAVEMAN_SRC"; exit 77; }
upstream=$(find "$CAVEMAN_SRC" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
[ "$upstream" -gt 0 ] || { echo "SKIP: no SKILL.md under $CAVEMAN_SRC"; exit 77; }

# --- 1. every upstream caveman skill is synced ------------------------------
# The real script mktemp -d's a run dir under $HOME/.jcode/logs and never removes
# it, so a test that claims to be read-only would leave litter behind. Note what
# exists, then delete only what this run created.
logs_root="$HOME/.jcode/logs"
before=$(find "$logs_root" -maxdepth 1 -name 'update-all-*' 2>/dev/null | sort)
out=$(bash "$SCRIPT" --dry-run --skills-only 2>&1)
rc=$?
for d in $(find "$logs_root" -maxdepth 1 -name 'update-all-*' 2>/dev/null | sort); do
  printf '%s\n' "$before" | grep -qxF "$d" || rm -rf "$d"
done
case "$out" in
  *"owns the lock"*) echo "SKIP: another update-all run owns the lock"; exit 77 ;;
esac
listed=$(printf '%s\n' "$out" | grep 'DRY: sync' | grep -c 'caveman/skills/')
if [ "$rc" = 0 ] && [ "$listed" = "$upstream" ]; then
  ok "sync_skills enumerates $listed/$upstream caveman skills"
else
  bad "sync_skills enumerates $listed of $upstream caveman skills (exit $rc)"
fi

# --- 2. write_manifest attributes every one of them ------------------------
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
while read -r skill_md; do
  name=$(basename "$(dirname "$skill_md")")
  mkdir -p "$fixture/skills/$name"
  : > "$fixture/skills/$name/SKILL.md"
done < <(find "$CAVEMAN_SRC" -maxdepth 2 -name SKILL.md)
# Decoys that are in no clone, or are non-skill dirs inside one (caveman ships
# native/ and generated/ next to its skills): all must stay unmanaged, or the
# probe is claiming files the updater never synced.
for decoy in not-a-caveman-skill native generated; do
  mkdir -p "$fixture/skills/$decoy"
  : > "$fixture/skills/$decoy/SKILL.md"
done

# Sourcing re-assigns the globals from $HOME, so override after, not before.
# shellcheck disable=SC1090
source "$SCRIPT"
SKILLS_DIR="$fixture/skills"
MANIFEST="$fixture/README.md"
LOG_DIR="$fixture/logs"
LOG="$LOG_DIR/update-all.log"
# CHECKLIST_TMP is resolved at source time, so it must be redirected here too or
# the test appends to the real run ledger.
CHECKLIST_TMP="$fixture/checklist.tsv"
mkdir -p "$LOG_DIR"
write_manifest > /dev/null 2>&1

rows=$(grep -c 'JuliusBrussee/caveman' "$fixture/README.md" 2>/dev/null || true)
rows=${rows:-0}
decoys_ok=1
for decoy in not-a-caveman-skill native generated; do
  grep -q "^| $decoy | bundled/manual |" "$fixture/README.md" || decoys_ok=0
done
if [ "$rows" = "$upstream" ] && [ "$decoys_ok" = 1 ]; then
  ok "write_manifest attributes all $upstream caveman skills, decoys stay unmanaged"
else
  bad "write_manifest attributed $rows of $upstream caveman skills (decoys clean: $decoys_ok)"
fi

exit "$fail"
