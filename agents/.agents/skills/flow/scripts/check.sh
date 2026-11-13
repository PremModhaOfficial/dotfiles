#!/usr/bin/env bash
# Asserts the flow skill's rules file and that every skill it names is installed.
set -uo pipefail
S="${HOME}/.agents/skills/flow"
R="$S/rules.md"
fail=0
note() { printf 'FAIL: %s\n' "$*"; fail=1; }

# 1. rules file exists and every row matches the format, one physical line each
if [ ! -f "$R" ]; then
  note "missing $R"
else
  rx='^- [0-9]{4}-[0-9]{2}-[0-9]{2} \| [^|]+$'
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    printf '%s\n' "$line" | grep -Eq "$rx" || note "bad rule line: $line"
  done < "$R"
  n=$(grep -c '^- ' "$R" || true)
  [ "${n:-0}" -le 15 ] || note "rules.md has $n rules, cap 15"
fi

# 2. every skill named in SKILL.md is installed (EGM bundle resolved by glob)
egm=$(ls -d "$HOME"/.pi/agent/git/github.com/*/elephant-goldfish-model/skills 2>/dev/null | head -1)
[ -n "$egm" ] && echo "note: EGM skills at $egm"
for s in $(grep -oE '`[a-z][a-z0-9]*(-[a-z0-9]+)*`' "$S/SKILL.md" | tr -d '`' | sort -u); do
  [ -d "${HOME}/.agents/skills/$s" ] && continue
  [ -n "$egm" ] && [ -d "$egm/$s" ] && continue
  note "skill named but not installed: $s"
done

[ "$fail" -eq 0 ] && echo "OK: flow rules and skill references valid"
exit "$fail"
