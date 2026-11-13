#!/usr/bin/env bash
# caveman-review — two fixes a re-sync would otherwise wipe:
#   1. README links up to the repo root (../../), which is outside the install.
#      Rewrite them to their upstream URLs; sed only matches the relative form,
#      so a second run changes nothing.
#   2. SKILL.md has no "Not this one" note separating it from tiger-style-review,
#      so both read as the same one-line review. Our copy adds that note; re-apply
#      it here or the next sync of JuliusBrussee/caveman drops it.
# Idempotent: the sed is grep-guarded, a patch is skipped when its new text is
# already present. Touches only README.md, SKILL.md, then .overlay-applied.
# Contract: see apply_overlays() in ~/dotfiles/jcode/update-all.sh.
set -uo pipefail

# patch() is shared: jcode/overlay-lib.sh and resolved from this script's
# directory before any cd, so a relative invocation still finds it. A missing
# anchor is a non-zero exit with no marker, never a silent pass, and a lib that
# cannot be found fails here instead of falling through to the system `patch`.
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../jcode/overlay-lib.sh"
[ -f "$LIB" ] || { echo "OVERLAY-WARN: ${0##*/}: missing $LIB" >&2; exit 3; }
. "$LIB"

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
warn() { echo "OVERLAY-WARN: caveman-review: $*"; }

[ -f "$F" ] || { warn "no SKILL.md in $SD"; exit 3; }
cd "$SD" || { warn "cannot cd $SD"; exit 3; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 3; }
trap 'rm -rf "$tmp"' EXIT


cat > "$tmp/old" <<'OLD'
Reviews only — does not write the code fix, does not approve/request-changes, does not run linters. Output the comment(s) ready to paste into the PR. "stop caveman-review" or "normal mode": revert to verbose review style.
OLD
cat > "$tmp/new" <<'NEW'
Reviews only — does not write the code fix, does not approve/request-changes, does not run linters. Output the comment(s) ready to paste into the PR. "stop caveman-review" or "normal mode": revert to verbose review style.

## Not this one

`tiger-style-review` is the other terse review: same one-line shape and the same four severity prefixes, but it hunts Tiger Style safety and invariants with its own tag list. Use this one for comment voice on any diff; use that one for safety.
NEW
patch "$tmp/old" "$tmp/new"

touch "$MARK"
echo "overlay done: $SD"
