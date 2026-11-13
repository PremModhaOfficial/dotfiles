#!/usr/bin/env bash
# skills-overlay/ghostex-browser-use.sh — contract: ~/.jcode/scratch/skills-audit/overlay-spec.md
# Why: the skill drives `cua-driver` (installed) but its Ghostex-only cross-references need
# the Ghostex runtime at /opt/ghostex, which is not installed on this host. Names the
# real missing piece instead of claiming the commands themselves are broken.
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
warn() { echo "OVERLAY-WARN: ghostex-browser-use: $*"; }

[ -f "$F" ] || { warn "no SKILL.md in $SD"; exit 3; }
cd "$SD" || { warn "cannot cd $SD"; exit 3; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 3; }
trap 'rm -rf "$tmp"' EXIT


cat > "$tmp/old" <<'OLD'
---

# ghostex-browser-use
OLD
cat > "$tmp/new" <<'NEW'
---

> **Availability gate:** the driver half works here — `cua-driver` is installed (0.35.4). The Ghostex runtime at `/opt/ghostex` is not, so the Ghostex-only cross-references in this skill (for example `$ghostex-embedded-browser-use`, Ghostex's built-in panes) are unavailable until you install Ghostex Desktop, which unpacks `gxserver` into `/opt/ghostex`.

# ghostex-browser-use
NEW
patch "$tmp/old" "$tmp/new"

touch "$MARK"
echo "overlay done: $SD"
