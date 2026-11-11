#!/usr/bin/env bash
# skills-overlay/tiger-style-help.sh — contract: ~/.jcode/scratch/skills-audit/overlay-spec.md
# Why: documents TIGER_STYLE_DEFAULT_MODE / ~/.config/tiger-style/config.json as if a plain
# install reads them (only the repo's hooks/tiger-config.js does, and it is not
# installed), and promises a `/tiger-style off` mode the skill's own level list
# (lite|full|strict) does not define.
# Idempotent: a patch is skipped when its new text is already present.
# Touches only $SKILL_DIR/SKILL.md, then $SKILL_DIR/.overlay-applied.
set -uo pipefail

SD="${SKILL_DIR:-$PWD}"
F="$SD/SKILL.md"
MARK="$SD/.overlay-applied"
warn() { echo "OVERLAY-WARN: tiger-style-help: $*"; }

[ -f "$F" ] || { warn "no SKILL.md in $SD"; exit 0; }
cd "$SD" || { warn "cannot cd $SD"; exit 0; }

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
    print("OVERLAY-WARN: tiger-style-help: anchor not found: " + old.splitlines()[0][:70]); sys.exit(0)
open(f, "w", encoding="utf-8").write(p.replace(old, new, 1))
print("apply ok: " + new.splitlines()[0][:70])
PY
}

cat > "$tmp/old" <<'OLD'
Say "stop tiger-style" or "normal mode". Resume anytime with `/tiger-style`.
`/tiger-style off` also works.
OLD
cat > "$tmp/new" <<'NEW'
Say "stop tiger-style" or "normal mode". Resume anytime with `/tiger-style`.

There is no `off` level — the skill's levels are lite, full and strict only — so
`/tiger-style off` is not a trigger. Deactivate with the phrases above.
NEW
patch "$tmp/old" "$tmp/new"

cat > "$tmp/old" <<'OLD'
Default mode = `full`, auto-active every session. Change it:

**Environment variable** (highest priority):
```bash
export TIGER_STYLE_DEFAULT_MODE=strict
```

**Config file** (`~/.config/tiger-style/config.json`, Windows: `%APPDATA%\tiger-style\config.json`):
```json
{ "defaultMode": "lite" }
```

Set `"off"` to disable auto-activation on session start, activate manually
with `/tiger-style` when wanted.

Resolution: env var > config file > `full`.
OLD
cat > "$tmp/new" <<'NEW'
Default mode = `full`, auto-active every session.

**Pass the level as an argument** — this is the only mechanism a plain skill
install reads:
```
/tiger-style lite
/tiger-style strict
```

**Environment variable and config file** are read only when the Tiger Style
plugin hooks are installed (the repo's `hooks/tiger-config.js`, in
https://github.com/PremModhaOfficial/tiger-style). Without those hooks nothing
reads them, so exporting the variable or writing the file changes nothing:

```bash
export TIGER_STYLE_DEFAULT_MODE=strict
```

Config file (`~/.config/tiger-style/config.json`, Windows:
`%APPDATA%\tiger-style\config.json`), read by those hooks only:
```json
{ "defaultMode": "lite" }
```

With the hooks installed, `"off"` in that file turns auto-activation off at
session start, and you activate manually with `/tiger-style` when wanted. That
is a config value for the hooks, not a `/tiger-style off` trigger.

Resolution (hooks only): env var > config file > `full`.
NEW
patch "$tmp/old" "$tmp/new"

touch "$MARK"
echo "overlay done: $SD"
