#!/usr/bin/env bash
# caveman-help — three fixes a re-sync would otherwise wipe:
#   1. README links up to the repo root (../../), which is outside the install.
#      Rewrite them to their upstream URLs; sed only matches the relative form,
#      so a second run changes nothing.
#   2. The skill table routes to caveman-review only and describes it as
#      safety-tagged PR comments, which is tiger-style-review's job. Our copy
#      lists both with their real triggers; re-apply it or the next sync of
#      JuliusBrussee/caveman drops the row.
#   3. "Configure Default Mode" prescribes CAVEMAN_DEFAULT_MODE and
#      ~/.config/caveman/config.json, and nothing on this host reads either
#      (no caveman hook in ~/.claude/settings.json, no reader in the
#      installed @caveman-ai/cli). Replaced with how the mode is really
#      chosen, so the card stops prescribing a no-op.
# Idempotent: the sed is grep-guarded, a patch is skipped when its new text is
# already present. Touches only README.md, SKILL.md, then .overlay-applied.
# Contract: see apply_overlays() in ~/dotfiles/jcode/update-all.sh.
set -uo pipefail

# patch() is shared: jcode/overlay-lib.sh and resolved from this script's
# directory before any cd, so a relative invocation still finds it. A missing
# anchor is a non-zero exit with no marker, never a silent pass, and a lib that
# cannot be found fails here instead of falling through to the system `patch`.
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../jcode/overlay-lib.sh"
[ -f "$LIB" ] || { echo "OVERLAY-WARN: ${0##*/}: missing $LIB" >&2; exit 3; }
. "$LIB"

fix_ref() { # fix_ref <repo-relative-path>: ../../<path> -> upstream URL
  local p esc
  p="$1"
  [ -f README.md ] || { echo "OVERLAY-WARN: no README.md in $SKILL_DIR"; return 0; }
  grep -qF "../../$p" README.md || return 0
  esc=$(printf '%s' "$p" | sed 's/[.[*^$\\]/\\&/g')
  sed -i "s|\.\./\.\./$esc|https://github.com/JuliusBrussee/caveman/blob/main/$p|g" README.md
  echo "OVERLAY: README.md ../../$p -> upstream URL"
}

fix_ref README.md

SD="${SKILL_DIR:-$PWD}"
F="$SD/SKILL.md"
MARK="$SD/.overlay-applied"
warn() { echo "OVERLAY-WARN: caveman-help: $*"; }

[ -f "$F" ] || { warn "no SKILL.md in $SD"; exit 3; }
cd "$SD" || { warn "cannot cd $SD"; exit 3; }

tmp=$(mktemp -d) || { warn "mktemp failed"; exit 3; }
trap 'rm -rf "$tmp"' EXIT


cat > "$tmp/old" <<'OLD'
| **caveman-review** | `/caveman-review` | One-line PR comments: `L42: bug: user null. Add guard.` |
OLD
cat > "$tmp/new" <<'NEW'
| **tiger-style-review** | `/tiger-style-review` | One-line PR comments: `L42: assert: user null after find. Add guard.` Safety tags only. |
| **caveman-review** | `/caveman-review` | Terse review of any diff: `L42: 🔴 bug: user can be null after .find(). Add guard before .email.` |
NEW
patch "$tmp/old" "$tmp/new"

cat > "$tmp/old" <<'OLD'
## Configure Default Mode

Default mode = `caveman`. Change it:

**Environment variable** (highest priority):
```bash
export CAVEMAN_DEFAULT_MODE=ultracave
```

**Config file** (`~/.config/caveman/config.json`):
```json
{ "defaultMode": "ultracave" }
```

For opt-in activation in Claude Code, set `defaultMode` to `manual`. Sessions start off; `/skill:caveman` or `talk like caveman` activates caveman. `off` also disables bare-command activation. `manual` is a startup policy, not a mode. OpenCode still starts in caveman mode because its installer also supplies static activation rules.

Set `"off"` to suppress automatic and bare-command activation. Use `"manual"` when bare `/skill:caveman` should activate.

Resolution: env var > repo config > user config > `caveman`. Legacy values `lite`, `full`, `ultra`, `wenyan*` still resolve.
OLD
cat > "$tmp/new" <<'NEW'
## Choosing the mode

No mode is stored and nothing reads a setting, so the mode is whichever skill is loaded: `/skill:caveman`, `/skill:ultracave` (alias `/skill:caveman ultra`) or `/skill:megacave` (alias `/skill:caveman wenyan`), or just say "talk like caveman". It holds for the session; "stop caveman" or "normal mode" ends it, and a new session starts in no mode.

Upstream does carry a `defaultMode` resolver — `CAVEMAN_DEFAULT_MODE`, then repo `.caveman/config.json`, then user `~/.config/caveman/config.json`, default `caveman` — in `src/hooks/caveman-config.js`. Only its Claude Code hook scripts and its OpenCode plugin read it, and neither is installed here: `~/.claude/settings.json` has no caveman hook, there is no OpenCode caveman plugin, and the installed `@caveman-ai/cli` bundle contains no reader. Exporting that variable or writing that file changes nothing on this host; say so rather than implying a default moved. `lite`, `full`, `ultra`, `wenyan*` are legacy aliases of the modes above.
NEW
# The card claimed a configurable default that nothing on this host reads;
# a missing anchor is drift, so re-read upstream instead of trusting the text.
patch "$tmp/old" "$tmp/new" "## Choosing the mode"

touch "$MARK"
echo "overlay done: $SD"
