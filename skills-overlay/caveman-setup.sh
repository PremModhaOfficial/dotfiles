#!/usr/bin/env bash
# caveman-setup — two dead doc pointers in SKILL.md:
#   docs/integrations/        does not exist upstream; the per-framework recipes
#                             live at integrations/recipes/ in the repo, so point
#                             at that URL.
#   docs/discover-workflows.md exists nowhere, so it cannot be linked: reworded
#                             to run the installed caveman-discover skill.
# Idempotent: each sed only matches the unpatched text.
# Contract: see apply_overlays() in ~/dotfiles/jcode/update-all.sh.
set -uo pipefail

if [ -f SKILL.md ] && grep -qF 'page under `<docs origin>/docs/integrations/`' SKILL.md; then
  sed -i '\|page under `<docs origin>/docs/integrations/`|,+1c\
fetch the matching recipe in the repo (https://github.com/JuliusBrussee/caveman/tree/main/integrations/recipes) and follow it.' SKILL.md
  echo "OVERLAY: SKILL.md docs/integrations/ -> repo integrations/recipes/ URL"
fi

if [ -f SKILL.md ] && grep -qF 'fetch <docs origin>/docs/discover-workflows.md' SKILL.md; then
  sed -i 's|fetch <docs origin>/docs/discover-workflows.md|run the `caveman-discover` skill|' SKILL.md
  echo "OVERLAY: SKILL.md dead docs/discover-workflows.md -> caveman-discover skill"
fi

touch .overlay-applied
