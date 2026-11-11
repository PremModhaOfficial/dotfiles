#!/usr/bin/env bash
# skills-overlay/ghostex-manage-beads.sh — contract: ~/.jcode/scratch/skills-audit/overlay-spec.md
# Why: the ghostex-manage-beads half needs the `ghostex`/`gx` CLI from /opt/ghostex, which
# is not installed on this host. `bd` IS installed (bd version 1.3.4), so it is not
# gated; nothing else restructured.
# Idempotent: a patch is skipped when its new text is already present.
# Touches only $SKILL_DIR/SKILL.md, then $SKILL_DIR/.overlay-applied.
set -uo pipefail

SD="${SKILL_DIR:-$PWD}"
F="$SD/SKILL.md"
MARK="$SD/.overlay-applied"
warn() { echo "OVERLAY-WARN: ghostex-manage-beads: $*"; }

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
    print("OVERLAY-WARN: ghostex-manage-beads: anchor not found: " + old.splitlines()[0][:70]); sys.exit(0)
open(f, "w", encoding="utf-8").write(p.replace(old, new, 1))
print("apply ok: " + new.splitlines()[0][:70])
PY
}

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
