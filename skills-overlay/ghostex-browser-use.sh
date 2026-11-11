#!/usr/bin/env bash
# skills-overlay/ghostex-browser-use.sh — contract: ~/.jcode/scratch/skills-audit/overlay-spec.md
# Why: the skill drives `cua-driver` (installed) but its Ghostex-only cross-references need
# the Ghostex runtime at /opt/ghostex, which is not installed on this host. Names the
# real missing piece instead of claiming the commands themselves are broken.
# Idempotent: a patch is skipped when its new text is already present.
# Touches only $SKILL_DIR/SKILL.md, then $SKILL_DIR/.overlay-applied.
set -uo pipefail

SD="${SKILL_DIR:-$PWD}"
F="$SD/SKILL.md"
MARK="$SD/.overlay-applied"
warn() { echo "OVERLAY-WARN: ghostex-browser-use: $*"; }

[ -f "$F" ] || { warn "no SKILL.md in $SD"; exit 0; }
cd "$SD" || { warn "cannot cd $SD"; exit 0; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 0; }
trap 'rm -rf "$tmp"' EXIT

# patch <oldfile> <newfile>: one literal replacement, skipped when already applied
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
    print("OVERLAY-WARN: ghostex-browser-use: anchor not found: " + old.splitlines()[0][:70]); sys.exit(0)
open(f, "w", encoding="utf-8").write(p.replace(old, new, 1))
print("apply ok: " + new.splitlines()[0][:70])
PY
}

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
