#!/usr/bin/env bash
# skills-overlay/ai-image-generation.sh — contract: ~/.jcode/scratch/skills-audit/overlay-spec.md
# Why: every command needs the inference.sh CLI (`belt`), which is not installed on
# this host; state that up front with the install URL the skill already carries.
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
warn() { echo "OVERLAY-WARN: ai-image-generation: $*"; }

[ -f "$F" ] || { warn "no SKILL.md in $SD"; exit 3; }
cd "$SD" || { warn "cannot cd $SD"; exit 3; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 3; }
trap 'rm -rf "$tmp"' EXIT


cat > "$tmp/old" <<'OLD'
> **Install the belt CLI skill:** `npx skills add belt-sh/cli`
OLD
cat > "$tmp/new" <<'NEW'
> **Not available on this host:** the inference.sh CLI (`belt`) is not installed, so every command below is inert until you install it: https://raw.githubusercontent.com/inference-sh/skills/refs/heads/main/cli-install.md

> **Install the belt CLI skill:** `npx skills add belt-sh/cli`
NEW
patch "$tmp/old" "$tmp/new"

touch "$MARK"
echo "overlay done: $SD"
