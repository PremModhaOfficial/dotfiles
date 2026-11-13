#!/usr/bin/env bash
# skills-overlay/ghostex-manage-beads.sh — contract: ~/.jcode/scratch/skills-audit/overlay-spec.md
# Why: the ghostex-manage-beads half needs the `ghostex`/`gx` CLI from /opt/ghostex, which
# is not installed on this host. `bd` IS installed (bd version 1.3.4), so it is not
# gated; nothing else restructured.
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
warn() { echo "OVERLAY-WARN: ghostex-manage-beads: $*"; }

[ -f "$F" ] || { warn "no SKILL.md in $SD"; exit 3; }
cd "$SD" || { warn "cannot cd $SD"; exit 3; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 3; }
trap 'rm -rf "$tmp"' EXIT


cat > "$tmp/old" <<'OLD'
---

# ghostex-manage-beads
OLD
cat > "$tmp/new" <<'NEW'
---

> **Availability gate:** the board half is inert on this host — the `ghostex`/`gx` commands below need the Ghostex runtime at `/opt/ghostex` (`/opt/ghostex/gxserver/bin/ghostex`), which is missing (the PATH stubs fail with `No such file or directory`); install Ghostex Desktop, which unpacks `gxserver` into `/opt/ghostex`. The machine-installed `bd` CLI is unaffected: it is present and working (`bd version 1.3.4`).

# ghostex-manage-beads
NEW
patch "$tmp/old" "$tmp/new"

touch "$MARK"
echo "overlay done: $SD"
