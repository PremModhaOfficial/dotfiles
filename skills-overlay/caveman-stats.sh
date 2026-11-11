#!/usr/bin/env bash
# caveman-stats — the README links up to the repo root (../../) and the SKILL.md
# names the repo's own hook/methodology files, none of which are installed.
# Point the README links and those bare paths at their upstream URLs; sed only
# matches the unpatched form, so a second run changes nothing.
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

link() { # link <repo-relative-path>: wrap the backticked path in an upstream link
  local p esc url
  p="$1"
  url="https://github.com/JuliusBrussee/caveman/blob/main/$p"
  [ -f SKILL.md ] || { echo "OVERLAY-WARN: no SKILL.md in $SKILL_DIR"; return 0; }
  grep -qF "($url)" SKILL.md && return 0
  esc=$(printf '%s' "$p" | sed 's/[.[*^$\\]/\\&/g')
  sed -i "s|\`$esc\`|[\`$p\`]($url)|g" SKILL.md || return 1
  echo "OVERLAY: SKILL.md \`$p\` -> upstream URL"
}

fix_ref docs/HONEST-NUMBERS.md
fix_ref README.md
link src/hooks/caveman-mode-tracker.js
link src/hooks/caveman-stats.js
link docs/HONEST-NUMBERS.md

touch .overlay-applied
