#!/usr/bin/env bash
# ============================================================================
# jcode-update-all — ONE command to update everything, keep our custom bits.
#
#   Canonical location: ~/dotfiles/jcode/update-all.sh
#   (symlinked from ~/.jcode/bin/update-all.sh)
#
#   Updates:
#     1. jcode core   — fetch upstream (1jehuang/jcode), rebase our fork branch
#                       (local/turn-end-gate) onto upstream master, push to our
#                       fork (PremModhaOfficial/jcode = origin), build.
#     2. Skill sources — git pull ponytail, tiger-style, tuicr, babysitter,
#                       herdr; re-sync installed skills into ~/.agents/skills.
#     3. Regenerated skills — babysit keeps our jcode harness=pi adaptation;
#                       herdr is a plain sync.
#     4. Tools         — mise herdr, herdr-pickr plugin, babysitter SDK via npx
#                       (always latest), gopls best-effort.
#     5. Configs       — install dotfiles configs into live locations
#                       (~/.jcode, ~/.config/herdr, repo .a5c), then commit +
#                       push the dotfiles repo (PremModhaOfficial/dotfiles).
#     6. Skill manifest — ~/.agents/skills/README.md regenerated.
#
#   Preserved custom things: local/turn-end-gate jcode branch (in the fork),
#   pickr config.toml, herdr-agent-state.sh hook, babysitter-gate.sh hook,
#   .a5c/processes/* (babysitter processes), any skill in ~/.agents/skills/
#   with no upstream source listed below.
#
#   Usage:
#     ~/.jcode/bin/update-all.sh              # full update
#     ~/.jcode/bin/update-all.sh --dry-run    # show what would run
#     ~/.jcode/bin/update-all.sh --jcode-only
#     ~/.jcode/bin/update-all.sh --skills-only
#     ~/.jcode/bin/update-all.sh --tools-only
#     ~/.jcode/bin/update-all.sh --config-only
#
#   After it finishes: restart jcode (or reload skills) so the new skill list
#   takes effect, then run: jcode self-dev --reload  (if jcode itself updated).
# ============================================================================
set -uo pipefail

# --- config -----------------------------------------------------------------
HOME_DIR="$HOME"
JCODE_SRC="$HOME/.jcode/source/jcode"
SKILLS_DIR="$HOME/.agents/skills"
UPDATER_SRC="$HOME/.jcode/updater-src"          # git clones we own for skill sync
LOG_DIR="$HOME/.jcode/logs"
LOG="$LOG_DIR/update-all.log"
MANIFEST="$SKILLS_DIR/README.md"
DOTFILES="$HOME/dotfiles"
GATE_BRANCH="local/turn-end-gate"
JCODE_FORK="https://github.com/PremModhaOfficial/jcode.git"
JCODE_UPSTREAM="https://github.com/1jehuang/jcode.git"
UPDATER="${BASH_SOURCE[0]}"

mkdir -p "$LOG_DIR" "$UPDATER_SRC"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG"; }
fail() { log "ERROR: $*"; checklist_write 1; exit 1; }

DRY=0; DO_JCODE=1; DO_SKILLS=1; DO_TOOLS=1; DO_CONFIG=1
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --jcode-only) DO_SKILLS=0; DO_TOOLS=0; DO_CONFIG=0 ;;
    --skills-only) DO_JCODE=0; DO_TOOLS=0; DO_CONFIG=0 ;;
    --tools-only) DO_JCODE=0; DO_SKILLS=0; DO_CONFIG=0 ;;
    --config-only) DO_JCODE=0; DO_SKILLS=0; DO_TOOLS=0 ;;
    *) echo "unknown arg: $arg"; exit 2 ;;
  esac
done

# Per-run checklist ledger: appended to CHECKLIST.md in the skill folder so the
# skill (and the user) can see exactly what was done, and verify next time.
CHECKLIST_DIR="$SKILLS_DIR/update-all"
CHECKLIST="$CHECKLIST_DIR/CHECKLIST.md"
CHECKLIST_TMP="$LOG_DIR/checklist.tmp"

checklist_init() {
  mkdir -p "$CHECKLIST_DIR"
  : > "$CHECKLIST_TMP"
}
checklist_add() { # checklist_add <done|fail> <label>
  printf '%s\t%s\n' "$1" "$2" >> "$CHECKLIST_TMP"
}
checklist_write() {
  [ -f "$CHECKLIST_TMP" ] || return 0
  local total ok failc
  total=$(wc -l < "$CHECKLIST_TMP" | tr -d ' ')
  ok=$(grep -c '^done' "$CHECKLIST_TMP" || true)
  failc=$(grep -c '^fail' "$CHECKLIST_TMP" || true)
  {
    echo "## Update run — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
    echo "Summary: $ok/$total steps OK, $failc failed (exit: ${1:-0})"
    echo ""
    echo "| # | Step | Status |"
    echo "|---|------|--------|"
    local i=0
    while IFS=$'\t' read -r status label; do
      i=$((i+1))
      local mark="done"
      [ "$status" = "fail" ] && mark="fail"
      echo "| $i | $label | $mark |"
    done < "$CHECKLIST_TMP"
    echo ""
  } >> "$CHECKLIST"
  log "OK: checklist appended to $CHECKLIST"
}

run() { # run <label> <cmd...>
  local label="$1"; shift
  if [ "$DRY" = 1 ]; then log "DRY: $label — $*"; return 0; fi
  log "RUN: $label — $*"
  if "$@"; then log "OK:  $label"; checklist_add done "$label"; else
    log "WARN: $label exited $? (continuing)"
    checklist_add fail "$label"
  fi
}

# require() is like run() but FAILS THE WHOLE UPDATE on error. Used for the
# jcode core steps where continuing silently would corrupt the fork branch or
# claim success while doing nothing.
require() { # require <label> <cmd...>
  local label="$1"; shift
  if [ "$DRY" = 1 ]; then log "DRY: $label — $*"; return 0; fi
  log "RUN: $label — $*"
  if "$@"; then log "OK:  $label"; checklist_add done "$label"; else
    checklist_add fail "$label"
    fail "required step failed: $label (exited $?)"
  fi
}

# --- 1. jcode core (fork-based) --------------------------------------------
update_jcode() {
  log "=== jcode core (fork-based) ==="
  command -v cargo >/dev/null || fail "cargo not found"
  [ -d "$JCODE_SRC/.git" ] || fail "no jcode source at $JCODE_SRC (run: jcode self-dev --setup)"

  # Ensure remotes: origin = our fork (maintains our changes), upstream = jcode.
  local origin_url
  origin_url=$(git -C "$JCODE_SRC" remote get-url origin 2>/dev/null || true)
  if [ "$origin_url" != "$JCODE_FORK" ] && [ "$origin_url" != "git@github.com:PremModhaOfficial/jcode.git" ]; then
    run "set origin to fork" git -C "$JCODE_SRC" remote set-url origin "$JCODE_FORK"
  fi
  if ! git -C "$JCODE_SRC" remote get-url upstream >/dev/null 2>&1; then
    run "add upstream" git -C "$JCODE_SRC" remote add upstream "$JCODE_UPSTREAM"
  fi

  # Fetch latest from both. These are required: a stale fetch silently
  # rebases onto old upstream and force-pushes it to the fork.
  require "git fetch upstream" git -C "$JCODE_SRC" fetch upstream master
  require "git fetch origin" git -C "$JCODE_SRC" fetch origin

  # Rebase our feature branch onto upstream master.
  local current stash_applied=0
  current=$(git -C "$JCODE_SRC" branch --show-current)
  # A dirty tree blocks rebase even when already on the gate branch (e.g.
  # unrelated WIP in other crates). Stash unconditionally, pop after.
  if [ -n "$(git -C "$JCODE_SRC" status --porcelain)" ]; then
    log "stashing uncommitted jcode changes"
    git -C "$JCODE_SRC" stash push -m "update-all pre-rebase" || true
    stash_applied=1
  fi
  if [ "$current" != "$GATE_BRANCH" ]; then
    require "checkout $GATE_BRANCH" git -C "$JCODE_SRC" checkout "$GATE_BRANCH"
  fi

  # Rebase is required AND must not leave a rebase-in-progress state behind.
  # On conflict we abort and fail the whole update instead of force-pushing a
  # broken branch to the fork.
  if ! git -C "$JCODE_SRC" rebase upstream/master; then
    git -C "$JCODE_SRC" rebase --abort >/dev/null 2>&1 || true
    fail "rebase onto upstream/master conflicted; aborted (resolve manually on $GATE_BRANCH, then re-run)"
  fi
  log "OK:  rebase $GATE_BRANCH onto upstream/master"

  # Only push to the fork after a clean rebase (never a conflicted branch).
  require "push $GATE_BRANCH to fork" git -C "$JCODE_SRC" push -f origin "$GATE_BRANCH"

  # Return to the previous branch if we moved, then restore stashed changes.
  if [ -n "$current" ] && [ "$current" != "$GATE_BRANCH" ]; then
    require "checkout back to $current" git -C "$JCODE_SRC" checkout "$current"
  fi
  if [ "$stash_applied" = 1 ]; then
    log "re-applying stashed jcode changes"
    git -C "$JCODE_SRC" stash pop || true
  fi

  # Build the dev binary (required: the whole point is a fresh binary).
  require "cargo build jcode" cargo build --manifest-path "$JCODE_SRC/Cargo.toml" --bin jcode
  log "to run the updated jcode: jcode self-dev --reload  (or restart jcode)"
}

# --- 2. skill sources -------------------------------------------------------
skill_sources() {
  log "=== skill sources ==="
  declare -A sources=(
    ["ponytail"]="https://github.com/DietrichGebert/ponytail"
    ["caveman"]="https://github.com/JuliusBrussee/caveman"
    ["tiger-style"]="https://github.com/PremModhaOfficial/tiger-style"
    ["tuicr"]="https://github.com/agavra/tuicr"
    ["babysitter"]="https://github.com/a5c-ai/babysitter"
    ["herdr"]="https://github.com/herdrdev/herdr"
  )
  for name in "${!sources[@]}"; do
    local url="${sources[$name]}"
    local dir="$UPDATER_SRC/$name"
    if [ -d "$dir/.git" ]; then
      run "pull $name" git -C "$dir" pull --ff-only
    else
      run "clone $name" git clone --depth 1 "$url" "$dir"
    fi
  done

  # Refresh the babysitter process library too (created by the babysitter CLI).
  local plib="$HOME/.a5c/process-library/babysitter-repo"
  if [ -d "$plib/.git" ]; then
    run "pull babysitter process library" git -C "$plib" pull --ff-only
  fi
}

# --- 3. sync skills ---------------------------------------------------------
sync_dir() { # sync_dir <src> <dst>
  local src="$1" dst="$2"
  [ -d "$src" ] || { log "skip (missing): $src"; return; }
  mkdir -p "$dst"
  if [ "$DRY" = 1 ]; then log "DRY: sync $src -> $dst"; return; fi
  cp -R "$src/." "$dst/"
  log "OK: sync $src -> $dst"
}

sync_skills() {
  log "=== skill sync ==="
  # ponytail family (ponytail + audits)
  sync_dir "$UPDATER_SRC/ponytail/skills/ponytail"        "$SKILLS_DIR/ponytail"
  sync_dir "$UPDATER_SRC/ponytail/skills/ponytail-audit"  "$SKILLS_DIR/ponytail-audit"
  sync_dir "$UPDATER_SRC/ponytail/skills/ponytail-debt"   "$SKILLS_DIR/ponytail-debt"
  sync_dir "$UPDATER_SRC/ponytail/skills/ponytail-gain"   "$SKILLS_DIR/ponytail-gain"
  sync_dir "$UPDATER_SRC/ponytail/skills/ponytail-help"   "$SKILLS_DIR/ponytail-help"
  sync_dir "$UPDATER_SRC/ponytail/skills/ponytail-review" "$SKILLS_DIR/ponytail-review"
  # caveman + friends (now its own repo: JuliusBrussee/caveman)
  sync_dir "$UPDATER_SRC/caveman/skills/caveman"         "$SKILLS_DIR/caveman"
  sync_dir "$UPDATER_SRC/caveman/skills/caveman-commit"  "$SKILLS_DIR/caveman-commit"
  sync_dir "$UPDATER_SRC/caveman/skills/caveman-compress" "$SKILLS_DIR/caveman-compress"
  sync_dir "$UPDATER_SRC/caveman/skills/caveman-help"    "$SKILLS_DIR/caveman-help"
  sync_dir "$UPDATER_SRC/caveman/skills/caveman-review"  "$SKILLS_DIR/caveman-review"
  sync_dir "$UPDATER_SRC/caveman/skills/caveman-stats"   "$SKILLS_DIR/caveman-stats"
  sync_dir "$UPDATER_SRC/caveman/skills/cavecrew"        "$SKILLS_DIR/cavecrew"

  # tiger-style family
  sync_dir "$UPDATER_SRC/tiger-style/skills/tiger-style"        "$SKILLS_DIR/tiger-style"
  sync_dir "$UPDATER_SRC/tiger-style/skills/tiger-style-audit"  "$SKILLS_DIR/tiger-style-audit"
  sync_dir "$UPDATER_SRC/tiger-style/skills/tiger-style-commit" "$SKILLS_DIR/tiger-style-commit"
  sync_dir "$UPDATER_SRC/tiger-style/skills/tiger-style-help"   "$SKILLS_DIR/tiger-style-help"
  sync_dir "$UPDATER_SRC/tiger-style/skills/tiger-style-review" "$SKILLS_DIR/tiger-style-review"

  # tuicr skill (has herdr wrappers)
  sync_dir "$UPDATER_SRC/tuicr/skills/tuicr" "$SKILLS_DIR/tuicr"

  # herdr skill (plain upstream copy)
  sync_dir "$UPDATER_SRC/herdr/skills/herdr" "$SKILLS_DIR/herdr"

  # babysit — REGENERATED with our jcode adaptation preserved
  regenerate_babysit
}

regenerate_babysit() {
  log "=== babysit (regenerated, custom jcode adaptation preserved) ==="
  local src_skill="$UPDATER_SRC/babysitter/plugins/babysitter-unified/skills/babysit/SKILL.md"
  [ -f "$src_skill" ] || { log "skip: upstream babysit SKILL.md missing"; return; }
  local dst="$SKILLS_DIR/babysit"
  mkdir -p "$dst"
  local out="$dst/SKILL.md"
  if [ "$DRY" = 1 ]; then log "DRY: regenerate $dst from $src_skill"; return; fi

  sed -e 's|^SDK_VERSION=.*$|SDK_VERSION=latest|' \
      -e 's|{{harness}}|pi|g' \
      "$src_skill" > "$out"

  if ! grep -q "jcode harness note" "$out"; then
    cat >> "$out" <<'EOF'

> **jcode harness note:** jcode does not implement Claude Code's Stop/PreToolUse
> hook protocol, so Babysitter runs in **non-hook-driven continuation** mode:
> keep driving the orchestration loop inside the current turn until the run
> completes or a real user breakpoint requires chat input. Do not yield the turn
> and wait for a Stop hook that will never come.
EOF
  fi
  log "OK: regenerated $dst (harness=pi, jcode note appended)"
}

# --- 4. tools ---------------------------------------------------------------
update_tools() {
  log "=== tools ==="
  if command -v mise >/dev/null; then
    run "mise herdr latest" mise install herdr@latest
    run "mise use herdr@latest" mise use -g herdr@latest
  fi
  if command -v herdr >/dev/null; then
    run "herdr plugin reinstall pickr" herdr plugin install tomasvarga/herdr-pickr -y
  fi
  if command -v node >/dev/null; then
    # The babysitter CLI is consumed via `npm exec --package @a5c-ai/babysitter-sdk@latest`
    # at runtime (documented fallback; no global install). This step VERIFIES the
    # latest SDK resolves — it does not install anything.
    run "babysitter SDK verify (npx always-latest)" node -e "require('child_process').execSync('npm exec --yes --package @a5c-ai/babysitter-sdk@latest -- babysitter --version', {stdio:'inherit'})"
  fi
  if command -v go >/dev/null; then
    run "gopls latest" go install golang.org/x/tools/gopls@latest
  fi
}

# install_if_different installs src -> dst, skipping silently when they are the
# same file (e.g. dst is a symlink into src) so the step is a true no-op, not a
# confusing cp failure.
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

# --- 5. configs: dotfiles -> live, then commit + push dotfiles --------------
sync_configs() {
  log "=== configs (dotfiles -> live, then push dotfiles) ==="
  [ -d "$DOTFILES/.git" ] || { log "skip: no dotfiles repo at $DOTFILES"; return; }

  # Keep dotfiles itself up to date with any remote changes (other machines).
  # Pull the actual checked-out branch (dotfiles uses `wrk`), not `origin HEAD`
  # which resolves to the remote's default branch and diverges.
  local df_branch df_pull_ok=1
  df_branch=$(git -C "$DOTFILES" branch --show-current 2>/dev/null || echo "wrk")
  if [ "$DRY" = 1 ]; then
    log "DRY: git pull dotfiles ($df_branch)"
  elif ( cd "$DOTFILES" && git fetch origin && git pull --ff-only origin "$df_branch" ) >> "$LOG" 2>&1; then
    log "OK:  dotfiles pulled ($df_branch)"
  else
    log "WARN: dotfiles pull failed (continuing with local state)"
    df_pull_ok=0
  fi

  # jcode config + hooks (symlink-safe install)
  if [ -f "$DOTFILES/jcode/.jcode/config.toml" ]; then
    install_if_different "$DOTFILES/jcode/.jcode/config.toml" "$HOME/.jcode/config.toml"
  fi
  if [ -d "$DOTFILES/jcode/.jcode/hooks" ]; then
    for hook in "$DOTFILES/jcode/.jcode/hooks/"*.sh; do
      [ -f "$hook" ] || continue
      install_if_different "$hook" "$HOME/.jcode/hooks/$(basename "$hook")"
    done
    chmod +x "$HOME/.jcode/hooks/"*.sh 2>/dev/null || true
  fi

  # jcode theme switcher + presets (bin + themes)
  if [ -f "$DOTFILES/jcode/bin/jcode-theme" ]; then
    mkdir -p "$HOME/.jcode/bin"
    install_if_different "$DOTFILES/jcode/bin/jcode-theme" "$HOME/.jcode/bin/jcode-theme"
    chmod +x "$HOME/.jcode/bin/jcode-theme" 2>/dev/null || true
  fi
  if [ -d "$DOTFILES/jcode/themes" ]; then
    mkdir -p "$HOME/.jcode/themes"
    for t in "$DOTFILES/jcode/themes/"*.toml; do
      [ -f "$t" ] || continue
      install_if_different "$t" "$HOME/.jcode/themes/$(basename "$t")"
    done
  fi

  # herdr theme switcher + presets (live under ~/.config/herdr with herdr's config)
  if [ -f "$DOTFILES/herdr/bin/herdr-theme" ]; then
    mkdir -p "$HOME/.config/herdr/bin"
    install_if_different "$DOTFILES/herdr/bin/herdr-theme" "$HOME/.config/herdr/bin/herdr-theme"
    chmod +x "$HOME/.config/herdr/bin/herdr-theme" 2>/dev/null || true
  fi
  if [ -d "$DOTFILES/herdr/themes" ]; then
    mkdir -p "$HOME/.config/herdr/themes"
    for t in "$DOTFILES/herdr/themes/"*.toml; do
      [ -f "$t" ] || continue
      install_if_different "$t" "$HOME/.config/herdr/themes/$(basename "$t")"
    done
  fi

  # herdr config (only the pickr config we maintain)
  if [ -f "$DOTFILES/herdr/plugins/config/pickr/config.toml" ]; then
    run "install pickr config" mkdir -p "$HOME/.config/herdr/plugins/config/pickr"
    install_if_different "$DOTFILES/herdr/plugins/config/pickr/config.toml" "$HOME/.config/herdr/plugins/config/pickr/config.toml"
  fi

  # babysitter processes (custom .a5c processes) — install into the current repo
  # and the global ~/.a5c/processes so babysitter can find them anywhere.
  if [ -d "$DOTFILES/babysitter/processes" ]; then
    if [ -d ".a5c/processes" ]; then
      run "install babysitter processes (repo)" cp -R "$DOTFILES/babysitter/processes/." ".a5c/processes/"
    fi
    mkdir -p "$HOME/.a5c/processes"
    run "install babysitter processes (global)" cp -R "$DOTFILES/babysitter/processes/." "$HOME/.a5c/processes/"
  fi

  # Commit + push the dotfiles repo. We ONLY push the paths this updater owns
  # (never `git add -A`, which sweeps in unrelated edits and nested git repos).
  # And we only push if the ff-only pull above succeeded, so we never overwrite
  # remote commits we failed to merge.
  if [ "$DRY" = 1 ]; then log "DRY: commit+push dotfiles"; return; fi
  if [ "$df_pull_ok" = 1 ]; then
    ( cd "$DOTFILES" \
      && git add jcode/ babysitter/ \
      && git add -f herdr/.config/herdr/plugins/config/pickr \
      && git -c user.name="prem-modha" -c user.email="prem-modha@users.noreply.github.com" \
           commit -m "update-all: sync configs/skills/updater" --allow-empty \
      && git push origin HEAD ) >> "$LOG" 2>&1 \
    && log "OK: dotfiles committed + pushed" \
    || log "WARN: dotfiles commit/push failed (see log)"
  else
    log "WARN: skipping dotfiles push (pull failed; remote may have commits we did not merge)"
  fi
}

# --- 6. self-review: run ponytail + tiger-style on the new code -------------
self_review() {
  log "=== self-review (ponytail + tiger-style on new code) ==="
  local review_dir="$SKILLS_DIR"
  local review_out="$LOG_DIR/self-review"
  mkdir -p "$review_out"

  # REVIEW_SOURCE: point reviewers at the jcode feature diff + the updater.
  # The ponytail/tiger skills read SKILL.md instructions; we invoke them via
  # the skill loader, but the review targets are concrete files, so we record
  # them here for the checklist and run what's scriptable.
  local targets=(
    "$JCODE_SRC/crates/jcode-base/src/hooks.rs"
    "$JCODE_SRC/crates/jcode-app-core/src/server/client_lifecycle.rs"
    "$JCODE_SRC/crates/jcode-app-core/src/agent/turn_execution.rs"
    "$JCODE_SRC/crates/jcode-config-types/src/lib.rs"
    "$UPDATER"
  )

  # Scriptable summary: line counts + TODO/debt markers for the changed files
  # (the real review is done by the skills when invoked; this keeps a record).
  if [ "$DRY" = 1 ]; then
    log "DRY: self-review would inspect ${#targets[@]} files"
    return 0
  fi
  {
    echo "# Self-review — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
    echo "Targets:"
    for t in "${targets[@]}"; do
      if [ -f "$t" ]; then
        echo "- $t ($(wc -l < "$t") lines)"
      else
        echo "- $t (missing)"
      fi
    done
    echo ""
    echo "Debt markers (ponytail: TODO/FIXME/XXX):"
    grep -rn "TODO\|FIXME\|XXX\|HACK" "${targets[@]}" 2>/dev/null | head -10 || echo "(none)"
    echo ""
    echo "Explicit limits (tiger-style: const/assert):"
    grep -rn "const .* = \|assert" "${targets[@]}" 2>/dev/null | head -10 || echo "(none)"
    echo ""
  } > "$review_out/$(date -u +%Y%m%dT%H%M%SZ).md"
  log "OK: self-review record written to $review_out"
  log "note: for full ponytail/tiger review, invoke /ponytail-review and /tiger-style-review on: ${targets[*]}"
}

# --- 7. manifest ------------------------------------------------------------
write_manifest() {
  log "=== skill manifest ==="
  local out="$MANIFEST"
  local tmp="$out.tmp"
  {
    echo "# Installed Agent Skills"
    echo ""
    echo "Regenerated by \`~/.jcode/bin/update-all.sh\` on $(date -u +%Y-%m-%dT%H:%M:%SZ)."
    echo "Run \`~/.jcode/bin/update-all.sh\` to refresh everything."
    echo ""
    echo "| Skill | Source | Source commit |"
    echo "|-------|--------|---------------|"
    local commit
    for dir in "$SKILLS_DIR"/*/; do
      [ -f "$dir/SKILL.md" ] || continue
      local name
      name=$(basename "$dir")
      local source="bundled/manual"
      local repo=""
      case "$name" in
        babysit)        source="a5c-ai/babysitter (custom harness=pi)"; repo="$UPDATER_SRC/babysitter" ;;
        herdr)          source="herdrdev/herdr"; repo="$UPDATER_SRC/herdr" ;;
        tuicr)          source="agavra/tuicr"; repo="$UPDATER_SRC/tuicr" ;;
        ponytail*|compress) source="DietrichGebert/ponytail"; repo="$UPDATER_SRC/ponytail" ;;
        caveman*|cavecrew) source="JuliusBrussee/caveman"; repo="$UPDATER_SRC/caveman" ;;
        tiger-style*)   source="PremModhaOfficial/tiger-style"; repo="$UPDATER_SRC/tiger-style" ;;
      esac
      commit="—"
      if [ -n "$repo" ] && [ -d "$repo/.git" ]; then
        commit=$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || echo "—")
      fi
      echo "| $name | $source | $commit |"
    done
  } > "$tmp"
  if [ "$DRY" = 1 ]; then log "DRY: manifest -> $out"; rm -f "$tmp"; return; fi
  mv "$tmp" "$out"
  log "OK: manifest written to $out ($(grep -c '^| ' "$out" | awk '{print $1-2}') skills)"
}

# --- main -------------------------------------------------------------------
log "=============================================="
log "update-all started (dry_run=$DRY)"
checklist_init
[ "$DO_JCODE" = 1 ]   && update_jcode
[ "$DO_SKILLS" = 1 ] && { skill_sources; sync_skills; }
[ "$DO_TOOLS" = 1 ]  && update_tools
[ "$DO_CONFIG" = 1 ] && sync_configs
[ "$DO_JCODE" = 1 ]  && self_review
[ "$DO_SKILLS" = 1 ] && write_manifest
checklist_write
log "update-all finished — restart jcode (or reload skills) to pick up the new list."
log "next: jcode self-dev --reload   (if jcode core was rebuilt)"
log "checklist: $CHECKLIST"
log "=============================================="
