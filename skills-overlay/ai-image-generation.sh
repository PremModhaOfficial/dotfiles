#!/usr/bin/env bash
# skills-overlay/ai-image-generation.sh — contract: ~/.jcode/scratch/skills-audit/overlay-spec.md
# Why: every command needs the inference.sh CLI (`belt`), which is not installed on
# this host; state that up front with the install URL the skill already carries.
# Idempotent: a patch is skipped when its new text is already present.
# Touches only $SKILL_DIR/SKILL.md, then $SKILL_DIR/.overlay-applied.
set -uo pipefail

SD="${SKILL_DIR:-$PWD}"
F="$SD/SKILL.md"
MARK="$SD/.overlay-applied"
warn() { echo "OVERLAY-WARN: ai-image-generation: $*"; }

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
    print("OVERLAY-WARN: ai-image-generation: anchor not found: " + old.splitlines()[0][:70]); sys.exit(0)
open(f, "w", encoding="utf-8").write(p.replace(old, new, 1))
print("apply ok: " + new.splitlines()[0][:70])
PY
}

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
