#!/usr/bin/env bash
# skills-overlay/claude-handoff.sh — contract: ~/.jcode/scratch/skills-audit/overlay-spec.md
# Why: built on `claude --bg --name ...`; the `claude` CLI is not installed on this host
# (pi, codex, cmd, opencode are). Keep it harness-neutral and use flags that exist:
# `pi -n/--name` and `-p/--print` (verified with `pi --help`).
# Idempotent: a patch is skipped when its new text is already present.
# Touches only $SKILL_DIR/SKILL.md, then $SKILL_DIR/.overlay-applied.
set -uo pipefail

SD="${SKILL_DIR:-$PWD}"
F="$SD/SKILL.md"
MARK="$SD/.overlay-applied"
warn() { echo "OVERLAY-WARN: claude-handoff: $*"; }

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
    print("OVERLAY-WARN: claude-handoff: anchor not found: " + old.splitlines()[0][:70]); sys.exit(0)
open(f, "w", encoding="utf-8").write(p.replace(old, new, 1))
print("apply ok: " + new.splitlines()[0][:70])
PY
}

cat > "$tmp/old" <<'OLD'
Write a handoff summary of the current conversation so a fresh agent can continue the work. Save it to the temporary directory of the user's OS, then launch a background agent seeded with it as its prompt: `claude --bg --name "<descriptive name>" -- "$(cat <summary file>)"`. Passing the file keeps the shell from running backticks or expanding `$` in the summary. It starts in the current working directory and returns immediately; the user manages it with `claude agents`.

Always pass `-n`/`--name` with a descriptive name (e.g. `--name "Fix login bug"`); it sets the display name shown in the job list, session picker, and terminal title.
OLD
cat > "$tmp/new" <<'NEW'
Write a handoff summary of the current conversation so a fresh agent can continue the work. Save it to the temporary directory of the user's OS, then launch a fresh agent seeded with it as its prompt. Any installed agent CLI works; this card uses `pi` as the example (confirm it is there with `command -v pi`):

```bash
pi -n "<descriptive name>" -p "$(cat <summary file>)"
```

`-p`/`--print` runs non-interactively and exits when the run finishes; add a trailing `&` to keep working while it runs. It starts in the current working directory. Passing the file keeps the shell from running backticks or expanding `$` in the summary. The user finds the run again with `pi --resume`.

Always pass `-n`/`--name` with a descriptive name (e.g. `--name "Fix login bug"`); on `pi` it sets the session display name shown in the session picker and terminal title. For another agent CLI (`pi`, `codex`, `cmd`, `opencode`), take its own name and non-interactive flags from `--help` — do not reuse `pi`'s flags on a different binary.
NEW
patch "$tmp/old" "$tmp/new"

touch "$MARK"
echo "overlay done: $SD"
