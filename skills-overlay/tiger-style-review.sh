#!/usr/bin/env bash
# skills-overlay/tiger-style-review.sh — contract: apply_overlays() in ~/dotfiles/jcode/update-all.sh
# Why: the upstream review card gives tags but no comment voice, no pointer to
# the other review skills, and no boundary on approving/linting. Our copy adds a
# "Comment voice" section, a "Not this one" section, and two boundary sentences.
# A sync of PremModhaOfficial/tiger-style overwrites SKILL.md, so re-apply them
# here or the next sync drops our version.
# Idempotent: a patch is skipped when its new text is already present.
# Touches only $SKILL_DIR/SKILL.md, then $SKILL_DIR/.overlay-applied.
set -uo pipefail

# patch() is shared: jcode/overlay-lib.sh and resolved from this script's
# directory before any cd, so a relative invocation still finds it. A missing
# anchor is a non-zero exit with no marker, never a silent pass, and a lib that
# cannot be found fails here instead of falling through to the system `patch`.
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../jcode/overlay-lib.sh"
[ -f "$LIB" ] || { echo "OVERLAY-WARN: ${0##*/}: missing $LIB" >&2; exit 3; }
. "$LIB"

SD="${SKILL_DIR:-$PWD}"
F="$SD/SKILL.md"
MARK="$SD/.overlay-applied"
warn() { echo "OVERLAY-WARN: tiger-style-review: $*"; }

[ -f "$F" ] || { warn "no SKILL.md in $SD"; exit 3; }
cd "$SD" || { warn "cannot cd $SD"; exit 3; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 3; }
trap 'rm -rf "$tmp"' EXIT


cat > "$tmp/old" <<'OLD'
✅ `L152: naming: to (ms? bytes?). Rename to timeout_ms or size_bytes.`

## Scoring
OLD
cat > "$tmp/new" <<'NEW'
✅ `L152: naming: to (ms? bytes?). Rename to timeout_ms or size_bytes.`

## Comment voice

When severities are mixed, prefix the tag:

- `🔴 bug:` broken behavior, will cause an incident.
- `🟡 risk:` works but fragile (race, missing null check, swallowed error).
- `🔵 nit:` style, naming, micro-optimisation. The author can ignore it.
- `❓ q:` a genuine question, not a suggestion.

Drop: "I noticed that", "it seems like", "you might want to consider",
"this is just a suggestion but..." (use `nit:` instead), hedging ("perhaps",
"maybe", "I think"; use `q:` when unsure), praise on every comment (say it once
at the top), and any restatement of what the line already does.

Worked before-and-after:

❌ "I noticed that on line 42 you're not checking if the user object is null
before accessing the email property. This could potentially cause a crash if the
user is not found in the database. You might want to add a null check here."
✅ `L42: 🔴 bug: user can be null after .find(). Add guard before .email.`

❌ "It looks like this function is doing a lot of things and might benefit from
being broken up into smaller functions for readability."
✅ `L88-140: 🔵 nit: 50-line fn does 4 things. Extract validate/normalize/persist.`

❌ "Have you considered what happens if the API returns a 429? I think we
should probably handle that case."
✅ `L23: 🟡 risk: no retry on 429. Wrap in withBackoff(3).`

Keep: exact line numbers, exact symbols in backticks, a concrete fix rather
than "consider refactoring", and the why when the fix is not obvious from the
problem.

Auto-clarity: a security finding (CVE-class), an architectural disagreement,
or an author who is new to the code gets a normal paragraph with the reasoning,
then terse resumes for the rest.

## Scoring
NEW
patch "$tmp/old" "$tmp/new" "## Comment voice"

cat > "$tmp/old" <<'OLD'
If there is nothing to fix, say `Solid. Ship.` and stop.

## Boundaries
OLD
cat > "$tmp/new" <<'NEW'
If there is nothing to fix, say `Solid. Ship.` and stop.

## Not this one

`flow`'s default review is `ds-review-loop` (the loop with a fresh reviewer).
`code-review` runs the standards and spec axes. `ponytail-review` judges the
whole change for correctness, scale and bloat. This one is only the safety and
invariant tags above.

`caveman-review` is the standalone terse review: same one-line shape, the four
severity prefixes, no Tiger Style tag taxonomy. It owns comment voice with no
safety pass; `## Comment voice` above is that same contract applied to these
tags, which is why this file carries it rather than deferring. Use this one
whenever the ask involves invariants.

## Boundaries
NEW
patch "$tmp/old" "$tmp/new" "## Not this one"

cat > "$tmp/old" <<'OLD'
apply the fixes, only lists them.
OLD
cat > "$tmp/new" <<'NEW'
apply the fixes, only lists them. Does not approve or request changes, does not
run linters. Output the comments ready to paste into the PR.
NEW
patch "$tmp/old" "$tmp/new"

touch "$MARK"
echo "overlay done: $SD"
