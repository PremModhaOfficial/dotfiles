#!/usr/bin/env bash
# ============================================================================
# pi-root.sh — resolve the installed pi package root, in one place.
#
#   Source this; do not copy the candidate list.
#
#   What it replaces: a hardcoded
#   $HOME/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent
#   in apply-pi-patches.sh and compaction-escape.test.sh. That path is only
#   correct when pi was installed with the default npm-global prefix; with nvm,
#   pnpm, /usr/local or a distro package the patch step failed and took the
#   config phase down with it. Ask npm where its global root is instead, and
#   fall back to the common prefixes.
#
#   PI_ROOT still wins when set, so an override is never ignored.
#   Exit/return codes: 0 found (path echoed), 1 not found (candidates echoed to
#   stderr so the caller can print them).
# ============================================================================

PI_PKG="@earendil-works/pi-coding-agent"

pi_root_candidates() {
  if [ -n "${PI_ROOT:-}" ]; then
    printf '%s\n' "$PI_ROOT"
    return 0
  fi
  local root
  {
    if command -v npm >/dev/null 2>&1; then
      root=$(npm root -g 2>/dev/null || true)
      [ -n "$root" ] && printf '%s\n' "$root/$PI_PKG"
    fi
    printf '%s\n' \
      "$HOME/.npm-global/lib/node_modules/$PI_PKG" \
      "/usr/local/lib/node_modules/$PI_PKG" \
      "/usr/lib/node_modules/$PI_PKG"
    # npm's global root is often the same as the first fallback; one line per
    # distinct path keeps the "tried:" message readable.
  } | awk 'NF && !seen[$0]++'
}

resolve_pi_root() { # echoes the first existing candidate
  local c
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    if [ -d "$c" ]; then
      printf '%s\n' "$c"
      return 0
    fi
  done <<EOF
$(pi_root_candidates)
EOF
  return 1
}
