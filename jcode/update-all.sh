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
#                       fork only after a successful build, with an explicit lease.
#     2. Skill sources — git pull ponytail, tiger-style, tuicr, babysitter,
#                       herdr; re-sync installed skills into ~/.agents/skills.
#     3. Regenerated skills — babysit keeps our jcode harness=jcode adaptation;
#                       herdr is a plain sync.
#     4. Tools         — mise herdr, herdr-pickr plugin, babysitter SDK via npx
#                       (always latest), gopls best-effort.
#     5. Configs       — install dotfiles configs into live locations
#                       (~/.jcode, ~/.config/herdr, repo .a5c). Preserve divergent
#                       live config and dirty dotfiles; never stage user changes.
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
#     ~/.jcode/bin/update-all.sh --parallel   # independent phases and sources
#     ~/.jcode/bin/update-all.sh --context    # fast, read-only context pointers
#
#   After it finishes: restart jcode (or reload skills) so the new skill list
#   takes effect, then run: jcode self-dev --reload  (if jcode itself updated).
# ============================================================================

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

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG"; }
fail() { log "ERROR: $*"; checklist_add fail "$*"; exit 1; }

DRY=0; PARALLEL=0; DO_JCODE=1; DO_SKILLS=1; DO_TOOLS=1; DO_CONFIG=1
parse_args() {
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --parallel) PARALLEL=1 ;;
    --context) show_context; return 2 ;;
    --jcode-only) DO_SKILLS=0; DO_TOOLS=0; DO_CONFIG=0 ;;
    --skills-only) DO_JCODE=0; DO_TOOLS=0; DO_CONFIG=0 ;;
    --tools-only) DO_JCODE=0; DO_SKILLS=0; DO_CONFIG=0 ;;
    --config-only) DO_JCODE=0; DO_SKILLS=0; DO_TOOLS=0 ;;
    *) echo "unknown arg: $arg" >&2; return 1 ;;
  esac
done
}

# Per-run checklist ledger: appended to CHECKLIST.md in the skill folder so the
# skill (and the user) can see exactly what was done, and verify next time.
CHECKLIST_DIR="$SKILLS_DIR/update-all"
CHECKLIST="$CHECKLIST_DIR/CHECKLIST.md"
CHECKLIST_TMP="$LOG_DIR/checklist.tmp"

checklist_init() {
  mkdir -p "$(dirname "$CHECKLIST_TMP")"
  : > "$CHECKLIST_TMP"
}
checklist_add() { # checklist_add <done|fail> <label>
  printf '%s\t%s\n' "$1" "$2" >> "$CHECKLIST_TMP"
}
checklist_write() {
  [ -f "$CHECKLIST_TMP" ] || return 0
  local total ok failc skipped
  total=$(wc -l < "$CHECKLIST_TMP" | tr -d ' ')
  ok=$(grep -c '^done' "$CHECKLIST_TMP" || true)
  failc=$(grep -c '^fail' "$CHECKLIST_TMP" || true)
  skipped=$(grep -c '^skip' "$CHECKLIST_TMP" || true)
  {
    echo "## Update run — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
    echo "Summary: $ok/$total steps OK, $failc failed, $skipped skipped (exit: ${1:-0})"
    echo ""
    echo "| # | Step | Status |"
    echo "|---|------|--------|"
    local i=0
    while IFS=$'\t' read -r status label; do
      i=$((i+1))
      local mark="done"
      mark="$status"
      echo "| $i | $label | $mark |"
    done < "$CHECKLIST_TMP"
    echo ""
  } >> "$CHECKLIST"
  log "OK: checklist appended to $CHECKLIST"
}

run() { # run <label> <cmd...>
  local label="$1"; shift
  if [ "$DRY" = 1 ]; then log "DRY: $label — $*"; checklist_add skip "$label (dry-run)"; return 0; fi
  log "RUN: $label — $*"
  if "$@"; then log "OK:  $label"; checklist_add done "$label"; else
    local rc=$?
    log "ERROR: $label exited $rc"
    checklist_add fail "$label"
    return "$rc"
  fi
}

# require() is like run() but FAILS THE WHOLE UPDATE on error. Used for the
# jcode core steps where continuing silently would corrupt the fork branch or
# claim success while doing nothing.
require() { # require <label> <cmd...>
  run "$@" || exit "$?"
}

# Each child owns its log/ledger. Merge only after waiting, including failures.
# Launch even serial work as a child so errexit is not disabled by an if test.
run_jobs() {
  local dir name pid rc=0 i=0
  local -a pids=() names=()
  dir=$(mktemp -d "$RUN_DIR/jobs.XXXXXX")
  for name in "$@"; do
    names+=("$name")
    (
      set -euo pipefail
      LOG="$dir/$i.log"; CHECKLIST_TMP="$dir/$i.tsv"
      : > "$LOG"; : > "$CHECKLIST_TMP"
      "$name"
    ) > "$dir/$i.output" 2>&1 &
    pid=$!; pids+=("$pid")
    if [ "$PARALLEL" = 0 ]; then wait "$pid" || rc=1; fi
    i=$((i+1))
  done
  for i in "${!pids[@]}"; do
    if wait "${pids[$i]}"; then
      checklist_add done "phase ${names[$i]}"
    else
      checklist_add fail "phase ${names[$i]}"; rc=1
    fi
    cat "$dir/$i.tsv" >> "$CHECKLIST_TMP"
    cat "$dir/$i.log" >> "$LOG"
    cat "$dir/$i.output"
  done
  return "$rc"
}

# --- 1. jcode core (fork-based) --------------------------------------------
update_jcode() {
  log "=== jcode core (fork-based) ==="
  if [ "$DRY" = 1 ]; then
    log "DRY: require clean core, fetch, rebase $GATE_BRANCH, build, then push with lease"
    checklist_add skip "core (dry-run, no git/cargo executed)"
    return 0
  fi
  command -v cargo >/dev/null || fail "cargo not found"
  [ -d "$JCODE_SRC/.git" ] || fail "no jcode source at $JCODE_SRC (run: jcode self-dev --setup)"
  [ -z "$(git -C "$JCODE_SRC" status --porcelain)" ] || fail "core is dirty; preserve changes and resolve manually before updating"

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

  # Never stash/reset user work. Refuse an unfinished operation too.
  local current lease
  current=$(git -C "$JCODE_SRC" branch --show-current)
  [ -n "$current" ] || fail "core has detached HEAD"
  [ ! -d "$JCODE_SRC/.git/rebase-merge" ] && [ ! -d "$JCODE_SRC/.git/rebase-apply" ] && [ ! -f "$JCODE_SRC/.git/MERGE_HEAD" ] || fail "core has an unfinished merge/rebase"
  lease=$(git -C "$JCODE_SRC" rev-parse "refs/remotes/origin/$GATE_BRANCH") || fail "fork gate branch missing"
  if [ "$current" != "$GATE_BRANCH" ]; then
    require "checkout $GATE_BRANCH" git -C "$JCODE_SRC" checkout "$GATE_BRANCH"
  fi

  # Rebase is required AND must not leave a rebase-in-progress state behind.
  # On conflict we abort and fail the whole update instead of force-pushing a
  # broken branch to the fork.
  if ! git -C "$JCODE_SRC" -c rebase.autoStash=false rebase upstream/master; then
    git -C "$JCODE_SRC" rebase --abort >/dev/null 2>&1 || true
    [ "$current" = "$GATE_BRANCH" ] || git -C "$JCODE_SRC" checkout "$current"
    fail "rebase onto upstream/master conflicted; aborted (resolve manually on $GATE_BRANCH, then re-run)"
  fi
  log "OK:  rebase $GATE_BRANCH onto upstream/master"

  # Build the rebased gate branch before publishing, not the previous branch.
  local rc=0
  run "cargo build jcode" cargo build --manifest-path "$JCODE_SRC/Cargo.toml" --bin jcode || rc=1
  if [ "$rc" = 0 ]; then
    run "push $GATE_BRANCH to fork" git -C "$JCODE_SRC" push "--force-with-lease=refs/heads/$GATE_BRANCH:$lease" origin "$GATE_BRANCH" || rc=1
  fi
  if [ -n "$current" ] && [ "$current" != "$GATE_BRANCH" ]; then
    require "checkout back to $current" git -C "$JCODE_SRC" checkout "$current"
  fi
  log "to run the updated jcode: jcode self-dev --reload  (or restart jcode)"
  return "$rc"
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
  local name
  local -a jobs=()
  for name in "${!sources[@]}"; do
    jobs+=("pull_$name")
    # Names and URLs are fixed literals above, never user input.
    eval "pull_$name() { pull_skill '$name' '${sources[$name]}'; }"
  done
  local plib="$HOME/.a5c/process-library/babysitter-repo"
  if [ -d "$plib/.git" ]; then jobs+=(pull_process_library); fi
  run_jobs "${jobs[@]}"
}

pull_skill() {
    local name="$1" url="$2"
    local dir="$UPDATER_SRC/$name"
    if [ -d "$dir/.git" ]; then
      run "pull $name" git -C "$dir" -c pull.rebase=false -c merge.autoStash=false pull --ff-only
    else
      run "clone $name" git clone --depth 1 "$url" "$dir"
    fi
}
pull_process_library() {
  local plib="$HOME/.a5c/process-library/babysitter-repo"
  run "pull babysitter process library" git -C "$plib" -c pull.rebase=false -c merge.autoStash=false pull --ff-only
}

# --- 3. sync skills ---------------------------------------------------------
sync_dir() { # sync_dir <src> <dst>
  local src="$1" dst="$2"
  if [ "$DRY" = 1 ]; then log "DRY: sync $src -> $dst"; return 0; fi
  [ -d "$src" ] || { log "ERROR (missing): $src"; checklist_add fail "sync $src (missing)"; return 1; }
  if [ "$DRY" = 1 ]; then log "DRY: sync $src -> $dst"; return; fi
  mkdir -p "$dst"
  cp -R "$src/." "$dst/"
  log "OK: sync $src -> $dst"
  checklist_add done "sync $(basename "$dst")"
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
  if [ "$DRY" = 1 ]; then log "DRY: regenerate babysit from $src_skill"; return 0; fi
  [ -f "$src_skill" ] || fail "upstream babysit SKILL.md missing"
  local dst="$SKILLS_DIR/babysit"
  mkdir -p "$dst"
  local out="$dst/SKILL.md"
  if [ "$DRY" = 1 ]; then log "DRY: regenerate $dst from $src_skill"; return; fi

  sed -e 's|^SDK_VERSION=.*$|SDK_VERSION=latest|' \
      -e 's|{{harness}}|jcode|g' \
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
  log "OK: regenerated $dst (harness=jcode, jcode note appended)"
  checklist_add done "regenerate babysit (harness=jcode)"
}

# --- 4. tools ---------------------------------------------------------------
update_tools() {
  log "=== tools ==="
  run_jobs update_herdr_tools verify_babysitter_sdk update_gopls
}
update_herdr_tools() {
  if command -v mise >/dev/null; then
    run "mise herdr latest" mise install herdr@latest
    run "mise use herdr@latest" mise use -g herdr@latest
  fi
  if command -v herdr >/dev/null; then
    run "herdr plugin reinstall pickr" herdr plugin install tomasvarga/herdr-pickr -y
  fi
}
verify_babysitter_sdk() {
  if command -v node >/dev/null; then
    # The babysitter CLI is consumed via `npm exec --package @a5c-ai/babysitter-sdk@latest`
    # at runtime (documented fallback; no global install). This step VERIFIES the
    # latest SDK resolves — it does not install anything.
    run "babysitter SDK verify (npx always-latest)" node -e "require('child_process').execSync('npm exec --yes --package @a5c-ai/babysitter-sdk@latest -- babysitter --version', {stdio:'inherit'})"
  fi
}
update_gopls() {
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
  run "install $src -> $dst" cp "$src" "$dst"
}

install_live_jcode_config() {
  local src="$DOTFILES/jcode/.jcode/config.toml" dst="$HOME/.jcode/config.toml"
  [ -f "$src" ] || return 0
  if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
    log "PRESERVED: live jcode config differs; review/merge manually, runtime keys were not overwritten"
    checklist_add skip "live jcode config preserved (manual merge required)"
    return 0
  fi
  install_if_different "$src" "$dst"
}

# --- 5. configs: preserve runtime state and unrelated dotfiles work --------
sync_configs() {
  log "=== configs (dotfiles -> live, then push dotfiles) ==="
  if [ "$DRY" = 1 ]; then
    log "DRY: pull clean dotfiles branch, install configs (preserve divergent live jcode config), push clean branch"
    checklist_add skip "configs (dry-run, no writes or git executed)"
    return 0
  fi
  [ -d "$DOTFILES/.git" ] || { log "skip: no dotfiles repo at $DOTFILES"; return; }

  # Keep dotfiles itself up to date with any remote changes (other machines).
  # Pull the actual checked-out branch, not `origin HEAD`
  # which resolves to the remote's default branch and diverges.
  local df_branch df_pull_ok=1
  df_branch=$(git -C "$DOTFILES" branch --show-current)
  [ -n "$df_branch" ] || fail "dotfiles detached HEAD"
  if [ "$DRY" = 1 ]; then
    log "DRY: git pull dotfiles ($df_branch)"
  elif [ -n "$(git -C "$DOTFILES" status --porcelain)" ]; then
    log "PRESERVED: dirty dotfiles; skip pull/staging/commit/push, install current configs only"
    checklist_add skip "dirty dotfiles pull/commit/push (manual review required)"
    df_pull_ok=0
  elif ( cd "$DOTFILES" && git fetch origin && git -c pull.rebase=false -c merge.autoStash=false pull --ff-only origin "$df_branch" ) >> "$LOG" 2>&1; then
    log "OK:  dotfiles pulled ($df_branch)"
    checklist_add done "dotfiles pull ($df_branch)"
  else
    log "WARN: dotfiles pull failed (continuing with local state)"
    df_pull_ok=0
    checklist_add fail "dotfiles pull ($df_branch)"
  fi

  # jcode config + hooks (symlink-safe install)
  if [ -f "$DOTFILES/jcode/.jcode/config.toml" ]; then
    install_live_jcode_config
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

  # Only push a clean branch after successful ff-only pull. No source files
  # were generated by this phase, so there is nothing safe to stage or commit.
  if [ "$DRY" = 1 ]; then log "DRY: commit+push dotfiles"; return; fi
  if [ "$df_pull_ok" = 1 ]; then
    # This phase installs outward and owns no source edits. Never stage user
    # work (including an unrelated index), nor create empty update commits.
    if [ -z "$(git -C "$DOTFILES" status --porcelain)" ]; then
      run "push clean dotfiles branch $df_branch" git -C "$DOTFILES" push origin "$df_branch"
    else
      checklist_add skip "dotfiles push (concurrent edits, manual review required)"
    fi
  else
    log "WARN: skipping dotfiles push (pull failed; remote may have commits we did not merge)"
  fi
}

# --- 6. self-review: run ponytail + tiger-style on the new code -------------
self_review() {
  log "=== self-review (ponytail + tiger-style on new code) ==="
  if [ "$DRY" = 1 ]; then log "DRY: self-review"; return 0; fi
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
  if [ "$DRY" = 1 ]; then log "DRY: manifest -> $MANIFEST"; return 0; fi
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
        babysit)        source="a5c-ai/babysitter (custom harness=jcode)"; repo="$UPDATER_SRC/babysitter" ;;
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
  log "OK: manifest written to $out ($(grep -c '^| ' "$out" | awk '{print $1-1}') skills)"
  checklist_add done "write skill manifest"
}

update_skills() { skill_sources; sync_skills; }
update_core_phase() { update_jcode; self_review; }

show_context() {
  printf '%s\n' \
    "Canonical script: $DOTFILES/jcode/update-all.sh" \
    "Canonical skill: $DOTFILES/jcode/skills/update-all/SKILL.md" \
    "Next-run context: $DOTFILES/jcode/skills/update-all/CONTEXT.md" \
    "Checklist: $CHECKLIST" "Latest log: $LOG" \
    'Run --parallel for independent core/skills/tools, then configs and manifest.' \
    'Dirty core fails. Live-only config keys are preserved. Read CONTEXT.md before updating.'
}

main() {
  # No shell options, filesystem writes, argument parsing or work on source.
  set -uo pipefail
  local parsed rc=0
  parsed=0
  parse_args "$@" || parsed=$?
  [ "$parsed" != 2 ] || return 0
  [ "$parsed" = 0 ] || return 2
  command -v flock >/dev/null || { echo 'flock is required' >&2; return 1; }
  mkdir -p "$LOG_DIR"
  exec 9>"$LOG_DIR/update-all.lock"
  flock -n 9 || { echo 'Another update-all run owns the lock' >&2; return 1; }
  export GIT_TERMINAL_PROMPT=0 GIT_MERGE_AUTOEDIT=no
  RUN_DIR=$(mktemp -d "$LOG_DIR/update-all-$(date -u +%Y%m%dT%H%M%SZ).XXXXXX")
  local shared_log="$LOG"
  LOG="$RUN_DIR/update-all.log"
  CHECKLIST_TMP="$RUN_DIR/checklist.tsv"
  mkdir -p "$UPDATER_SRC"
  checklist_init
  log "update-all started (dry_run=$DRY parallel=$PARALLEL); private run: $RUN_DIR"
  local -a phases=()
  [ "$DO_JCODE" = 0 ] || phases+=(update_core_phase)
  [ "$DO_SKILLS" = 0 ] || phases+=(update_skills)
  [ "$DO_TOOLS" = 0 ] || phases+=(update_tools)
  run_jobs "${phases[@]}"
  rc=$?
  # Do not install/publish a mixed partial update after an independent failure.
  if [ "$rc" = 0 ]; then
    phases=()
    [ "$DO_CONFIG" = 0 ] || phases+=(sync_configs)
    [ "$DO_SKILLS" = 0 ] || phases+=(write_manifest)
    PARALLEL=0
    run_jobs "${phases[@]}"
    rc=$?
  else
    checklist_add skip "configs/manifest (earlier phase failed)"
  fi
  if grep -q '^fail' "$CHECKLIST_TMP"; then rc=1; fi
  mkdir -p "$(dirname "$CHECKLIST")"
  checklist_write "$rc"
  log "update-all finished (exit=$rc); restart/reload only successful updates"
  cp "$LOG" "$shared_log" || rc=1
  flock -u 9
  exec 9>&-
  return "$rc"
}

# --- main -------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
