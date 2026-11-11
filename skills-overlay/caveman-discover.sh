#!/usr/bin/env bash
# caveman-discover — SKILL.md points at `<docs origin>/docs/agent-setup.md`,
# which is not in the repo and so never in the install either. Reworded to name
# the installed setup skill instead, keeping the same instruction.
# Idempotent: the sed only matches the dead pointer.
# Contract: see apply_overlays() in ~/dotfiles/jcode/update-all.sh.
set -uo pipefail

if [ -f SKILL.md ] && grep -qF 'setup skill (`<docs origin>/docs/agent-setup.md`)' SKILL.md; then
  sed -i 's|setup skill (`<docs origin>/docs/agent-setup.md`) instead of manufacturing a|setup skill (`caveman-setup`) instead of manufacturing a|' SKILL.md
  echo "OVERLAY: SKILL.md dead docs/agent-setup.md -> caveman-setup skill"
fi

touch .overlay-applied
