#!/usr/bin/env bash
# caveman-help — two fixes a re-sync would otherwise wipe:
#   1. README links up to the repo root (../../), which is outside the install.
#      Rewrite them to their upstream URLs; sed only matches the relative form,
#      so a second run changes nothing.
#   2. The skill table routes to caveman-review only and describes it as
#      safety-tagged PR comments, which is tiger-style-review's job. Our copy
#      lists both with their real triggers; re-apply it or the next sync of
#      JuliusBrussee/caveman drops the row.
# Idempotent: the sed is grep-guarded, a patch is skipped when its new text is
# already present. Touches only README.md, SKILL.md, then .overlay-applied.
# Contract: see apply_overlays() in ~/dotfiles/jcode/update-all.sh.
set -uo pipefail

fix_ref() { # fix_ref <repo-relative-path>: ../../<path> -> upstream URL
  local p esc
  p="$1"
  [ -f README.md ] || { echo "OVERLAY-WARN: no README.md in $SKILL_DIR"; return 0; }
  grep -qF "../../$p" README.md || return 0
  esc=$(printf '%s' "$p" | sed 's/[.[*^$\\]/\\&/g')
  sed -i "s|\.\./\.\./$esc|https://github.com/JuliusBrussee/caveman/blob/main/$p|g" README.md
  echo "OVERLAY: README.md ../../$p -> upstream URL"
}

fix_ref README.md

SD="${SKILL_DIR:-$PWD}"
F="$SD/SKILL.md"
MARK="$SD/.overlay-applied"
warn() { echo "OVERLAY-WARN: caveman-help: $*"; }

[ -f "$F" ] || { warn "no SKILL.md in $SD"; exit 0; }
cd "$SD" || { warn "cannot cd $SD"; exit 0; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 0; }
trap 'rm -rf "$tmp"' EXIT

# patch <oldfile> <newfile>: one literal replacement, skipped when already applied.
# The heredocs carry a trailing newline; strip it so a patch can end a file that
# has none, and so an interior anchor matches without eating the next newline.
patch() {
  python3 - "$F" "$1" "$2" <<'PY'
import sys
f, o, n = sys.argv[1:4]
p = open(f, encoding="utf-8").read()
old = open(o, encoding="utf-8").read().rstrip("\n")
new = open(n, encoding="utf-8").read().rstrip("\n")
if new in p:
    print("skip  already applied: " + new.splitlines()[0][:70]); sys.exit(0)
if old not in p:
    print("OVERLAY-WARN: caveman-help: anchor not found: " + old.splitlines()[0][:70]); sys.exit(0)
open(f, "w", encoding="utf-8").write(p.replace(old, new, 1))
print("apply ok: " + new.splitlines()[0][:70])
PY
}

cat > "$tmp/old" <<'OLD'
| **caveman-review** | `/caveman-review` | One-line PR comments: `L42: bug: user null. Add guard.` |
OLD
cat > "$tmp/new" <<'NEW'
| **tiger-style-review** | `/tiger-style-review` | One-line PR comments: `L42: assert: user null after find. Add guard.` Safety tags only. |
| **caveman-review** | `/caveman-review` | Terse review of any diff: `L42: 🔴 bug: user can be null after .find(). Add guard before .email.` |
NEW
patch "$tmp/old" "$tmp/new"

touch "$MARK"
echo "overlay done: $SD"
