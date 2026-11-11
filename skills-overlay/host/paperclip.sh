#!/usr/bin/env bash
# skills-overlay/host/paperclip.sh (host-installed skill: NOT under ~/.agents/skills, so the
# runner glob skills-overlay/*.sh skips it on purpose — a full-tree run still exits 0) — contract: ~/.jcode/scratch/skills-audit/overlay-spec.md
# Why: SKILL.md tells you to verify writes with scripts/paperclip-issue-update.sh, but
# the installed package ships only scripts/paperclip-upload-artifact.sh. The skill's own
# hand-rolled curl rule (HTTP code + echoed field) already carries the requirement, so it
# is kept and the dead helper is replaced with a working jq/curl example.
# NOTE: the installed paperclip skill is a symlink into the paperclipai npm package
# (~/.pi/agent/skills/paperclip, ~/.claude/skills/paperclip), not under ~/.agents/skills.
# This overlay runs against whatever dir it is handed and refuses to patch any other skill.
# Idempotent. Touches only $SKILL_DIR/SKILL.md, then $SKILL_DIR/.overlay-applied.
set -uo pipefail

SD="${SKILL_DIR:-$PWD}"
MARK_NAME=".overlay-applied"
warn() { echo "OVERLAY-WARN: paperclip: $*"; }

REAL=$(cd "$SD" 2>/dev/null && pwd -P) || { warn "cannot resolve $SD"; exit 0; }
case "$REAL" in
  */skills/paperclip) : ;;
  *) warn "refusing: $REAL is not a paperclip skill dir"; exit 0 ;;
esac
F="$REAL/SKILL.md"
MARK="$REAL/$MARK_NAME"
[ -f "$F" ] || { warn "no SKILL.md in $REAL"; exit 0; }
( : > "$REAL/.overlay-probe" ) 2>/dev/null && rm -f "$REAL/.overlay-probe" ||
  { warn "not writable: $REAL"; exit 0; }
cd "$REAL" || { warn "cannot cd $REAL"; exit 0; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 0; }
trap 'rm -rf "$tmp"' EXIT

# patch <oldfile> <newfile>: one literal replacement, skipped when already applied
patch() {
  python3 - "$F" "$1" "$2" <<'PY'
import sys
f, o, n = sys.argv[1:4]
p = open(f, encoding="utf-8").read()
old = open(o, encoding="utf-8").read()
new = open(n, encoding="utf-8").read()
if new in p:
    print("skip  already applied: " + new.splitlines()[0][:70]); sys.exit(0)
if old not in p:
    print("OVERLAY-WARN: paperclip: anchor not found: " + old.splitlines()[0][:70]); sys.exit(0)
open(f, "w", encoding="utf-8").write(p.replace(old, new, 1))
print("apply ok: " + new.splitlines()[0][:70])
PY
}

cat > "$tmp/old" <<'OLD'
Use `scripts/paperclip-issue-update.sh` (it checks the HTTP status, retries connection-level failures, and confirms the echoed `status`); if you must hand-roll curl, capture `-w '%{http_code}'` and check the response echoes your update. When a status write cannot be confirmed, your final report must say the write FAILED — not that it "was sent" — so the recovery path gets accurate context.
OLD
cat > "$tmp/new" <<'NEW'
This package ships no update helper (`scripts/` contains only `paperclip-upload-artifact.sh`), so hand-roll the request: capture `-w '%{http_code}'`, treat anything but 2xx as a failed write, check the response echoes your update, and retry connection-level failures instead of assuming success. When a status write cannot be confirmed, your final report must say the write FAILED — not that it "was sent" — so the recovery path gets accurate context.
NEW
patch "$tmp/old" "$tmp/new"

cat > "$tmp/old" <<'OLD'
```bash
scripts/paperclip-issue-update.sh --issue-id "$PAPERCLIP_TASK_ID" --status done <<'MD'
Done

- Fixed the newline-preserving issue update path
- Verified the raw stored comment body keeps paragraph breaks
MD
```
OLD
cat > "$tmp/new" <<'NEW'
```bash
jq -n --rawfile comment /dev/stdin --arg status done '{status: $status, comment: $comment}' <<'MD' |
  curl -sS -X PATCH "$PAPERCLIP_API_URL/api/issues/$PAPERCLIP_TASK_ID" \
    -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
    -H "X-Paperclip-Run-Id: $PAPERCLIP_RUN_ID" \
    -H 'Content-Type: application/json' --data-binary @- -w '\n%{http_code}\n'
Done

- Fixed the newline-preserving issue update path
- Verified the raw stored comment body keeps paragraph breaks
MD
```
NEW
patch "$tmp/old" "$tmp/new"

cat > "$tmp/old" <<'OLD'
Use the helper below (or an equivalent `jq --arg` pattern reading from a heredoc/file) so literal newlines survive JSON encoding:
OLD
cat > "$tmp/new" <<'NEW'
Use the `jq --arg`/`--rawfile` pattern below (or an equivalent reading from a heredoc/file) so literal newlines survive JSON encoding:
NEW
patch "$tmp/old" "$tmp/new"

touch "$MARK"
echo "overlay done: $REAL"
