#!/usr/bin/env bash
# IT3-7 on the live tree: ledger before, sync #1, sync #2, whole-tree byte
# comparison (README.md included), and the git attribution of the difference.
set -u
RUN=/home/prm/.agents/loop/it3-7-run
SK=/home/prm/.agents/skills
export TMPDIR="$RUN/tmp"; mkdir -p "$TMPDIR"

snapshot() { ( cd "$SK" && find . -type f -print0 | sort -z | xargs -0 sha256sum ) > "$1"; echo "snapshot $1: $(wc -l < "$1") files"; }

echo "== backup of the pre-run tree"
tar czf "$RUN/pre-skills.tar.gz" -C "$SK" . && echo "backup $(du -h "$RUN/pre-skills.tar.gz" | cut -f1)"
echo "== ledger before (dry run)"
python3 /home/prm/dotfiles/jcode/skills-activation.py --dry-run > "$RUN/ledger0.txt" 2>&1
echo "exit=$?"; grep 'token ledger\|skills scanned' "$RUN/ledger0.txt"
snapshot "$RUN/pre.sha"
echo "== sync #1 (live, --skills-only)"
bash /home/prm/dotfiles/jcode/update-all.sh --skills-only > "$RUN/sync1.log" 2>&1
echo "sync1 exit=$?"
grep -E 'token ledger|skills scanned|AUDIT-TOTAL|REFUSED|ERROR' "$RUN/sync1.log" | tail -8
snapshot "$RUN/post1.sha"
echo "== sync #2 (live, --skills-only)"
bash /home/prm/dotfiles/jcode/update-all.sh --skills-only > "$RUN/sync2.log" 2>&1
echo "sync2 exit=$?"
grep -E 'token ledger|skills scanned|AUDIT-TOTAL|REFUSED|ERROR' "$RUN/sync2.log" | tail -8
snapshot "$RUN/post2.sha"
echo "== byte identity, whole skills tree, README.md included"
cmp -s "$RUN/post1.sha" "$RUN/post2.sha" && echo "IDENTICAL: $(wc -l < "$RUN/post1.sha") files" || { echo "DIFFERS"; diff "$RUN/post1.sha" "$RUN/post2.sha" | head -20; }
echo "== README line 3: $(sed -n 3p "$SK/README.md")"
echo "== which files differ pre -> post1"
python3 - "$RUN/pre.sha" "$RUN/post1.sha" <<'PY'
import sys
def load(p):
    out = {}
    for line in open(p):
        h, f = line.split(None, 1)
        out[f.strip()] = h
    return out
a, b = load(sys.argv[1]), load(sys.argv[2])
diff = sorted(f for f in set(a) | set(b) if a.get(f) != b.get(f))
print("%d files differ" % len(diff))
for f in diff[:15]: print("  ", f)
PY
echo "== git status of the skills tree"
git -C /home/prm/dotfiles status --porcelain agents/.agents/skills | wc -l
echo "== done"
