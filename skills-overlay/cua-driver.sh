#!/usr/bin/env bash
# skills-overlay/cua-driver.sh — contract: ~/.jcode/scratch/skills-audit/overlay-spec.md
# Why: links MACOS.md and WINDOWS.md, which a Linux host-filtered install does not
# contain; name them as host-specific package docs instead of local links.
# $SKILL_DIR is a symlink (~/.agents/skills/cua-driver -> ~/.cua-driver/skills/cua-driver):
# the patch and the marker go to the resolved real directory and nowhere else.
set -uo pipefail

SD="${SKILL_DIR:-$PWD}"
MARK_NAME=".overlay-applied"
warn() { echo "OVERLAY-WARN: cua-driver: $*"; }

REAL=$(cd "$SD" 2>/dev/null && pwd -P) || { warn "cannot resolve $SD"; exit 0; }
case "$REAL" in
  */skills/cua-driver) : ;;
  *) warn "refusing: $REAL is not a cua-driver skill dir"; exit 0 ;;
esac
F="$REAL/SKILL.md"
MARK="$REAL/$MARK_NAME"
[ -f "$F" ] || { warn "no SKILL.md in $REAL"; exit 0; }
( : > "$REAL/.overlay-probe" ) 2>/dev/null && rm -f "$REAL/.overlay-probe" ||
  { warn "not writable: $REAL"; exit 0; }
cd "$REAL" || { warn "cannot cd $REAL"; exit 0; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 0; }
trap 'rm -rf "$tmp"' EXIT

patch() {
  python3 - "$F" "$1" "$2" <<'PY'
import sys
f, o, n = sys.argv[1:4]
p = open(f, encoding="utf-8").read()
old = open(o, encoding="utf-8").read()
new = open(n, encoding="utf-8").read()
if new in p:
    print("skip  already applied: " + new.splitlines()[0][:70]); sys.exit(0)
if old not in p:
    print("OVERLAY-WARN: cua-driver: anchor not found: " + old.splitlines()[0][:70]); sys.exit(0)
open(f, "w", encoding="utf-8").write(p.replace(old, new, 1))
print("apply ok: " + new.splitlines()[0][:70])
PY
}

cat > "$tmp/old" <<'OLD'
- Current host only: [MACOS.md](MACOS.md), [WINDOWS.md](WINDOWS.md), or [LINUX.md](LINUX.md). Other platform files may be absent from a host-filtered installation.
OLD
cat > "$tmp/new" <<'NEW'
- Current host only: [Linux](LINUX.md). The macOS and Windows guides ship in the cua-driver package as `MACOS.md` and `WINDOWS.md`; a host-filtered installation omits them, so this card does not link them.
NEW
patch "$tmp/old" "$tmp/new"

touch "$MARK"
echo "overlay done: $REAL"
