#!/usr/bin/env bash
# IT3-7 sandbox cycle: real update-all.sh --skills-only twice on a synthetic
# 180-card HOME (/tmp/it37/home), then byte-compare the whole skills tree,
# README.md included, plus a direct transform-twice check on a wiped tree.
set -u
RUN="$HOME_RUN"
SB=/tmp/it37
export HOME="$SB/home"
export PYTHONPATH=/home/prm/.local/lib/python3.14/site-packages
export TMPDIR="$SB/tmp"
mkdir -p "$TMPDIR" "$RUN"
FILES="$RUN/files.txt"

python3 - "$FILES" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("ss", "/tmp/it37/fake/jcode/skill_slash.py")
ss = importlib.util.module_from_spec(spec); spec.loader.exec_module(ss)
open(sys.argv[1], "w").write("\n".join(ss.skill_files()) + "\n")
PY

snapshot() { # snapshot OUT: every file the skills tree carries, README included
  ( cd "$SB/fake/agents/.agents/skills" && find . -type f -print0 \
      | sort -z | xargs -0 sha256sum ) > "$1"
  echo "snapshot $1: $(wc -l < "$1") files"
}

echo "== sandbox HOME=$HOME  cards=$(wc -l < "$FILES")"
echo "== transform dry-run on the pre-sync tree"
python3 /tmp/it37/fake/jcode/skills-activation.py --dry-run > "$RUN/ledger-pre.txt" 2>&1
grep 'token ledger' "$RUN/ledger-pre.txt"
echo "== transform writes the pre-sync tree (proves it, then the sync re-introduces)"
python3 /tmp/it37/fake/jcode/skills-activation.py > "$RUN/apply-pre.txt" 2>&1
echo "apply-pre exit=$?"; grep 'skills scanned' "$RUN/apply-pre.txt"

echo "== sync #1"
bash /tmp/it37/fake/jcode/update-all.sh --skills-only > "$RUN/sync1.log" 2>&1
RC1=$?
echo "sync1 exit=$RC1"; grep -E 'ledger|skills scanned|AUDIT-TOTAL|ERROR|REFUSED' "$RUN/sync1.log" | tail -6
snapshot "$RUN/post1.sha"

echo "== post-sync transform dry-run (must be a no-op)"
python3 /tmp/it37/fake/jcode/skills-activation.py --dry-run > "$RUN/ledger1.txt" 2>&1
grep 'token ledger\|skills scanned' "$RUN/ledger1.txt"

echo "== sync #2"
bash /tmp/it37/fake/jcode/update-all.sh --skills-only > "$RUN/sync2.log" 2>&1
RC2=$?
echo "sync2 exit=$RC2"; grep -E 'ledger|skills scanned|AUDIT-TOTAL|ERROR|REFUSED' "$RUN/sync2.log" | tail -6
snapshot "$RUN/post2.sha"

echo "== byte identity of the whole skills tree, README.md included"
if cmp -s "$RUN/post1.sha" "$RUN/post2.sha"; then
  echo "IDENTICAL: $(wc -l < "$RUN/post1.sha") files, README.md included"
else
  echo "DIFFER:"; diff "$RUN/post1.sha" "$RUN/post2.sha" | head -10
fi
echo "== README.md line 3:"; sed -n 3p "$SB/fake/agents/.agents/skills/README.md"
echo "== README regenerated twice outside the sync, compared"
cp "$SB/fake/agents/.agents/skills/README.md" "$RUN/readme1.md"
bash /tmp/it37/fake/jcode/update-all.sh --manifest-only > "$RUN/manifest2.log" 2>&1
cmp -s "$RUN/readme1.md" "$SB/fake/agents/.agents/skills/README.md" && echo "README IDENTICAL across two manifest builds" || echo "README DIFFERS"

echo "== transform twice on a wiped tree (the transform-owned files)"
WIPE="$SB/home2"
rm -rf "$WIPE"; mkdir -p "$WIPE/.jcode/bin"
cp -a "$SB/fake/agents/.agents" "$WIPE/.agents"
ln -s "$SB/fake/jcode/update-all.sh" "$WIPE/.jcode/bin/update-all.sh"
python3 - "$WIPE/.agents/skills" <<'PY'
import re, sys, glob, os
inv = re.compile(r"/skill:(?=[a-z])")
n_files = n_tok = 0
for path in glob.glob(os.path.join(sys.argv[1], "*", "SKILL.md")):
    text = open(path, encoding="utf-8").read()
    hits = len(inv.findall(text))
    if hits:
        n_files += 1; n_tok += hits
        open(path, "w", encoding="utf-8").write(inv.sub("/", text))
print("wipe: %d files, %d prefixes removed" % (n_files, n_tok))
PY
HOME="$WIPE" python3 /tmp/it37/fake/jcode/skills-activation.py > "$RUN/wipe1.log" 2>&1
echo "wipe-transform1 exit=$?"; grep 'token ledger\|skills scanned' "$RUN/wipe1.log"
( cd "$WIPE/.agents/skills" && find . -type f -print0 | sort -z | xargs -0 sha256sum ) > "$RUN/wipe1.sha"
HOME="$WIPE" python3 /tmp/it37/fake/jcode/skills-activation.py > "$RUN/wipe2.log" 2>&1
echo "wipe-transform2 exit=$?"; grep 'token ledger\|skills scanned' "$RUN/wipe2.log"
( cd "$WIPE/.agents/skills" && find . -type f -print0 | sort -z | xargs -0 sha256sum ) > "$RUN/wipe2.sha"
cmp -s "$RUN/wipe1.sha" "$RUN/wipe2.sha" && echo "wipe: transform output byte-identical across two runs" || { echo "wipe: DIFFERS"; diff "$RUN/wipe1.sha" "$RUN/wipe2.sha" | head; }
echo "== done"
