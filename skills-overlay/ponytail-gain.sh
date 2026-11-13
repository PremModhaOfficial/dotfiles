#!/usr/bin/env bash
# skills-overlay/ponytail-gain.sh — contract: ~/.jcode/scratch/skills-audit/overlay-spec.md
# Why: cites benchmarks/results/2026-10-07-agentic.md, a repo-level path that does not
# exist in the installed skill; point at the upstream file instead.
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
warn() { echo "OVERLAY-WARN: ponytail-gain: $*"; }

[ -f "$F" ] || { warn "no SKILL.md in $SD"; exit 3; }
cd "$SD" || { warn "cannot cd $SD"; exit 3; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 3; }
trap 'rm -rf "$tmp"' EXIT


cat > "$tmp/old" <<'OLD'
Source: `benchmarks/results/2026-10-07-agentic.md` and the README.
OLD
cat > "$tmp/new" <<'NEW'
Source: https://github.com/DietrichGebert/ponytail/blob/main/benchmarks/results/2026-10-07-agentic.md
and https://github.com/DietrichGebert/ponytail#readme
NEW
patch "$tmp/old" "$tmp/new"

touch "$MARK"
echo "overlay done: $SD"
