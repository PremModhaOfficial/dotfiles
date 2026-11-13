#!/usr/bin/env python3
"""FIX-1 rev2: undo rev1's hiding, revert rewrites that a sync would overwrite.

1. drop every `disable-model-invocation` line rev1 added (pre-ticket = fix1-backup-skills.tar.gz)
2. restore the upstream description for skills whose SKILL.md is re-synced by
   update-all.sh:316 (cp -R) or is a symlink into an app-managed directory
3. keep the remaining rewrites and the deletion of event-loop-orchestration

Idempotent: a second run prints `updated: <none>`.
"""
import os
import re

ROOT = os.path.expanduser("~/.agents/skills")
BEFORE = "/tmp/fix1-before"            # tar xzf ~/.agents/loop/fix1-backup-skills.tar.gz -C /tmp/fix1-before
ORIGINALS = os.path.expanduser("~/.agents/loop/fix1-symlink-originals")

# re-synced with `cp -R` by update-all.sh, or a symlink into an app bundle:
# the source owns the file, so an edit here is silently undone by the next update.
REVERT = {
    "tiger-style": f"{BEFORE}/tiger-style/SKILL.md",
    "tiger-style-audit": f"{BEFORE}/tiger-style-audit/SKILL.md",
    "tiger-style-review": f"{BEFORE}/tiger-style-review/SKILL.md",
    "ponytail-review": f"{BEFORE}/ponytail-review/SKILL.md",
    "cua-driver": f"{ORIGINALS}/cua-driver.SKILL.md",
    "superwhisper": f"{ORIGINALS}/superwhisper.SKILL.md",
}


def split(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        raise SystemExit("no frontmatter in " + text[:20])
    return m.group(1), text[m.end():]


def desc_block(fm):
    """The description line plus any block-scalar continuation, as one string."""
    lines = fm.split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("description:"))
    end = start + 1
    if lines[start].split(":", 1)[1].strip() in ("|", ">", "|-", ">-", "|+", ">+"):
        while end < len(lines) and (lines[end].startswith((" ", "\t")) or not lines[end].strip()):
            end += 1
    return "\n".join(lines[start:end])


def with_description(fm, block):
    lines = fm.split("\n")
    old = desc_block(fm).split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("description:"))
    return "\n".join(lines[:start] + block.split("\n") + lines[start + len(old):])


def main():
    changed = 0
    for name in sorted(os.listdir(ROOT)):
        path = os.path.join(ROOT, name, "SKILL.md")
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as f:
            text = f.read()
        fm, body = split(text)

        if name in REVERT:
            with open(REVERT[name], encoding="utf-8") as f:
                src = split(f.read())[0]
            fm = with_description(fm, desc_block(src))

        before = f"{BEFORE}/{name}/SKILL.md"
        has_flag = re.search(r"^disable-model-invocation:", fm, re.M) is not None
        if has_flag and os.path.isfile(before):
            pre = split(open(before, encoding="utf-8").read())[0]
            if not re.search(r"^disable-model-invocation:", pre, re.M):
                fm = re.sub(r"\n?^disable-model-invocation:.*$", "", fm, count=1, flags=re.M)

        out = "---\n%s\n---\n%s" % (fm, body)
        if out != text:
            with open(path, "w", encoding="utf-8") as f:
                f.write(out)
            changed += 1
    print("updated:", changed)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
