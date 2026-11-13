#!/usr/bin/env bash
# IT4-4 proof: four runs of the updater's own skill-activation phase, each with
# HOME pointed at a sandbox, so the state file, the tree and the log are all
# inside the sandbox. The live tree is read once (to build the "full" tree) and
# never written.
#
#   bash ~/.agents/loop/it4-4/run.sh            # prints the transcript
#
# Phase granularity, not whole-update granularity: apply_skill_activation is the
# step update-all runs (update-all.sh:677-700) and the exit code it returns is
# what the phases loop turns into the run's exit. A whole --skills-only run would
# git-pull 5 upstream repos into the sandbox first, which proves nothing extra
# about this ticket.
set -uo pipefail

S=/home/prm/.cache/it4-4
REAL_CARDS=/home/prm/.agents/skills
PHASE=/home/prm/.agents/loop/it4-4/phase.sh

rm -rf "$S"; mkdir -p "$S"

# Render a full card tree into a sandbox HOME: every installed SKILL.md, no
# symlinks (two installed skills are symlinks out of the tree, and a sandbox must
# not be able to write through them).
full_tree() { # full_tree <home>
  local home=$1 n=0
  mkdir -p "$home/.agents/skills"
  while IFS= read -r -d '' card; do
    local d="$home/.agents/skills/${card#"$REAL_CARDS"/}"
    mkdir -p "$(dirname "$d")"
    cp -L "$card" "$d" || return 1
    n=$((n+1))
  done < <(find -L "$REAL_CARDS" -name SKILL.md -print0)
  echo "$n"
}

run_case() { # run_case <label> <home>
  local label=$1 home=$2 out rc
  out=$(HOME="$home" bash "$PHASE" 2>&1); rc=$?
  printf '\n===== %s =====\n' "$label"
  printf '%s\n' "$out" | sed -n '1,40p'
  printf 'EXIT=%d\n' "$rc"
  printf 'WARN_LINES=%d\n' "$(printf '%s\n' "$out" | grep -c 'WARN:')"
  printf 'STATE=%s\n' "$(cat "$home/.jcode/state/skills-activation.json" 2>/dev/null |
    python3 -c 'import json,sys; d=json.load(sys.stdin); print("count=%d fingerprint=%s" % (d["count"], d["fingerprint"][:12]))' 2>/dev/null || echo absent)"
  return "$rc"
}

echo "### sandbox root: $S"
echo "### live cards: $(find -L "$REAL_CARDS" -name SKILL.md | wc -l)"

# (a) empty tree, no state
A=$S/a
mkdir -p "$A"
run_case "a empty tree, no state" "$A"; echo "a_exit=$?"

# (c) full tree, state written by (a2), unchanged  -- build the state first
C=$S/c
N=$(full_tree "$C")
echo
echo "### c tree built with $N cards; run 1 writes the baseline"
run_case "c1 full tree, no state (baseline)" "$C" >/dev/null
run_case "c2 full tree, state present, unchanged" "$C"; echo "c_exit=$?"

# (b) same tree, state present, 20 cards deleted
B=$S/b
cp -a "$C" "$B"
find "$B/.agents/skills" -mindepth 1 -maxdepth 1 -type d | sort | head -20 |
  while IFS= read -r d; do rm -rf "$d"; done
echo
echo "### b tree now $(find -L "$B/.agents/skills" -name SKILL.md | wc -l) cards"
run_case "b full tree, state present, 20 deleted" "$B"; echo "b_exit=$?"

# (d) state from a wiped run, then the full tree is restored
D=$S/d
mkdir -p "$D"
run_case "d1 wiped tree, no state (writes a 0 baseline)" "$D" >/dev/null
M=$(full_tree "$D")
echo
echo "### d2 $M cards restored under the wiped run's state"
run_case "d2 full tree restored, state says 0" "$D"; echo "d_exit=$?"

# (e) the reviewer's own case, for the record: a cold sync installs 35 cards
#     into a tree that has no state yet. Not one of the four, same rule.
E=$S/e
mkdir -p "$E/.agents/skills"
find -L "$REAL_CARDS" -name SKILL.md | sort | head -35 | while IFS= read -r card; do
  d="$E/.agents/skills/${card#"$REAL_CARDS"/}"
  mkdir -p "$(dirname "$d")"; cp -L "$card" "$d"
done
echo "### e tree: $(find -L "$E/.agents/skills" -name SKILL.md | wc -l) cards, no state"
run_case "e reviewer's case: 35 cards, no state" "$E"; echo "e_exit=$?"
