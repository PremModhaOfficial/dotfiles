#!/usr/bin/env bash
# Probe the dispatch state: worktrees, open PRs, and pairwise merge conflicts.
#
# Exists because "remember to check status before reporting" is a memory rule and
# memory rules fail silently. This prints the facts instead, so a stale ledger is
# visible in the output rather than trusted from a thread's own message.
#
#   flow-state.sh            all three sections
#   flow-state.sh worktrees  branch, dirty count, head sha per worktree
#   flow-state.sh prs        open PRs: number, head branch, checks, mergeable
#   flow-state.sh conflicts  pairwise merge conflicts among open PR heads
#   flow-state.sh --selftest assert the conflict probe on a scratch repo
#   flow-state.sh --help
#
# Read-only: no fetch, no commit, no PR writes. Missing origin refs are reported,
# never fetched, so a probe cannot move a branch under a running agent.

set -uo pipefail

git_() { command git "$@"; }

section_worktrees() {
  git_ worktree list --porcelain | awk '
    /^worktree /  { path = substr($0, 10) }
    /^HEAD /      { sha = substr($0, 6, 8) }
    /^branch /    { ref = substr($0, 8); sub(/^refs\/heads\//, "", ref); n++; printf "%-10s %-45s %s\n", sha, ref, path }
    /^detached/   { n++; printf "%-10s %-45s %s\n", sha, "(detached)", path }
  '
  local dirty=0
  for p in $(git_ worktree list --porcelain | awk '/^worktree /{print substr($0,10)}'); do
    [ -d "$p" ] || continue
    c=$(git_ -C "$p" status --porcelain 2>/dev/null | wc -l)
    [ "$c" -gt 0 ] && { printf 'dirty %-4s %s\n' "$c" "$p"; dirty=$((dirty + 1)); }
  done
  [ "$dirty" -eq 0 ] && echo "no dirty worktrees"
}

section_prs() {
  if ! command -v gh >/dev/null || ! gh repo view --json name >/dev/null 2>&1; then
    echo "no GitHub repo here; skipped"
    return 0
  fi
  gh pr list --state open --limit 100 --json number,headRefName,mergeable,statusCheckRollup,title \
    --jq '.[] | "\(.number)\t\(.mergeable)\tchecks=\([.statusCheckRollup[]? | .conclusion // .state] | group_by(.) | map("\(.[0])×\(length)") | join(","))\t\(.headRefName)\t\(.title)"' \
    | sort -n | awk -F'\t' '{ printf "%-4s %-12s %-40s %-32s %s\n", $1, $2, $3, $4, $5 }'
  gh pr list --state open --limit 100 --json number --jq '"open PRs: \(length)"'
}

section_conflicts() {
  local refs=() n
  while IFS= read -r n; do
    if git_ rev-parse --verify --quiet "origin/$n" >/dev/null; then refs+=("origin/$n"); else echo "missing ref origin/$n (not fetched)"; fi
  done < <(gh pr list --state open --limit 100 --json headRefName --jq '.[].headRefName' 2>/dev/null)

  [ "${#refs[@]}" -lt 2 ] && { echo "fewer than 2 open PR heads; nothing to compare"; return 0; }
  local i j found=0
  for ((i = 0; i < ${#refs[@]}; i++)); do
    for ((j = i + 1; j < ${#refs[@]}; j++)); do
      # --name-only prints the tree oid, then one path per conflicted file.
      if ! out=$(git_ merge-tree --write-tree --no-messages --name-only "${refs[$i]}" "${refs[$j]}" 2>&1); then
        found=$((found + 1))
        printf 'CONFLICT %s + %s\n' "${refs[$i]}" "${refs[$j]}"
        printf '%s\n' "$out" | tail -n +2 | grep -v '^$' | sed 's/^/    /'
      fi
    done
  done
  [ "$found" -eq 0 ] && echo "no conflicts among ${#refs[@]} open PR heads"
}

selftest() {
  local tmp rc=0
  tmp=$(mktemp -d) || return 1
  trap 'rm -rf "$tmp"' RETURN
  git_ -C "$tmp" init -q -b main
  git_ -C "$tmp" config user.email t@t; git_ -C "$tmp" config user.name t
  git_ -C "$tmp" config commit.gpgsign false; git_ -C "$tmp" config tag.gpgsign false
  printf 'a\n' > "$tmp/f"
  git_ -C "$tmp" add f; git_ -C "$tmp" commit -qm base
  git_ -C "$tmp" checkout -qb one; printf 'one\n' > "$tmp/f"; git_ -C "$tmp" commit -qam one
  git_ -C "$tmp" checkout -q main; git_ -C "$tmp" checkout -qb two
  printf 'two\n' > "$tmp/f"; git_ -C "$tmp" commit -qam two
  local mt
  mt=$(cd "$tmp" && git_ merge-tree --write-tree one two 2>&1)
  if grep -q '^CONFLICT' <<<"$mt"; then
    echo "ok conflict probe flags a real conflict"
  else
    echo "FAIL conflict probe missed a conflict"; rc=1
  fi
  git_ -C "$tmp" checkout -q main
  mt=$(cd "$tmp" && git_ merge-tree --write-tree main main 2>&1)
  if grep -q '^CONFLICT' <<<"$mt"; then
    echo "FAIL conflict probe invents a conflict"; rc=1
  else
    echo "ok conflict probe passes identical refs"
  fi
  return $rc
}

case "${1:-all}" in
  --selftest) selftest ;;
  --help | -h) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//' ;;
  worktrees) section_worktrees ;;
  prs) section_prs ;;
  conflicts) section_conflicts ;;
  all)
    echo "== worktrees"; section_worktrees
    echo "== pull requests"; section_prs
    echo "== conflicts"; section_conflicts
    ;;
  *) echo "unknown command: $1 (try --help)" >&2; exit 2 ;;
esac
