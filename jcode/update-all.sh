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
#     2. Skill sources — git pull ponytail, tiger-style, caveman, babysitter,
#                       herdr; re-sync installed skills into ~/.agents/skills.
#     3. Regenerated skills — babysit keeps our jcode harness=jcode adaptation;
#                       herdr is a plain sync; then skills-cap.py caps every
#                       description at the catalogue budget (see 3c).
#     3d. pi rules file — ~/.pi/agent/AGENTS.md generated from ~/.agents/AGENTS.md
#                       plus jcode/pi-agents.fragment.md (see 3d).
#     3e. pi patches  — ~/dotfiles/pi-patches re-applied to the npm-installed pi
#                       dist tree, which a pi upgrade overwrites (see 3e).
#     4. Tools         — mise herdr, babysitter SDK via npx
#                       (always latest), gopls best-effort.
#     5. Configs       — install dotfiles configs into live locations
#                       (~/.jcode, ~/.config/herdr, repo .a5c). Preserve divergent
#                       live config and dirty dotfiles; never stage user changes.
#     6. Skill manifest — ~/.agents/skills/README.md regenerated.
#
#   Preserved custom things: local/turn-end-gate jcode branch (in the fork),
#   herdr-agent-state.sh hook, babysitter-gate.sh hook,
#   .a5c/processes/* (babysitter processes), any skill in ~/.agents/skills/
#   with no upstream source listed below.
#
#   UPSTREAM PRECEDENCE (critical constraint):
#   jcode core is upstream-managed. Our fork carries local/turn-end-gate only
#   where it does not conflict with upstream direction. On rebase conflict,
#   upstream wins and we adapt:
#     - Equal upstream functionality   -> drop our version, keep upstream's
#     - Upstream absorbed our patch     -> keep merged result (not duplicate)
#     - turn_end_gate is the SOLE continuation-decision hook.
#       turn_end / post_tool_feedback are fire-and-forget observers only.
#       Do not duplicate continuation control flow across hooks.
#
#   Usage:
#     ~/.jcode/bin/update-all.sh              # full update
#     ~/.jcode/bin/update-all.sh --dry-run    # show what would run
#     ~/.jcode/bin/update-all.sh --jcode-only
#     ~/.jcode/bin/update-all.sh --skills-only
#     ~/.jcode/bin/update-all.sh --tools-only
#     ~/.jcode/bin/update-all.sh --config-only
#     ~/.jcode/bin/update-all.sh --manifest-only  # just rebuild README.md from installed skills
#     ~/.jcode/bin/update-all.sh --pi-only    # regenerate ~/.pi/agent/AGENTS.md + re-apply pi patches
#     ~/.jcode/bin/update-all.sh --patches-only  # just re-apply ~/dotfiles/pi-patches to the pi install
#     ~/.jcode/bin/update-all.sh --parallel   # independent phases and sources
#     ~/.jcode/bin/update-all.sh --context    # fast, read-only context pointers
#
#   After it finishes: restart jcode (or reload skills) so the new skill list
#   takes effect. If jcode itself updated, restart jcode or run /rebuild in a
#   session (needs ~/.jcode/debug_control; see SELFDEV-NOTES.md, which also
#   covers how to check which build the running server actually has mapped).
# ============================================================================

# --- config -----------------------------------------------------------------
HOME_DIR="$HOME"
JCODE_SRC="$HOME/.jcode/source/jcode"
SKILLS_DIR="$HOME/.agents/skills"
# Skills a host installs outside SKILLS_DIR (pi's npm-packaged ones). Overlays
# for those live in skills-overlay/host/ instead.
HOST_SKILLS_DIR="$HOME/.pi/agent/skills"
UPDATER_SRC="$HOME/.jcode/updater-src"          # git clones we own for skill sync
LOG_DIR="$HOME/.jcode/logs"
LOG="$LOG_DIR/update-all.log"
MANIFEST="$SKILLS_DIR/README.md"
# The repo root is where THIS script lives, not a hardcoded ~/dotfiles: cloned to
# ~/src/dotfiles the config phase used to log "skip: no dotfiles repo" and return
# 0, a green run that installed nothing. ~/dotfiles stays the fallback for the
# installed ~/.jcode/bin/update-all.sh copy if it were ever a real file.
DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." 2>/dev/null && pwd)
[ -n "$DOTFILES" ] && [ -d "$DOTFILES/.git" ] || DOTFILES="$HOME/dotfiles"
GATE_BRANCH="local/turn-end-gate"
JCODE_FORK="https://github.com/PremModhaOfficial/jcode.git"
JCODE_UPSTREAM="https://github.com/1jehuang/jcode.git"
UPDATER="${BASH_SOURCE[0]}"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG"; }
# Every pipeline whose first stage decides whether the run is green goes through
# this, and it reads PIPESTATUS itself with pipefail deliberately off, so the
# answer does not depend on which shell option a caller happened to inherit.
# `cmd | tee || rc=1` reports tee's status and swallows the failure: that is how
# a refused transform once ended `update-all finished (exit=0)`.
# Pipelines that are only formatting (log's own echo, the checklist/manifest
# tables, `grep ... || echo "(none)"`, `wc | tr`, the stale-run pruning
# `find | sort | tail | xargs rm`) are not wrappers: their last stage is either
# the decision or nothing can fail meaningfully in stage 0.
run_logged() {
  local rc had_pipefail=0 had_errexit=0
  shopt -qo pipefail && had_pipefail=1
  case $- in *e*) had_errexit=1 ;; esac
  # Both options are cleared for the pipeline itself, then restored: with
  # errexit on, a failing stage 0 would kill the shell before PIPESTATUS could
  # be read, and the step's own error line would never print.
  set +o pipefail
  set +e
  "$@" 2>&1 | tee -a "$LOG"
  rc=${PIPESTATUS[0]}
  [ "$had_pipefail" = 0 ] || set -o pipefail
  [ "$had_errexit" = 0 ] || set -e
  return "$rc"
}
fail() { log "ERROR: $*"; checklist_add fail "$*"; exit 1; }

DRY=0; PARALLEL=0; DO_JCODE=1; DO_SKILLS=1; DO_TOOLS=1; DO_CONFIG=1; DO_MANIFEST=1; DO_PI=1; DO_PATCHES=1
parse_args() {
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --parallel) PARALLEL=1 ;;
    --context) show_context; return 2 ;;
    --jcode-only) DO_SKILLS=0; DO_TOOLS=0; DO_CONFIG=0; DO_PI=0; DO_PATCHES=0 ;;
    --skills-only) DO_JCODE=0; DO_TOOLS=0; DO_CONFIG=0; DO_PI=0; DO_PATCHES=0 ;;
    --tools-only) DO_JCODE=0; DO_SKILLS=0; DO_CONFIG=0; DO_PI=0; DO_PATCHES=0 ;;
    # --config-only used to leave DO_PI/DO_PATCHES on, so the one repair command
    # for a failed cold run re-ran the two phases that failed for the same reason
    # (finding 8). Every selector now turns off the phases it does not name.
    --config-only) DO_JCODE=0; DO_SKILLS=0; DO_TOOLS=0; DO_MANIFEST=0; DO_PI=0; DO_PATCHES=0 ;;
    # Manifest reads installed skills, not sources, so it is safe to run alone
    # after a partial run. It is its own flag so a core-phase failure can still
    # be repaired with one cheap command instead of a whole full run.
    --manifest-only) DO_JCODE=0; DO_SKILLS=0; DO_TOOLS=0; DO_CONFIG=0 ;;
    # Same reason as --manifest-only: a generated file that drifted must be repairable
    # without a full run, which is also how the failure path gets tested.
    --pi-only) DO_JCODE=0; DO_SKILLS=0; DO_TOOLS=0; DO_CONFIG=0; DO_MANIFEST=0 ;;
    # A pi upgrade silently reverts a patch to its dist tree; this repairs that
    # without paying for a full run.
    --patches-only) DO_JCODE=0; DO_SKILLS=0; DO_TOOLS=0; DO_CONFIG=0; DO_MANIFEST=0; DO_PI=0 ;;
    *) echo "unknown arg: $arg" >&2; return 1 ;;
  esac
done
}

# Per-run checklist ledger: appended to CHECKLIST.md so the skill (and the user)
# can see exactly what was done, and verify next time. Kept out of $SKILLS_DIR:
# a dir there with no SKILL.md reads as a broken skill to every harness scanner.
CHECKLIST_DIR="$HOME/.jcode/state/update-all"
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
    # The run must say what it did NOT do. A skipped step used to appear only as a
    # table row (or, before this, not even that when a phase returned 0 early), so
    # "zero configs installed, exit 0" was indistinguishable from a full sync.
    echo "### Not done in this run"
    if grep -qE '^(skip|fail)' "$CHECKLIST_TMP"; then
      awk -F'\t' '$1=="skip"||$1=="fail"{print "- " $1 ": " $2}' "$CHECKLIST_TMP"
    else
      echo "- nothing skipped or failed"
    fi
    echo ""
  } >> "$CHECKLIST"
  log "OK: checklist appended to $CHECKLIST ($ok/$total ok, $failc failed, $skipped skipped)"
  if grep -qE '^(skip|fail)' "$CHECKLIST_TMP"; then
    log "not done this run:"
    awk -F'\t' '$1=="skip"||$1=="fail"{print "  " $1 ": " $2}' "$CHECKLIST_TMP" | tee -a "$LOG"
  fi
}

# --- 0. prerequisites -------------------------------------------------------
# Everything the phases below assume is checked once, by name, at the start. A
# fresh machine used to learn about a missing tool through eight unrelated phase
# failures, one of which (PyYAML) only surfaced as a traceback from inside a
# Python step and took the configs down with it.
preflight() {
  log "=== prerequisites ==="
  local missing=() t
  for t in git bash python3 flock sha256sum cmp cp; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    log "ERROR: missing required tools: ${missing[*]}"
    log "ERROR: install them and re-run; no phase was started"
    checklist_add fail "prerequisites (missing: ${missing[*]})"
    return 1
  fi
  log "OK: git, bash, python3, flock, sha256sum, cmp, cp present"
  checklist_add done "prerequisites (base tools)"

  # PyYAML is a hard import in skills-cap-check.py and the only soft one in
  # skills-cap.py. The user site dir is per-HOME, so it is simply absent on a new
  # machine and the cap step dies with a traceback. Install it once here, and
  # never continue without it: the cap is the difference between a 40 KB and a
  # 34 KB prompt on every turn.
  if python3 -c 'import yaml' 2>/dev/null; then
    log "OK: PyYAML present ($(python3 -c 'import yaml; print(yaml.__file__)' 2>/dev/null))"
    checklist_add done "prerequisites (PyYAML)"
  elif [ "$DRY" = 1 ]; then
    log "DRY: PyYAML missing; would run: python3 -m pip install --user pyyaml"
    checklist_add skip "prerequisites (PyYAML missing, dry-run)"
  elif python3 -m pip install --user pyyaml >/dev/null 2>&1 && python3 -c 'import yaml' 2>/dev/null; then
    log "OK: installed PyYAML (python3 -m pip install --user pyyaml)"
    checklist_add done "prerequisites (PyYAML installed)"
  else
    # A distro Python with PEP 668 (Arch, Debian 12+) refuses --user without
    # --break-system-packages, so the plain command above is not enough to quote.
    log "ERROR: PyYAML missing (skills-cap-check.py imports it); install it, then re-run:"
    log "ERROR:   python3 -m pip install --user --break-system-packages pyyaml"
    log "ERROR:   or your distro package (pacman -S python-pyyaml / apt install python3-yaml)"
    log "ERROR: no phase was started; nothing was installed or changed"
    checklist_add fail "prerequisites (PyYAML missing: python3 -m pip install --user --break-system-packages pyyaml)"
    return 1
  fi
  return 0
}

# --- 0b. symlink fleet ------------------------------------------------------
# ~/.agents is the tree every skill, the manifest and gen-pi-agents.py read, and
# nothing in this repo ever created it. It was hand-made with `ln -s` on one
# machine, so a fresh machine installed 35 of 130 skills into a real directory,
# never generated ~/.pi/agent/AGENTS.md, and lost the other 95 with no error.
# Created here, before any phase reads it; every phase below checks it.
link_into_repo() { # link_into_repo <link> <target>
  local link="$1" target="$2" want
  # Relative only for a link that sits directly in $HOME: a relative link is
  # resolved against the link's own dir, so "dotfiles/..." placed in
  # ~/.jcode/bin/ points at ~/.jcode/bin/dotfiles/... and dangles. A link that
  # lives under $HOME keeps its target relative so a moved home dir survives.
  if [ "$(dirname "$link")" = "$HOME" ] && [ "${target#"$HOME"/}" != "$target" ]; then
    want="${target#"$HOME"/}"
  else
    want="$target"
  fi
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$want" ]; then
    log "OK:  link $link -> $want (in place)"
    return 0
  fi
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    # Never rm a real directory or file: it may hold the only copy of something.
    log "ERROR: $link exists and is not a symlink; refusing to replace it"
    log "ERROR: move it aside (mv $link $link.bak) and re-run so the repo copy is used"
    return 1
  fi
  if [ "$DRY" = 1 ]; then log "DRY: ln -sfn $want $link"; return 0; fi
  ln -sfn "$want" "$link" || { log "ERROR: could not link $link -> $want"; return 1; }
  log "OK:  link $link -> $want"
}

bootstrap_links() {
  log "=== symlink fleet (~/.agents is read by every later phase) ==="
  local rc=0
  if [ "$DRY" = 1 ]; then
    log "DRY: link fleet would be created under $HOME"
  else
    mkdir -p "$HOME/.jcode/bin" || rc=1
  fi
  link_into_repo "$HOME/.agents"                 "$DOTFILES/agents/.agents" || rc=1
  link_into_repo "$HOME/AGENTS.md"               "$DOTFILES/agents/AGENTS.md" || rc=1
  link_into_repo "$HOME/skills"                  "$DOTFILES/agents/.agents/skills" || rc=1
  link_into_repo "$HOME/.skill-lock.json"        "$DOTFILES/agents/.agents/.skill-lock.json" || rc=1
  link_into_repo "$HOME/.jcode/bin/update-all.sh" "$DOTFILES/jcode/update-all.sh" || rc=1
  if [ "$rc" = 0 ]; then
    checklist_add done "symlink fleet (~/.agents, ~/AGENTS.md, ~/skills, ~/.skill-lock.json, ~/.jcode/bin/update-all.sh)"
  else
    checklist_add fail "symlink fleet (see ERROR lines above)"
  fi
  return "$rc"
}

# One guard for every phase that reads $SKILLS_DIR. Without it a missing fleet
# looks like a normal empty run: sync_dir mkdir -p'd a real ~/.agents/skills and
# reported 35 successful copies while 95 skills never existed.
require_links() { # require_links <phase>
  local phase="$1"
  if [ -d "$SKILLS_DIR" ]; then return 0; fi
  log "ERROR: $phase needs $SKILLS_DIR, which is missing"
  log "ERROR: ~/.agents is a symlink into $DOTFILES/agents/.agents; the bootstrap step creates it"
  log "ERROR: re-run: bash $DOTFILES/jcode/update-all.sh"
  checklist_add fail "$phase (missing ~/.agents; symlink fleet not created)"
  return 1
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
  # ~/.jcode/source/jcode is created by `jcode self-dev --setup`, which is a
  # jcode feature this repo does not provide. Failing here was correct-looking and
  # wrong: the config phase used to be gated behind it, so a fresh machine
  # installed ZERO configs because core could never pass. Report the missing
  # prerequisite and let the independent phases run.
  local why=""
  command -v cargo >/dev/null 2>&1 || why="cargo not installed"
  [ -d "$JCODE_SRC/.git" ] || why="${why:+$why; }no jcode source at $JCODE_SRC (run: jcode self-dev --setup)"
  if [ -n "$why" ]; then
    log "SKIP: jcode core — $why"
    log "SKIP: core covers only the fork rebase/build/push; skills, pi rules and configs still run"
    checklist_add skip "core ($why)"
    return 0
  fi
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
  log "to run the updated jcode: restart jcode, or /rebuild in a session (needs ~/.jcode/debug_control)"
  return "$rc"
}

# --- 2. skill sources -------------------------------------------------------
skill_sources() {
  log "=== skill sources ==="
  declare -A sources=(
    ["ponytail"]="https://github.com/DietrichGebert/ponytail"
    ["caveman"]="https://github.com/JuliusBrussee/caveman"
    ["tiger-style"]="https://github.com/PremModhaOfficial/tiger-style"
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
  if [ -d "$plib/.git" ]; then
    jobs+=(pull_process_library)
  else
    log "SKIP: babysitter process library — no clone at $plib"
  fi
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
# Provenance ledger: which skill dirs this script wrote, and from where. Recorded
# at sync time because a later run cannot otherwise tell an upstream skill the
# repo dropped from a hand-written local skill that merely looks like one.
stamp_source() { # stamp_source <src> <dst>
  local src="$1" dst="$2" name ledger tmp
  [ "$DRY" = 1 ] && return 0
  name=$(basename "$dst")
  # Kept out of $SKILLS_DIR on purpose: that tree is git-tracked, and a ledger
  # file there would look like a skill to anything that globs the directory.
  ledger="$HOME/.jcode/state/upstream-sources"
  tmp="$ledger.tmp"
  mkdir -p "$(dirname "$ledger")"
  { awk -F'\t' -v n="$name" '$1 != n' "$ledger" 2>/dev/null || true; } > "$tmp"
  printf '%s\t%s\n' "$name" "$src" >> "$tmp"
  mv "$tmp" "$ledger"
}

sync_dir() { # sync_dir <src> <dst>
  local src="$1" dst="$2"
  if [ "$DRY" = 1 ]; then log "DRY: sync $src -> $dst"; return 0; fi
  [ -d "$src" ] || { log "ERROR (missing): $src"; checklist_add fail "sync $src (missing)"; return 1; }
  if [ "$DRY" = 1 ]; then log "DRY: sync $src -> $dst"; return; fi
  mkdir -p "$dst"
  # cp's status was ignored, so a failed copy still logged OK and counted as done.
  cp -R "$src/." "$dst/" || {
    log "ERROR: copy failed $src -> $dst"
    checklist_add fail "sync $(basename "$dst")"
    return 1
  }
  log "OK: sync $src -> $dst"
  stamp_source "$src" "$dst"
  checklist_add done "sync $(basename "$dst")"
}

sync_skills() {
  log "=== skill sync ==="
  require_links "skill sync" || return 1
  # ponytail family (ponytail + audits)
  sync_dir "$UPDATER_SRC/ponytail/skills/ponytail"        "$SKILLS_DIR/ponytail"
  sync_dir "$UPDATER_SRC/ponytail/skills/ponytail-audit"  "$SKILLS_DIR/ponytail-audit"
  sync_dir "$UPDATER_SRC/ponytail/skills/ponytail-debt"   "$SKILLS_DIR/ponytail-debt"
  sync_dir "$UPDATER_SRC/ponytail/skills/ponytail-gain"   "$SKILLS_DIR/ponytail-gain"
  sync_dir "$UPDATER_SRC/ponytail/skills/ponytail-help"   "$SKILLS_DIR/ponytail-help"
  sync_dir "$UPDATER_SRC/ponytail/skills/ponytail-review" "$SKILLS_DIR/ponytail-review"
  # caveman + friends (now its own repo: JuliusBrussee/caveman). Since 4.0 upstream
  # ships a registry-driven suite and adds skills between releases, so enumerate
  # the registry instead of naming skills: the old hardcoded seven silently left
  # 15 upstream skills (ultracave, megacave, the native/* workflows) uninstalled.
  # Count them: an unmatched glob must fail loudly, not sync zero and report OK.
  local caveman_skill caveman_count=0 caveman_rc=0
  for caveman_skill in "$UPDATER_SRC/caveman/skills"/*/SKILL.md; do
    [ -f "$caveman_skill" ] || continue
    caveman_skill=$(basename "$(dirname "$caveman_skill")")
    caveman_count=$((caveman_count+1))
    sync_dir "$UPDATER_SRC/caveman/skills/$caveman_skill" "$SKILLS_DIR/$caveman_skill" || caveman_rc=1
  done
  if [ "$caveman_count" = 0 ]; then
    log "ERROR: no caveman skills matched $UPDATER_SRC/caveman/skills/*/SKILL.md (clone missing or upstream restructured)"
    checklist_add fail "sync caveman (no source skills)"
    caveman_rc=1
  fi
  # A sync only copies, so a skill upstream drops or renames stays installed and
  # keeps loading. Warn when a ledger entry's source is gone: a name prefix cannot
  # tell an upstream skill from a local one. No rm -rf yet, so a wrong ledger can
  # never delete user files; add a delete only once this is known-good.
  local stale from
  if [ -f "$HOME/.jcode/state/upstream-sources" ]; then
    while IFS=$'\t' read -r stale from; do
      [ -n "$from" ] || continue
      [ -e "$from" ] && continue
      log "WARN: $stale is installed but its upstream source is gone: $from"
    done < "$HOME/.jcode/state/upstream-sources"
  fi

  # tiger-style family
  sync_dir "$UPDATER_SRC/tiger-style/skills/tiger-style"        "$SKILLS_DIR/tiger-style"
  sync_dir "$UPDATER_SRC/tiger-style/skills/tiger-style-audit"  "$SKILLS_DIR/tiger-style-audit"
  sync_dir "$UPDATER_SRC/tiger-style/skills/tiger-style-commit" "$SKILLS_DIR/tiger-style-commit"
  sync_dir "$UPDATER_SRC/tiger-style/skills/tiger-style-help"   "$SKILLS_DIR/tiger-style-help"
  sync_dir "$UPDATER_SRC/tiger-style/skills/tiger-style-review" "$SKILLS_DIR/tiger-style-review"

  # herdr skill (plain upstream copy)
  sync_dir "$UPDATER_SRC/herdr/skills/herdr" "$SKILLS_DIR/herdr"

  # babysit — REGENERATED with our jcode adaptation preserved
  regenerate_babysit
  # A caveman-only failure must not report the whole family set as done, but it
  # must not skip tiger-style or herdr either.
  return "$caveman_rc"
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

  # Two upstream sentences assume files the install never gets: the SDK version
  # reader points at versions.json (repo-only) and the sed below already replaced
  # the version itself, so the sentence would contradict the code under it.
  sed -e 's|^SDK_VERSION=.*$|SDK_VERSION=latest|' \
      -e 's|^Read the SDK version from `versions.json`.*$|Use the latest published babysitter SDK; the version pin lives in SDK_VERSION below.|' \
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
  # Generated, not copied, so sync_dir never stamped it: record it here or the
  # manifest can attribute babysit to a repo the ledger has no line for.
  stamp_source "$src_skill" "$dst"
}

# --- 3b. skill overlays -----------------------------------------------------
# A sync copies the skill's own dir, so everything a SKILL.md points at outside
# it (repo README, docs/, agents/) is gone after install, and an in-place fix is
# wiped by the next sync. Each fix therefore lives in
# ~/dotfiles/skills-overlay/<skill>.sh and is re-applied here, after every
# family sync and before the manifest, so the manifest and the audit always see
# the patched tree.
# Overlay contract: run with cwd = the installed skill dir, SKILL_DIR and CLONE
# exported, idempotent, exit 0 with an OVERLAY-WARN line when it cannot patch,
# and .overlay-applied touched last so skills-audit can prove it ran.
run_overlay() { # run_overlay <script> <base-dir>
  local f="$1" base="$2" skill
  skill=$(basename "$f" .sh)
  if [ ! -d "$base" ]; then
    # The host itself is not installed (e.g. no ~/.pi/agent/skills on a machine
    # without pi). That is a known skip, not a warning: a WARN here is what made
    # "0 warnings" impossible on a fresh machine, and hiding it entirely is what
    # this round exists to stop.
    log "SKIP: overlay $skill — host skills dir $base does not exist (host not installed)"
    checklist_add skip "overlay $skill (no host skills dir $base)"
    return 0
  fi
  if [ ! -d "$base/$skill" ]; then
    # Warn, not fail: killing the run because one overlay targets a skill this
    # host does not have helps nobody. The audit turns a genuinely unapplied
    # overlay into an issue.
    log "OVERLAY-WARN: no installed skill $skill in $base"
    return 0
  fi
  # Subshell keeps the overlay's own cwd out of the runner and puts the whole
  # contract env in one place.
  if ( cd "$base/$skill" && SKILL_DIR="$base/$skill" CLONE="$UPDATER_SRC" bash "$f" ); then
    log "OK:  overlay $skill"
    checklist_add done "overlay $skill"
  else
    # Deliberately not fatal: the audit fails the run if a patch is missing,
    # and a broken overlay must not block the manifest or the configs.
    log "OVERLAY-WARN: $skill exited non-zero"
    checklist_add fail "overlay $skill (non-zero exit)"
  fi
  return 0
}
apply_overlays() {
  log "=== skill overlays ==="
  if [ "$DRY" = 1 ]; then
    log "DRY: bash $DOTFILES/skills-overlay/*.sh and skills-overlay/host/*.sh"
    checklist_add skip "skill overlays (dry-run)"
    return 0
  fi
  local f
  # One file per skill, named after the skill. host/ is the same contract for a
  # skill that lives outside $SKILLS_DIR (see HOST_SKILLS_DIR above).
  for f in "$DOTFILES"/skills-overlay/*.sh; do
    [ -f "$f" ] && run_overlay "$f" "$SKILLS_DIR"
  done
  for f in "$DOTFILES"/skills-overlay/host/*.sh; do
    [ -f "$f" ] && run_overlay "$f" "$HOST_SKILLS_DIR"
  done
  return 0
}

# --- 3c. catalogue cap ------------------------------------------------------
# A sync overwrites SKILL.md frontmatter, so a shortened description is undone by
# the next pull. The 98 catalogue entries cost 40,191 B of every request (73% of
# the prompt) before this cap, and descriptions were 24 KB of that. The transform
# is part of the sync, not a one-off: it runs after the overlays so the manifest
# and the audit see the capped tree, and the run fails if any description is over
# the cap or any recorded routing term went missing.
# pi registers a skill as /skill:<name>; a card that says "invoke /name" is a
# command that does nothing. 74 installed cards carried the bare form in
# frontmatter Trigger lines and mode tables, all copied from upstreams where
# /name works, and hand edits to them are reverted by the next sync. Rewrite
# them after the sync, and fail the run when a bare one survives: a new upstream
# card that reintroduces the form must turn the run red, not ship silently.
#
# Runs before the catalogue cap on purpose. A sync writes bare text into
# ~/.agents/skills while the vendored copy of the same skill under
# ~/.pi/agent/git/ is already rewritten, so the cap would read two forms of one
# description, record terms from both in its ledger, and then fail its own check
# on whichever copy it compared against. Normalising first puts every copy in
# the same form and the cap sees one description per skill.
apply_skill_activation() {
  log "=== skill activation form ==="
  if [ "$DRY" = 1 ]; then
    log "DRY: python3 $DOTFILES/jcode/skills-activation.py --dry-run"
    checklist_add skip "skill activation form (dry-run)"
    return 0
  fi
  local rc=0
  # The wrapper returns the transform's own status (exit 1 refusal, exit 2 below
  # the floor), never tee's; see run_logged.
  run_logged python3 "$DOTFILES/jcode/skills-activation.py" || rc=1
  if [ "$rc" = 0 ]; then
    checklist_add done "skill activation form"
  else
    log "ERROR: a bare /<skill> activation survived; pi only registers /skill:<name>"
    checklist_add fail "skill activation form"
  fi
  return "$rc"
}

apply_skill_cap() {
  log "=== skill catalogue cap ==="
  if [ "$DRY" = 1 ]; then
    log "DRY: python3 $DOTFILES/jcode/skills-cap.py && python3 $DOTFILES/jcode/skills-cap-check.py"
    checklist_add skip "skill catalogue cap (dry-run)"
    return 0
  fi
  local rc=0
  run_logged python3 "$DOTFILES/jcode/skills-cap.py" || rc=1
  run_logged python3 "$DOTFILES/jcode/skills-cap-check.py" || rc=1
  if [ "$rc" = 0 ]; then
    checklist_add done "skill catalogue cap"
  else
    # Fatal on purpose: an uncapped catalogue is 6 KB of prompt on every turn,
    # and silence is how the last hand-edited fix was lost.
    log "ERROR: skill catalogue cap failed; descriptions are not capped"
    checklist_add fail "skill catalogue cap"
  fi
  return "$rc"
}

# --- 3d. pi rules file ------------------------------------------------------
# pi has no `@` import for context files, so ~/.agents/AGENTS.md is inlined. Kept by
# hand it drifted: 42 diff lines against the shared file, two of which changed the
# instruction, and no step owned it. It is generated after the skill steps so one edit
# to the shared file reaches pi, and a broken fragment fails the run like the cap does:
# a stale rules file is invisible until an agent reads both copies.
generate_pi_agents() {
  log "=== pi rules file (generated) ==="
  if [ "$DRY" = 1 ]; then
    log "DRY: python3 $DOTFILES/jcode/gen-pi-agents.py"
    checklist_add skip "pi rules file (dry-run)"
    return 0
  fi
  require_links "pi rules file" || return 1
  if run_logged python3 "$DOTFILES/jcode/gen-pi-agents.py"; then
    checklist_add done "pi rules file (~/.pi/agent/AGENTS.md)"
  else
    # Fatal on purpose: the shared rules changed and pi is now running stale text,
    # so silence here is the exact drift this step exists to stop.
    log "ERROR: pi rules file generation failed; ~/.pi/agent/AGENTS.md is stale"
    checklist_add fail "pi rules file (~/.pi/agent/AGENTS.md)"
    return 1
  fi
}

# --- 3e. pi patches ---------------------------------------------------------
# pi is npm-managed, so an upgrade overwrites its dist/ tree and silently drops the
# fixes in ~/dotfiles/pi-patches/ (compaction role escaping). Re-applied after the
# generated rules file, and fatal on drift: a patch that no longer matches means the
# defect is live again, which must not pass as a green run.
apply_pi_patches() {
  log "=== pi patches (npm tree, re-applied) ==="
  if [ "$DRY" = 1 ]; then
    log "DRY: bash $DOTFILES/jcode/apply-pi-patches.sh --dry-run"
    checklist_add skip "pi patches (dry-run)"
    return 0
  fi
  local rc=0
  run_logged bash "$DOTFILES/jcode/apply-pi-patches.sh" || rc=$?
  if [ "$rc" = 3 ]; then
    # A machine without pi has nothing to patch. Report the skip with the paths the
    # resolver tried (pi-root.sh printed them): a skip is honest, a failure here
    # would paint a run red for a prerequisite the user has not installed yet.
    log "SKIP: pi patches — no pi install found (paths above; install pi or export PI_ROOT)"
    checklist_add skip "pi patches (no pi install found)"
    return 0
  fi
  if [ "$rc" = 0 ]; then
    # Applied is not the same as working: run the escape test, so an upgrade that
    # keeps the patch applying but changes the flattening sites still goes red.
    local trc=0
    run_logged bash "$DOTFILES/jcode/compaction-escape.test.sh" || trc=$?
    if [ "$trc" = 3 ]; then
      log "SKIP: compaction escape test — no pi install found"
      checklist_add skip "pi patches (escape test skipped: no pi install)"
    elif [ "$trc" = 0 ] && tail -1 "$LOG" | grep -q '^PASS'; then
      checklist_add done "pi patches (re-applied, escape test passed)"
    else
      log "ERROR: compaction escape test failed after applying the patch"
      checklist_add fail "pi patches (applied, escape test failed)"
      return 1
    fi
  else
    log "ERROR: pi patches did not apply; a pi upgrade probably changed the target"
    checklist_add fail "pi patches (target changed, refresh the patch)"
    return 1
  fi
}

# --- 4. tools ---------------------------------------------------------------
update_tools() {
  log "=== tools ==="
  run_jobs update_herdr_tools verify_babysitter_sdk update_gopls update_caveman_cli
}
# The caveman CLI is a hard dependency of five installed skills (learn, stats,
# optimize, evidence-review, manage). Installing it by hand once is how those
# skills ended up documented-but-dead on this machine, so the updater owns it.
update_caveman_cli() {
  if ! command -v npm >/dev/null 2>&1; then
    log "SKIP: caveman cli — npm not installed"
    checklist_add skip "caveman cli (npm not installed)"
    return 0
  fi
  run "caveman cli (npm global)" npm i -g @caveman-ai/cli@latest
  # Ships the six Go binaries (proxy, engine, mcp, browse, shrink, cavemem).
  # Idempotent: the signed installer skips components already at version.
  run "caveman binaries (signed installer)" caveman setup --install
}
update_herdr_tools() {
  if ! command -v mise >/dev/null 2>&1; then
    log "SKIP: herdr tools — mise not installed"
    checklist_add skip "herdr tools (mise not installed)"
    return 0
  fi
  run "mise herdr latest" mise install herdr@latest
  run "mise use herdr@latest" mise use -g herdr@latest
}
verify_babysitter_sdk() {
  if ! command -v node >/dev/null 2>&1; then
    log "SKIP: babysitter SDK verify — node not installed"
    checklist_add skip "babysitter SDK verify (node not installed)"
    return 0
  fi
  # The babysitter CLI is consumed via `npm exec --package @a5c-ai/babysitter-sdk@latest`
  # at runtime (documented fallback; no global install). This step VERIFIES the
  # latest SDK resolves — it does not install anything.
  run "babysitter SDK verify (npx always-latest)" node -e "require('child_process').execSync('npm exec --yes --package @a5c-ai/babysitter-sdk@latest -- babysitter --version', {stdio:'inherit'})"
}
update_gopls() {
  if ! command -v go >/dev/null 2>&1; then
    log "SKIP: gopls — go not installed"
    checklist_add skip "gopls (go not installed)"
    return 0
  fi
  run "gopls latest" go install golang.org/x/tools/gopls@latest
}

# install_if_different installs src -> dst.
#
# Two guards, because either alone is unsafe:
#   1. same file  - dst is a symlink into src, so cp would be a no-op at best
#                   and a confusing failure at worst.
#   2. DIVERGENCE - dst exists and differs from src. Without this, any edit made
#                   in the dotfiles tree silently destroyed the live copy with
#                   no backup. config.toml already had this via a separate cmp;
#                   apply the same rule everywhere so a live-only change is
#                   preserved and reported instead of overwritten.
# src always wins when the live copy is only a stale copy of an older src.
install_if_different() { # install_if_different <src> <dst>
  local src="$1" dst="$2"
  if [ "$DRY" = 1 ]; then log "DRY: install $src -> $dst"; return 0; fi
  # The destination dir was never created, so on a fresh machine both hook
  # installs (and anything else whose parent did not exist yet) failed on cp.
  mkdir -p "$(dirname "$dst")" || { log "ERROR: cannot create $(dirname "$dst")"; checklist_add fail "install $dst (no parent dir)"; return 1; }
  local rs ds
  rs=$(readlink -f "$src" 2>/dev/null || echo "$src")
  ds=$(readlink -f "$dst" 2>/dev/null || echo "$dst")
  if [ "$rs" = "$ds" ]; then
    log "OK:  install $dst (already in place)"
    return 0
  fi
  if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
    log "PRESERVED: $dst differs from $src; live edits kept, not overwritten (backup at $dst.bak.upstream)"
    cp -n "$dst" "$dst.bak.upstream" 2>/dev/null || true
    cp "$src" "$dst"
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
# SKILLS_DIR is ~/.agents/skills which is a symlink into
# dotfiles/agents/.agents/skills, so "${SKILLS_DIR#$DOTFILES/}" does NOT strip
# and git rejects the absolute :(exclude) as outside the repo. Resolve through
# the symlink first, then strip the DOTFILES prefix.
rel_to_dotfiles() { # rel_to_dotfiles <abs-path> -> repo-relative or empty
  local abs="$1" rp
  rp=$(readlink -f "$abs" 2>/dev/null || echo "$abs")
  case "$rp" in
    "$DOTFILES"/*) echo "${rp#$DOTFILES/}" ;;
    *) echo "" ;;
  esac
}

dotfiles_user_edits() { # echo porcelain lines for USER edits only
  local skills_rel manifest_rel
  skills_rel=$(rel_to_dotfiles "$SKILLS_DIR")
  manifest_rel=$(rel_to_dotfiles "$MANIFEST")
  local -a excludes=( ":(exclude)agents/.agents/" ":(exclude).agents/" )
  [ -n "$skills_rel" ] && excludes+=( ":(exclude)$skills_rel/" )
  [ -n "$manifest_rel" ] && excludes+=( ":(exclude)$manifest_rel" )
  git -C "$DOTFILES" status --porcelain -- "${excludes[@]}"
}

sync_configs() {
  log "=== configs (dotfiles -> live, then push dotfiles) ==="
  if [ "$DRY" = 1 ]; then
    log "DRY: pull clean dotfiles branch, install configs (preserve divergent live jcode config), push clean branch"
    checklist_add skip "configs (dry-run, no writes or git executed)"
    return 0
  fi
  # A missing repo used to log "skip: no dotfiles repo" and return 0: a green run
  # that installed nothing (finding 6). DOTFILES is now derived from this script's
  # own path, so this only fires on a genuinely broken checkout, and it is loud.
  [ -d "$DOTFILES/.git" ] || {
    log "ERROR: no dotfiles repo at $DOTFILES; configs were NOT installed"
    log "ERROR: run this script from the clone: bash <clone>/jcode/update-all.sh"
    checklist_add fail "configs (no dotfiles repo at $DOTFILES)"
    return 1
  }

  # Keep dotfiles itself up to date with any remote changes (other machines).
  # Pull the actual checked-out branch, not `origin HEAD`
  # which resolves to the remote's default branch and diverges.
  local df_branch df_pull_ok=1 df_dirty
  df_branch=$(git -C "$DOTFILES" branch --show-current)
  [ -n "$df_branch" ] || fail "dotfiles detached HEAD"
  # Judge "clean" by USER edits only. ~/.agents is a symlink into
  # dotfiles/agents/.agents, so SKILLS_DIR lives INSIDE $DOTFILES and the
  # skills phase always leaves that tree dirty. Counting those paths here made
  # this guard permanently unsatisfiable, so the ff-only pull and the push
  # below were dead code on every run. Filter the updater's own output; a real
  # edit anywhere else still trips the guard as intended.
  df_dirty=$(dotfiles_user_edits)
  if [ "$DRY" = 1 ]; then
    log "DRY: git pull dotfiles ($df_branch)"
  elif [ -n "$df_dirty" ]; then
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
    # install_if_different now creates the parent, but say it here too: this is
    # the step a fresh machine silently lost both hooks to.
    mkdir -p "$HOME/.jcode/hooks"
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
    # Same user-edit-only filter as the pull guard above, so updater-written
    # skill paths cannot block the push of an otherwise clean branch.
    df_dirty=$(dotfiles_user_edits)
    if [ -z "$df_dirty" ]; then
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
    # `grep | head -10` exits 141 (SIGPIPE) once head has its 10 lines, and
    # `set -o pipefail` in main propagates that, so the `|| echo "(none)"`
    # fallback fired *after* printing 10 real hits. The audit then claimed "no
    # debt" while listing it. `grep -m 10` stops on its own with a clean exit,
    # so the fallback can only fire on a genuine no-match.
    grep -rm 10 "TODO\|FIXME\|XXX\|HACK" "${targets[@]}" 2>/dev/null || echo "(none)"
    echo ""
    echo "Explicit limits (tiger-style: const/assert):"
    grep -rm 10 "const .* = \|assert" "${targets[@]}" 2>/dev/null || echo "(none)"
    echo ""
  } > "$review_out/$(date -u +%Y%m%dT%H%M%SZ).md"
  log "OK: self-review record written to $review_out"
  log "note: for full ponytail/tiger review, invoke /ponytail-review and /tiger-style-review on: ${targets[*]}"
}

# --- 7. skills audit --------------------------------------------------------
# Runs after the manifest: catches frontmatter gaps, duplicate descriptions,
# manifest drift, dangling host links and lost provenance. Every check here
# failed at least once on this machine, so the gate is worth its runtime.
audit_skills() {
  log "=== skills audit ==="
  if [ "$DRY" = 1 ]; then log "DRY: bash $DOTFILES/jcode/skills-audit.sh"; return 0; fi
  require_links "skills audit" || return 1
  local out rc=0 line
  out=$(bash "$DOTFILES/jcode/skills-audit.sh" 2>&1) || rc=$?
  while IFS= read -r line; do log "$line"; done <<< "$out"
  # Non-fatal on purpose: a stale link must not stop configs from installing, but
  # it does mark the run failed so it cannot be missed.
  if [ "$rc" = 0 ]; then checklist_add done "skills audit (clean)"; else
    checklist_add fail "skills audit (issues listed above)"
  fi
  return 0
}

# --- 8. manifest ------------------------------------------------------------
write_manifest() {
  log "=== skill manifest ==="
  if [ "$DRY" = 1 ]; then log "DRY: manifest -> $MANIFEST"; return 0; fi
  require_links "manifest" || return 1
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
      # Probe the clones instead of naming skills. A name list goes stale on the
      # first upstream addition, which is the exact bug this replaced: the old
      # caveman*|cavecrew case left 8 installed skills as "bundled/manual".
      # Require SKILL.md: caveman also ships native/ and generated/ there, which
      # are not skills and must not claim a skill of the same name.
      if [ -f "$UPDATER_SRC/caveman/skills/$name/SKILL.md" ]; then
        source="JuliusBrussee/caveman"; repo="$UPDATER_SRC/caveman"
      elif [ -f "$UPDATER_SRC/ponytail/skills/$name/SKILL.md" ]; then
        source="DietrichGebert/ponytail"; repo="$UPDATER_SRC/ponytail"
      elif [ -f "$UPDATER_SRC/tiger-style/skills/$name/SKILL.md" ]; then
        source="PremModhaOfficial/tiger-style"; repo="$UPDATER_SRC/tiger-style"
      elif [ -f "$UPDATER_SRC/herdr/skills/$name/SKILL.md" ]; then
        source="herdrdev/herdr"; repo="$UPDATER_SRC/herdr"
      elif [ "$name" = babysit ]; then
        source="a5c-ai/babysitter (custom harness=jcode)"; repo="$UPDATER_SRC/babysitter"
      fi
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

update_skills() { skill_sources; sync_skills; local rc=$?; apply_overlays; apply_skill_activation || rc=1; apply_skill_cap || rc=1; return "$rc"; }
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
  # Retention was missing, so each run left its private dir behind forever (58
  # dirs, 7 MB, after two months). Keep the newest few, delete only our own dirs.
  # Trailing slash keeps this to directories, so a run report file survives.
  find "$LOG_DIR" -maxdepth 1 -type d -name 'update-all-*' 2>/dev/null \
    | sort -r | tail -n +11 | xargs -r rm -rf
  local shared_log="$LOG"
  LOG="$RUN_DIR/update-all.log"
  CHECKLIST_TMP="$RUN_DIR/checklist.tsv"
  mkdir -p "$UPDATER_SRC"
  checklist_init
  log "update-all started (dry_run=$DRY parallel=$PARALLEL); private run: $RUN_DIR"
  # Prerequisites and the symlink fleet come first and are named: a fresh machine
  # used to discover them as eight unrelated phase failures, and the fleet used to
  # not exist at all.
  local pre_rc=0
  local -a phases=()
  preflight || pre_rc=1
  [ "$pre_rc" != 0 ] || bootstrap_links || pre_rc=1
  if [ "$pre_rc" = 0 ]; then
    [ "$DO_JCODE" = 0 ] || phases+=(update_core_phase)
    [ "$DO_SKILLS" = 0 ] || phases+=(update_skills)
    [ "$DO_PI" = 0 ] || phases+=(generate_pi_agents)
    [ "$DO_PATCHES" = 0 ] || phases+=(apply_pi_patches)
    [ "$DO_TOOLS" = 0 ] || phases+=(update_tools)
    if [ "${#phases[@]}" -gt 0 ]; then
      run_jobs "${phases[@]}"
      rc=$?
    fi
    # Configs and the manifest are INDEPENDENT of core (finding 1): every file they
    # install exists in the repo, and the old `if [ rc = 0 ]` gate meant a fresh
    # machine — where core can never pass without `jcode self-dev --setup` —
    # installed ZERO configs and reported "skip configs/manifest (earlier phase
    # failed)". They always run now, and each step fails on its own precondition.
    phases=()
    [ "$DO_CONFIG" = 0 ] || phases+=(sync_configs)
    [ "$DO_MANIFEST" = 0 ] || phases+=(write_manifest audit_skills)
    if [ "${#phases[@]}" -gt 0 ]; then
      PARALLEL=0
      run_jobs "${phases[@]}" || rc=1
    fi
  else
    checklist_add skip "all phases (prerequisites or symlink fleet failed: see ERROR lines)"
    rc=1
  fi
  if grep -q '^fail' "$CHECKLIST_TMP"; then rc=1; fi
  # A dry run must not touch durable state. Writing CHECKLIST.md or clobbering
  # the shared log here destroyed the record of the last REAL run, so a dry run
  # silently erased the history it was supposed to be previewing. Keep dry-run
  # output in the throwaway RUN_DIR only.
  if [ "$DRY" = 1 ]; then
    log "DRY: not writing $CHECKLIST or $shared_log (dry-run leaves no state)"
  else
    mkdir -p "$(dirname "$CHECKLIST")"
    checklist_write "$rc"
    log "update-all finished (exit=$rc); restart/reload only successful updates"
    cp "$LOG" "$shared_log" || rc=1
  fi
  flock -u 9
  exec 9>&-
  return "$rc"
}

# --- main -------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
