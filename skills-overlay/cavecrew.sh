#!/usr/bin/env bash
# cavecrew — this skill routes to cavecrew-investigator / -builder / -reviewer,
# whose definitions live only in the caveman repo's agents/ dir, outside the
# install. Ship the three files into ./agents/ and point the skill at them; the
# README's ../../agents/* links get upstream URLs instead, since prose should
# not depend on a copied file.
# Idempotent: cp only when the content differs, and each edit is grep-guarded.
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

for a in cavecrew-investigator cavecrew-builder cavecrew-reviewer; do
  src="$CLONE/caveman/agents/$a.md"
  [ -f "$src" ] || { echo "OVERLAY-WARN: missing $src"; continue; }
  mkdir -p agents
  cmp -s "$src" "agents/$a.md" || { cp "$src" "agents/$a.md"; echo "OVERLAY: agents/$a.md <- $src"; }
done

if [ -f SKILL.md ] && ! grep -qF './agents/cavecrew-investigator.md' SKILL.md; then
  sed -i 's|^What main thread can rely on per agent:$|What main thread can rely on per agent (definitions ship in `./agents/`):\n\n- [`cavecrew-investigator`](./agents/cavecrew-investigator.md)\n- [`cavecrew-builder`](./agents/cavecrew-builder.md)\n- [`cavecrew-reviewer`](./agents/cavecrew-reviewer.md)|' SKILL.md
  echo "OVERLAY: SKILL.md -> ./agents/*.md"
fi

fix_ref agents/cavecrew-investigator.md
fix_ref agents/cavecrew-builder.md
fix_ref agents/cavecrew-reviewer.md
fix_ref README.md

touch .overlay-applied
