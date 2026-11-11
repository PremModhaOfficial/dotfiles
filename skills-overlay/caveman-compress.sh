#!/usr/bin/env bash
# caveman-compress — README links up to the repo root (../../), which is outside the
# install. Rewrite them to their upstream URLs; sed only matches the relative
# form, so a second run changes nothing.
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

fix_ref tests/caveman-compress/
fix_ref docs/assets/dancing-rock.svg

touch .overlay-applied
