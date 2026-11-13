#!/usr/bin/env bash
# ============================================================================
# apply-pi-patches — re-apply ~/dotfiles/pi-patches to the local pi install.
#
#   Canonical location: ~/dotfiles/jcode/apply-pi-patches.sh
#
#   pi is installed from npm, so an upgrade overwrites its dist/ tree and
#   silently drops every fix we keep in ~/dotfiles/pi-patches/. This runs after
#   such an upgrade (and from update-all.sh) to put them back.
#
#   Each patch declares in its header, once per file it touches:
#     # target: <path relative to the pi package root>
#     # pristine-sha256: <sha256 of that file before the patch>
#   The sha is how this script knows the state instead of guessing:
#     pristine       -> apply the patch
#     patched        -> skip (this is what makes a second run a no-op)
#     anything else  -> FAIL LOUDLY: an upgrade changed the file, so the patch
#                       needs a refresh; applying it blind would corrupt the tree
#
#   Usage:
#     ~/dotfiles/jcode/apply-pi-patches.sh             # apply what is missing
#     ~/dotfiles/jcode/apply-pi-patches.sh --dry-run   # report, write nothing
#     ~/dotfiles/jcode/apply-pi-patches.sh --revert    # restore pristine bytes
#
#   Exit: 0 applied/no-op, 1 error, 3 no pi install found (a skip, not a
#   failure: a machine without pi has nothing to patch and update-all.sh
#   reports that instead of failing the run).
# ============================================================================

set -uo pipefail

# Sourced, not copied: the candidate list (npm root -g plus the common prefixes)
# lives in pi-root.sh so the escape test and this script cannot disagree.
# shellcheck source=pi-root.sh
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/pi-root.sh"
# The patches belong to this repo, wherever it is cloned; ~/dotfiles is only the
# conventional location.
PATCH_DIR="${PATCH_DIR:-$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)/pi-patches}"

DRY=0
REVERT=0

log() { echo "apply-pi-patches: $*"; }
fail() { echo "apply-pi-patches: ERROR: $*" >&2; exit 1; }

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --revert) REVERT=1 ;;
    *) fail "unknown arg: $arg (use --dry-run or --revert)" ;;
  esac
done

if [ -z "${PI_ROOT:-}" ]; then
  if ! PI_ROOT=$(resolve_pi_root); then
    echo "apply-pi-patches: SKIP: no pi install found; tried:" >&2
    pi_root_candidates | sed 's/^/  /' >&2
    echo "apply-pi-patches: install pi, or export PI_ROOT=<package root>" >&2
    exit 3
  fi
fi
[ -d "$PI_ROOT" ] || fail "no pi install at $PI_ROOT (set PI_ROOT to override)"
[ -d "$PATCH_DIR" ] || fail "no patch dir at $PATCH_DIR"
command -v git >/dev/null || fail "git not found (git apply does the patching)"
command -v sha256sum >/dev/null || fail "sha256sum not found"

# git apply both applies and checks; --check makes it read-only, -R reverses.
# Run it against the patch file from the pi root so --include matches patch paths.
apply_file() { # apply_file <patch> <target> <check|-R-check|apply|-R-apply>
  local patch="$1" target="$2" mode="$3"
  case "$mode" in
    # Probes are expected to fail on a mismatch; silence git and report our own
    # reason instead of its two lines of "patch does not apply" noise.
    check)     git -C "$PI_ROOT" apply --check --include="$target" -p1 "$patch" 2>/dev/null ;;
    rcheck)    git -C "$PI_ROOT" apply --check -R --include="$target" -p1 "$patch" 2>/dev/null ;;
    apply)     git -C "$PI_ROOT" apply --include="$target" -p1 "$patch" ;;
    revert)    git -C "$PI_ROOT" apply -R --include="$target" -p1 "$patch" ;;
  esac
}

sha() { sha256sum "$1" | cut -d' ' -f1; }

changed=0
skipped=0

shopt -s nullglob
patches=("$PATCH_DIR"/*.patch)
shopt -u nullglob
[ "${#patches[@]}" -gt 0 ] || fail "no *.patch in $PATCH_DIR"

for patch in "${patches[@]}"; do
  name=$(basename "$patch")
  # Pairs of (target, pristine sha) from the header, in file order.
  pairs=$(awk '/^# target: /{t=$3} /^# pristine-sha256: /{print t, $3}' "$patch")
  [ -n "$pairs" ] || fail "$name has no '# target:' / '# pristine-sha256:' header pins"

  while read -r target pristine; do
    [ -n "$target" ] || fail "$name: target/sha header pins are not paired"
    file="$PI_ROOT/$target"
    [ -f "$file" ] || fail "$name: missing $file (pi install layout changed?)"
    current=$(sha "$file")

    if [ "$REVERT" = 1 ]; then
      if [ "$current" = "$pristine" ]; then
        log "$name: $target already pristine, no-op"
        skipped=$((skipped + 1))
      elif apply_file "$patch" "$target" rcheck; then
        if [ "$DRY" = 1 ]; then
          log "DRY: would revert $target (sha $current -> $pristine)"
        else
          apply_file "$patch" "$target" revert || fail "$name: revert of $target failed"
          [ "$(sha "$file")" = "$pristine" ] || fail "$name: $target did not return to its pristine bytes"
          log "reverted $target (sha $(sha "$file"))"
        fi
        changed=$((changed + 1))
      else
        # Neither pristine nor reverse-appliable: an upgrade replaced it, or
        # someone hand-edited it. Restoring would be a guess, so stop.
        fail "$name: $target is neither pristine nor patched (sha $current); restore or refresh the patch by hand"
      fi
      continue
    fi

    if [ "$current" = "$pristine" ]; then
      if [ "$DRY" = 1 ]; then
        log "DRY: would apply $name to $target (sha $current)"
      else
        apply_file "$patch" "$target" apply || fail "$name: applying to $target failed"
        apply_file "$patch" "$target" rcheck || fail "$name: $target did not verify as patched after applying"
        log "applied $name to $target (sha $(sha "$file"))"
      fi
      changed=$((changed + 1))
    elif apply_file "$patch" "$target" rcheck; then
      log "$name: $target already patched, no-op"
      skipped=$((skipped + 1))
    else
      # The whole point: a changed upstream file must not be patched silently
      # and must not be skipped as if it were already done.
      fail "$name: $target is not the pinned pristine file (sha $current != $pristine) and the patch does not reverse; a pi upgrade changed it, refresh the patch"
    fi
  done <<< "$pairs"
done

if [ "$DRY" = 1 ]; then
  log "dry run: $changed file(s) would change, $skipped already in the target state"
else
  log "done: $changed file(s) changed, $skipped already in the target state"
fi
exit 0
