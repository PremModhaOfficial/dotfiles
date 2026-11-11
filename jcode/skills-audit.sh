#!/usr/bin/env bash
# Skills audit — one deterministic pass over the installed tree.
#
#   bash ~/dotfiles/jcode/skills-audit.sh [--quiet]
#
# Exit 0 clean, 1 issues found. Run by update-all.sh after the manifest, so a
# skill added upstream cannot silently break routing, links, or attribution
# again: every check here failed at least once on this machine.
set -uo pipefail

SKILLS_DIR="$HOME/.agents/skills"
# Skills a host installs elsewhere (pi's npm-packaged ones); their overlays live
# in skills-overlay/host/ and patch these dirs instead.
HOST_SKILLS_DIR="$HOME/.pi/agent/skills"
MANIFEST="$SKILLS_DIR/README.md"
LEDGER="$HOME/.jcode/state/upstream-sources"
[ "${1:-}" = "--quiet" ] && QUIET=1 || QUIET=0

# Findings go to a file: most checks run inside pipes, where a counter would be
# lost in the subshell.
findings=$(mktemp)
trap 'rm -f "$findings"' EXIT
bad() { printf '%s\n' "$*" >> "$findings"; }

# description of a SKILL.md, flattened: YAML block scalars (">", "|") span lines.
describe() {
  awk '
    /^description:/ {
      v = $0; sub(/^description:[[:space:]]*/, "", v)
      if (v ~ /^[|>][-+]?$/) { block = 1; next }
      print v; exit
    }
    block && /^[A-Za-z_][A-Za-z0-9_-]*:/ { exit }
    block { gsub(/^[[:space:]]+/, ""); d = (d == "" ? $0 : d " " $0); next }
  ' "$1"
}

# 1. frontmatter: harness scanners route on name + description, and a name that
#    disagrees with its directory makes the skill unfindable by id.
for dir in "$SKILLS_DIR"/*/; do
  name=$(basename "$dir")
  f="$dir/SKILL.md"
  if [ ! -f "$f" ]; then
    [ -n "$(ls -A "$dir" 2>/dev/null)" ] && bad "no SKILL.md in $dir (dir reads as a broken skill)"
    continue
  fi
  head -1 "$f" | grep -qx -- '---' || bad "$f: frontmatter does not start at line 1"
  grep -qm1 '^name:' "$f" || bad "$f: no name: in frontmatter"
  grep -qm1 '^description:' "$f" || bad "$f: no description: in frontmatter (cannot be routed)"
  fm_name=$(awk 'NR>1 && /^name:/{print $2; exit}' "$f")
  [ -z "$fm_name" ] || [ "$fm_name" = "$name" ] || bad "$f: name '$fm_name' != dir '$name'"
done

# 2. duplicate routing: two skills with the same description both fire on the
#    same request and the user gets whichever loads first.
for f in "$SKILLS_DIR"/*/SKILL.md; do
  d=$(describe "$f" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ' | sed 's/ *$//')
  [ -n "$d" ] && printf '%s\t%s\n' "$(printf '%s' "$d" | md5sum | cut -d' ' -f1)" "$f"
done | sort -u > "$findings.desc"
awk -F'\t' '{c[$1]++; f[$1]=f[$1] " " $2} END {for (k in c) if (c[k] > 1) print k}' "$findings.desc" |
  while read -r h; do
    awk -F'\t' -v h="$h" '$1 == h {print $2}' "$findings.desc" |
      sed 's/^/AUDIT: duplicate description (both fire on one request): /' >> "$findings"
  done
rm -f "$findings.desc"

# 3. manifest drift: README rows vs installed dirs, both directions.
if [ -f "$MANIFEST" ]; then
  comm -3 \
    <(grep -oE '^\| [^ |]+ ' "$MANIFEST" | tr -d '| ' | grep -vx 'Skill' | sort) \
    <(for d in "$SKILLS_DIR"/*/; do [ -f "$d/SKILL.md" ] && basename "$d"; done | sort) |
    sed 's/^[[:space:]]*/AUDIT: manifest drift (only on one side): /;s/\t/ /g' |
    grep -v 'AUDIT: manifest drift (only on one side): *$' >> "$findings"
else
  bad "no manifest at $MANIFEST"
fi

# 4. dangling host links: a host that scans only its own dir cannot resolve them.
for hd in "$HOME"/.pi/agent/skills "$HOME"/.claude/skills "$HOME"/.commandcode/skills \
          "$HOME"/.zcode/skills "$HOME"/.config/goose/skills "$HOME"/.hermes/skills \
          "$HOME"/.kiro/skills "$HOME"/.qoder/skills "$HOME"/.codebuddy/skills \
          "$HOME"/.rovodev/skills "$HOME"/.openhands/skills "$HOME"/.autohand/skills \
          "$HOME"/.minimax/skills; do
  [ -d "$hd" ] || continue
  find -L "$hd" -maxdepth 1 -type l 2>/dev/null | while read -r l; do
    echo "AUDIT: dangling link $l -> $(readlink "$l")" >> "$findings"
  done
done

# 5. provenance: a ledger row whose source vanished means upstream dropped or
#    renamed that skill while the installed copy keeps loading.
if [ -f "$LEDGER" ]; then
  while IFS=$'\t' read -r s from; do
    [ -n "$from" ] || continue
    [ -e "$from" ] || bad "stale skill '$s': upstream source is gone ($from)"
  done < "$LEDGER"
else
  bad "no provenance ledger at $LEDGER (skills cannot be traced to a source)"
fi

# 6. overlays: the sync recreates dead references on every run, so an overlay
#    script with no .overlay-applied marker in its skill dir means the installed
#    copy is still shipping whatever that overlay fixes. host/ scripts patch a
#    skill outside SKILLS_DIR, so they are checked against HOST_SKILLS_DIR.
for f in "$HOME"/dotfiles/skills-overlay/*.sh; do
  [ -f "$f" ] || continue
  s=$(basename "$f" .sh)
  [ -f "$SKILLS_DIR/$s/.overlay-applied" ] || bad "overlay not applied: $s"
done
for f in "$HOME"/dotfiles/skills-overlay/host/*.sh; do
  [ -f "$f" ] || continue
  s=$(basename "$f" .sh)
  [ -f "$HOST_SKILLS_DIR/$s/.overlay-applied" ] || bad "overlay not applied (host): $s"
done

# 7. dead relative links: a skill that points at a file the install does not
#    carry is unfollowable where it runs. External URLs are out of scope.
#    Allowlisted below are three links that sit inside documentation examples
#    (a rendered-output sample, a see-also template row, a ticket template), so
#    the target is a placeholder on purpose. Keep those names here if they move.
for f in "$SKILLS_DIR"/*/SKILL.md "$SKILLS_DIR"/*/README.md; do
  [ -f "$f" ] || continue
  d=$(dirname "$f")
  grep -oE '\]\([^)]+\)' "$f" 2>/dev/null | sed 's/^](//;s/)$//' |
    grep -vE '^(https?:|#|mailto:)' | while read -r l; do
      t=${l%%#*}
      [ -n "$t" ] || continue
      case "$f:$t" in
        */archify/SKILL.md:/abs/path/checkout-timing.html) continue ;;
        */rust-skills/README.md:other-rule.md) continue ;;
        */wayfinder/SKILL.md:link) continue ;;
      esac
      [ -e "$d/$t" ] || echo "AUDIT: dead relative link in $f -> $l" >> "$findings"
    done
done

sort -u "$findings"
count=$(wc -l < "$findings" | tr -d ' ')
echo "AUDIT-TOTAL: $count"
[ "$count" = 0 ]
