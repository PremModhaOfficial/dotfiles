#!/usr/bin/env bash
# skills-overlay/cua-driver.sh — contract: ~/.jcode/scratch/skills-audit/overlay-spec.md
# Why: links MACOS.md and WINDOWS.md, which a Linux host-filtered install does not
# contain; name them as host-specific package docs instead of local links.
# $SKILL_DIR is a symlink (~/.agents/skills/cua-driver -> ~/.cua-driver/skills/cua-driver):
# the patch and the marker go to the resolved real directory and nowhere else.
set -uo pipefail

# patch() is shared: jcode/overlay-lib.sh and resolved from this script's
# directory before any cd, so a relative invocation still finds it. A missing
# anchor is a non-zero exit with no marker, never a silent pass, and a lib that
# cannot be found fails here instead of falling through to the system `patch`.
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../jcode/overlay-lib.sh"
[ -f "$LIB" ] || { echo "OVERLAY-WARN: ${0##*/}: missing $LIB" >&2; exit 3; }
. "$LIB"

SD="${SKILL_DIR:-$PWD}"
MARK_NAME=".overlay-applied"
warn() { echo "OVERLAY-WARN: cua-driver: $*"; }

REAL=$(cd "$SD" 2>/dev/null && pwd -P) || { warn "cannot resolve $SD"; exit 3; }
case "$REAL" in
  */skills/cua-driver) : ;;
  *) warn "refusing: $REAL is not a cua-driver skill dir"; exit 3 ;;
esac
F="$REAL/SKILL.md"
MARK="$REAL/$MARK_NAME"
[ -f "$F" ] || { warn "no SKILL.md in $REAL"; exit 3; }
( : > "$REAL/.overlay-probe" ) 2>/dev/null && rm -f "$REAL/.overlay-probe" ||
  { warn "not writable: $REAL"; exit 3; }
cd "$REAL" || { warn "cannot cd $REAL"; exit 3; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 3; }
trap 'rm -rf "$tmp"' EXIT


cat > "$tmp/old" <<'OLD'
- Current host only: [MACOS.md](MACOS.md), [WINDOWS.md](WINDOWS.md), or [LINUX.md](LINUX.md). Other platform files may be absent from a host-filtered installation.
OLD
cat > "$tmp/new" <<'NEW'
- Current host only: [Linux](LINUX.md). The macOS and Windows guides ship in the cua-driver package as `MACOS.md` and `WINDOWS.md`; a host-filtered installation omits them, so this card does not link them.
NEW
patch "$tmp/old" "$tmp/new"

touch "$MARK"
echo "overlay done: $REAL"
