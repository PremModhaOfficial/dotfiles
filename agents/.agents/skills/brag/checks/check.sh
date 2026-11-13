#!/usr/bin/env bash
# The paths brag's Step 3 names, checked on this machine instead of trusted.
#
#   bash ~/.agents/skills/brag/checks/check.sh
#
# exit 0 = every cited path exists, the five stale names are gone and
# references/ still has at least the 16 entries the card states;
# 1 = one of those is false; 77 = no ~/.claude/skills/hyperframes, which is the
# case Step 3 itself calls unavailable, so it is not a pass either.
#
# Why a script: the previous "proof" for this section was a regex over prose
# (`reference/types/\*`, singular) that matched nothing either way, so it passed
# while the card named files that do not exist. These are existence tests.
set -uo pipefail

CLAUDE="${CLAUDE_SKILLS:-$HOME/.claude/skills}"
fail=0
ok() { echo "PASS: $*"; }
bad() { echo "FAIL: $*"; fail=1; }

[ -d "$CLAUDE/hyperframes" ] ||
  { echo "SKIP: no $CLAUDE/hyperframes — Step 3 says to stop here"; exit 77; }

for p in hyperframes/references/brief-contract.md \
         hyperframes-creative/references/house-style.md \
         hyperframes-creative/references/motion-principles.md \
         hyperframes-core/references/determinism-rules.md \
         media-use; do
  if [ -e "$CLAUDE/$p" ]; then ok "cited path exists: $p"; else bad "cited path missing: $p"; fi
done

for stale in format.md motion.md look.md story.md types; do
  if [ -e "$CLAUDE/hyperframes/references/$stale" ]; then
    bad "stale name is back in references/: $stale — update brag Step 3"
  else
    ok "stale name still absent: $stale"
  fi
done

# The card says 16 entries. It grows, so this fails downward only: a deletion
# means the card is stale, an addition does not.
n=$(find "$CLAUDE/hyperframes/references" -mindepth 1 -maxdepth 1 | wc -l)
if [ "$n" -ge 16 ]; then ok "references/ has $n entries"; else bad "references/ has $n entries, card states 16"; fi

exit "$fail"
