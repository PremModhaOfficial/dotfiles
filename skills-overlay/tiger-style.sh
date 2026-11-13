#!/usr/bin/env bash
# tiger-style — the Precedence block is ours, not upstream's. A sync overwrites
# SKILL.md and the tiger-style clone has no such section, so without this the
# next update-all silently drops every precedence, floor and switch rule in it.
# Idempotent when the installed block matches the pinned md5: it then writes the
# marker and exits 0. Only real drift or a missing anchor refuses. Drift, a second block or a
# missing anchor exits non-zero with a printed reason and leaves the marker
# untouched, so update-all records a failed overlay instead of logging OK. Touches
# only SKILL.md, then .overlay-applied.
# Contract: see apply_overlays() in ~/dotfiles/jcode/update-all.sh.
set -uo pipefail

SD="${SKILL_DIR:-$PWD}"
F="$SD/SKILL.md"
MARK="$SD/.overlay-applied"
SKILL_NAME=tiger-style
warn() { echo "OVERLAY-WARN: tiger-style: $*"; }

[ -f "$F" ] || { warn "no SKILL.md in $SD"; exit 3; }
cd "$SD" || { warn "cannot cd $SD"; exit 3; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 3; }
trap 'rm -rf "$tmp"' EXIT

# anchor and canonical block, as literal files. Skipped when the block is
# already canonical. The heredocs
# carry a trailing newline; strip it so the anchor stays one line and the block
# joins it with exactly one blank line.
cat > "$tmp/old" <<'OLD'
## The Protocol
OLD
cat > "$tmp/new" <<'NEW'
## Precedence

Across layers, stacked modes all stay on: each keeps its own layer, and starting a mode in one layer never removes a mode in another. Safety floor first: an explicit floor in any active mode survives every conflict below, and this list is the whole of it — a "never cut" list (ponytail, ultracave, megacave); caveman's ASD-STE100 floor (20 words max, active voice, kept negations) and verbatim payload; tiger-style's two-assertions-per-function minimum, fixed loop bounds, and "never slow-path safety for developer convenience"; ds-mode's pause before an irreversible action; i-have-adhd's "never omit relevant items" and "safety wins over brevity"; archify's validation before delivery. Work rules (ponytail, ds-mode, tiger-style) beat output rules (caveman, ultracave, megacave, i-have-adhd, archify): what to build outranks how it reads.
Two conflicts are settled here rather than by the last-wins rule below. Where ds-mode's "delete before you add" meets a tiger-style assertion minimum or loop bound, tiger-style wins: delete something else, or say why the deletion is elsewhere. Where an archify page would be made unasked (`proactive` or `always-on`) under ponytail, caveman, ultracave or megacave, the page is offered, not made, because an unrequested page is output nobody asked for.
Within one layer only one voice is on at a time: a second mode in the same layer replaces the first, and in the caveman family the last voice chosen replaces the earlier one — voices never stack. The replaced mode's floor still holds, because floors cross layers.
Clean switch: "stop ponytail", "stop caveman", "stop ultracave", "stop megacave", "stop adhd mode", "stop tiger-style", "stop ds-mode" each drop one mode; "normal mode" drops all of them. archify's `proactive` and `always-on` are rule lines in the host's rules file, switched on by its consent flow and off by deleting the line; `on-demand` is the default, its line only stopping the offer from recurring.

## The Protocol
NEW

# ensure_block <oldfile> <newfile>: exactly one canonical block, or a non-zero
# exit with the reason. A drifted block is never "repaired" by inserting a second
# copy: that forks the rules, and the pin would then measure the fresh copy and
# pass. Non-zero is read by apply_overlays() in ~/dotfiles/jcode/update-all.sh
# (checklist fail -> run exit 1); skills-audit check 6 only stats the marker.
ensure_block() {
  python3 - "$F" "$1" "$2" "$SKILL_NAME" <<'PY'
import hashlib, sys
f, o, n, name = sys.argv[1:5]
src = open(f, encoding="utf-8").read()
old = open(o, encoding="utf-8").read().rstrip("\n")
new = open(n, encoding="utf-8").read().rstrip("\n")
def blockof(s):
    ls = s.splitlines()
    i = next(i for i, l in enumerate(ls) if l.strip() == "## Precedence")
    j = next(k for k in range(i, len(ls)) if ls[k].startswith("Clean switch:"))
    return "\n".join(ls[i:j + 1])

block = blockof(new)
want = hashlib.md5((block + "\n\n").encode()).hexdigest()
lines = src.splitlines()
hdrs = [i for i, l in enumerate(lines) if l.strip() == "## Precedence"]

def die(msg, rc):
    print("OVERLAY-WARN: %s: %s" % (name, msg))
    sys.exit(rc)

if len(hdrs) > 1:
    die("%d Precedence blocks already present, expected 1; refusing to insert another" % len(hdrs), 2)
if len(hdrs) == 1:
    i = hdrs[0]
    tail = [k for k in range(i, len(lines)) if lines[k].startswith("Clean switch:")]
    if not tail:
        die("existing Precedence block has no 'Clean switch:' line; refusing to touch it", 2)
    cur = "\n".join(lines[i:tail[0] + 1])
    got = hashlib.md5((cur + "\n\n").encode()).hexdigest()
    # Compare the pinned md5, not the bytes: an already-applied block must never
    # exit non-zero, or the marker is never written and the audit stays red.
    if got == want:
        print("already applied: block md5 " + want)
        sys.exit(0)
    die("Precedence block drifted: %s != %s; refusing to insert a second copy" % (got, want), 2)
if old not in src:
    die("anchor not found and no Precedence block present: " + old.splitlines()[0][:60], 3)
open(f, "w", encoding="utf-8").write(src.replace(old, new, 1))
n2 = [i for i, l in enumerate(open(f, encoding="utf-8").read().splitlines()) if l.strip() == "## Precedence"]
if len(n2) != 1:
    die("after insert: %d Precedence blocks, expected 1" % len(n2), 2)
print("apply ok: " + new.splitlines()[0][:70] + " | block md5 " + want)
PY
}

rc=0
ensure_block "$tmp/old" "$tmp/new" || rc=$?
[ "$rc" -eq 0 ] || { warn "not patched (exit $rc); .overlay-applied NOT touched"; exit "$rc"; }
touch "$MARK"
echo "overlay done: $SD"
