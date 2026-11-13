#!/usr/bin/env bash
# ============================================================================
# overlay-lib.sh — the patch() every skills-overlay/*.sh shares.
#
# Sourced, never executed (`apply_overlays()` in ~/dotfiles/jcode/update-all.sh
# runs every *.sh in skills-overlay/ and skills-overlay/host/ as an overlay, so
# a helper cannot live there). $F must be set by the caller: the SKILL.md being
# patched.
#
# Why one implementation: 15 overlays each carried their own copy of a
# forward-only patch() that printed "anchor not found" and then `sys.exit(0)`.
# Exit 0 read as "applied", the script went on to `touch .overlay-applied`, and
# an upstream sync that dropped the anchor was recorded as patched - the card
# silently lost the fix and every run logged the same warning as noise. The
# failure mode was the whole file, not one overlay, so it is fixed here once.
#
# Outcomes, never a silent pass:
#   0  new text already present (skip) or just applied
#   2  drift: the caller named a `present` marker, it is in the file, and
#      neither the anchor nor our text is - the section was edited by hand
#   3  anchor missing: neither the anchor nor our text is in the file
# Non-zero is propagated below, which exits the calling script, so a failed
# patch can never reach its `touch "$MARK"`. The overlays run without `set -e`;
# that propagation is what makes this true.
#
# Comparison is done in the form skills-activation.py writes (skill_slash.py),
# because both rewrite the same cards: an overlay that matched raw text would
# read its own applied patch as drift on the next run.
# ============================================================================
set -uo pipefail

# The overlay's own name, for the log line. $0 is the overlay, because
# apply_overlays() runs `bash <script>` and a standalone run looks the same.
SKILL_NAME=${SKILL_NAME:-$(basename "$0" .sh)}

patch() { # patch <oldfile> <newfile> [present-marker]
  python3 - "$F" "$1" "$2" "${3:-}" "$SKILL_NAME" "$(dirname "${BASH_SOURCE[0]}")" <<'PY'
import importlib.util, os, sys
f, o, n, present, name, jcode = sys.argv[1:7]
spec = importlib.util.spec_from_file_location(
    "skill_slash", os.path.join(jcode, "skill_slash.py"))
ss = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ss)
names = ss.skill_names()
p = ss.normalize(open(f, encoding="utf-8").read(), names)
old = ss.normalize(open(o, encoding="utf-8").read().rstrip("\n"), names)
new = ss.normalize(open(n, encoding="utf-8").read().rstrip("\n"), names)
if new in p:
    print("skip  already applied: " + new.splitlines()[0][:70]); sys.exit(0)
if old in p:
    open(f, "w", encoding="utf-8").write(p.replace(old, new, 1))
    print("apply ok: " + new.splitlines()[0][:70]); sys.exit(0)
if present and present in p:
    print("OVERLAY-WARN: %s: drift: patched section present but edited; "
          "neither the anchor nor our text matches: %s"
          % (name, old.splitlines()[0][:70])); sys.exit(2)
print("OVERLAY-WARN: %s: anchor not found: %s"
      % (name, old.splitlines()[0][:70])); sys.exit(3)
PY
  local rc=$?
  [ "$rc" -eq 0 ] || exit "$rc"
}
