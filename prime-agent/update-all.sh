#!/usr/bin/env bash
# ============================================================================
# prime-agent-update-all — sync prime-agent dotfiles into the live agent dir
# (~/.prime/agent) and push the prime-agent/ paths in the dotfiles repo.
#
#   Canonical location: ~/dotfiles/prime-agent/update-all.sh
#   (symlinked from ~/.prime/agent/bin/update-all.sh)
#
#   Syncs:
#     1. Themes — dotfiles/prime-agent/themes/*.json -> ~/.prime/agent/themes/
#                 (fluoromachine flavors: delta, fluoromachine, retrowave)
#     2. Dotfiles repo — commit + push ONLY the prime-agent/ path.
#
#   Kept separate from jcode/update-all.sh on purpose: prime-agent dotfiles
#   have their own lifecycle and should not ride along with jcode's updater.
#
#   Usage:
#     ~/.prime/agent/bin/update-all.sh             # install + commit + push
#     ~/.prime/agent/bin/update-all.sh --dry-run   # show what would run
# ============================================================================
set -uo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
LOG_DIR="$HOME/.prime/agent/logs"
LOG="$LOG_DIR/prime-agent-update-all.log"
mkdir -p "$LOG_DIR"

DRY=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG"; }

install_if_different() { # install_if_different <src> <dst>
  local src="$1" dst="$2"
  if [ "$DRY" = 1 ]; then log "DRY: install $src -> $dst"; return 0; fi
  local rs ds
  rs=$(readlink -f "$src" 2>/dev/null || echo "$src")
  ds=$(readlink -f "$dst" 2>/dev/null || echo "$dst")
  if [ "$rs" = "$ds" ]; then
    log "OK:  install $dst (already in place)"
    return 0
  fi
  if cp "$src" "$dst"; then log "OK:  install $src -> $dst"; else log "WARN: install $src -> $dst failed"; fi
}

log "=== prime-agent dotfiles sync ==="
[ -d "$DOTFILES/.git" ] || { log "skip: no dotfiles repo at $DOTFILES"; exit 0; }

# Keep dotfiles up to date with any remote changes (other machines).
df_branch=$(git -C "$DOTFILES" branch --show-current 2>/dev/null || echo "wrk")
df_pull_ok=1
if [ "$DRY" = 1 ]; then
  log "DRY: git pull dotfiles ($df_branch)"
elif ( cd "$DOTFILES" && git fetch origin && git pull --ff-only origin "$df_branch" ) >> "$LOG" 2>&1; then
  log "OK:  dotfiles pulled ($df_branch)"
else
  log "WARN: dotfiles pull failed (continuing with local state)"
  df_pull_ok=0
fi

# Themes: dotfiles/prime-agent/themes -> ~/.prime/agent/themes
if [ -d "$DOTFILES/prime-agent/themes" ]; then
  mkdir -p "$HOME/.prime/agent/themes"
  for t in "$DOTFILES/prime-agent/themes/"*.json; do
    [ -f "$t" ] || continue
    install_if_different "$t" "$HOME/.prime/agent/themes/$(basename "$t")"
  done
fi

# Commit + push the dotfiles repo. Only push the paths this updater owns
# (never `git add -A`), and only if the ff-only pull succeeded.
if [ "$DRY" = 1 ]; then log "DRY: commit+push dotfiles (prime-agent/)"; exit 0; fi
if [ "$df_pull_ok" = 1 ]; then
  ( cd "$DOTFILES" \
    && git add prime-agent/ \
    && git -c user.name="prem-modha" -c user.email="prem-modha@users.noreply.github.com" \
         commit -m "prime-agent: sync themes" --allow-empty \
    && git push origin HEAD ) >> "$LOG" 2>&1 \
  && log "OK: dotfiles committed + pushed (prime-agent/)" \
  || log "WARN: dotfiles commit/push failed (see log)"
else
  log "WARN: skipping dotfiles push (pull failed; remote may have commits we did not merge)"
fi
