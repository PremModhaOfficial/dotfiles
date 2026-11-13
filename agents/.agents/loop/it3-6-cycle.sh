#!/usr/bin/env bash
# IT3-6 full cycle: snapshot -> wipe /skill: prefixes -> sync -> sync -> compare.
# The loadable tree is exactly the roots skill_slash.py globs; anything else is
# not loaded by pi, so it is not wiped.
set -u
RUN="$HOME/.agents/loop/it3-6-run"
mkdir -p "$RUN/tmp"
export TMPDIR="$RUN/tmp"
FILES="$RUN/files.txt"
python3 - "$FILES" <<'PY'
import importlib.util, os, sys
here = os.path.expanduser("~/dotfiles/jcode/skill_slash.py")
spec = importlib.util.spec_from_file_location("ss", here)
ss = importlib.util.module_from_spec(spec); spec.loader.exec_module(ss)
open(sys.argv[1], "w").write("\n".join(ss.skill_files()) + "\n")
PY

snapshot() { # snapshot OUT
  tr '\n' '\0' < "$FILES" | xargs -0 sha256sum | sort -k2 > "$1"
}

wipe() {
  python3 - "$FILES" <<'PY'
import re, sys
inv = re.compile(r"/skill:(?=[a-z])")
n_files = n_tok = 0
for path in open(sys.argv[1]).read().split():
    text = open(path, encoding="utf-8").read()
    hits = len(inv.findall(text))
    if not hits:
        continue
    n_files += 1; n_tok += hits
    open(path, "w", encoding="utf-8").write(inv.sub("/", text))
print("wipe: %d files, %d /skill: prefixes removed" % (n_files, n_tok))
PY
}

snapshot "$RUN/pre.sha"
echo "== live tree: $(wc -l < "$RUN/pre.sha") files"
echo "== dry-run ledger before any change"
python3 "$HOME/dotfiles/jcode/skills-activation.py" --dry-run > "$RUN/ledger0.txt" 2>&1
grep 'token ledger\|skills scanned' "$RUN/ledger0.txt"
echo
echo "== wipe"
wipe
echo "== transform on the wiped tree (no sync yet): what each token becomes"
python3 "$HOME/dotfiles/jcode/skills-activation.py" --dry-run > "$RUN/ledger-wiped.txt" 2>&1
grep 'token ledger\|skills scanned' "$RUN/ledger-wiped.txt"
echo
echo "== sync #1: update-all --skills-only"
bash "$HOME/dotfiles/jcode/update-all.sh" --skills-only > "$RUN/sync1.log" 2>&1
RC1=$?
echo "sync1 exit=$RC1"
tail -5 "$RUN/sync1.log"
snapshot "$RUN/post1.sha"
python3 "$HOME/dotfiles/jcode/skills-activation.py" --dry-run > "$RUN/ledger1.txt" 2>&1
grep 'token ledger\|skills scanned' "$RUN/ledger1.txt"
echo
echo "== sync #2: update-all --skills-only"
bash "$HOME/dotfiles/jcode/update-all.sh" --skills-only > "$RUN/sync2.log" 2>&1
RC2=$?
echo "sync2 exit=$RC2"
tail -5 "$RUN/sync2.log"
snapshot "$RUN/post2.sha"
python3 "$HOME/dotfiles/jcode/skills-activation.py" --dry-run > "$RUN/ledger2.txt" 2>&1
grep 'token ledger\|skills scanned' "$RUN/ledger2.txt"
echo
echo "== post1 vs post2 (stable across a second sync?)"
if diff "$RUN/post1.sha" "$RUN/post2.sha" > /dev/null; then
  echo "IDENTICAL: post1 == post2"
else
  echo "DIFFERING FILES: $(diff "$RUN/post1.sha" "$RUN/post2.sha" | grep -c '^[<>]')"
  diff "$RUN/post1.sha" "$RUN/post2.sha" | head -20
fi
echo
echo "== pre vs post1 (byte-identical to the pre-wipe live tree?)"
if diff "$RUN/pre.sha" "$RUN/post1.sha" > /dev/null; then
  echo "IDENTICAL: pre == post1"
else
  echo "DIFFERING FILES: $(diff "$RUN/pre.sha" "$RUN/post1.sha" | grep -c '^[<>]')"
  diff "$RUN/pre.sha" "$RUN/post1.sha" | grep '^[<>]' | awk '{print $1, $3}' | head -60
fi
echo "cycle done rc1=$RC1 rc2=$RC2"
