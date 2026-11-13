#!/usr/bin/env python3
"""IT4-3 acceptance: is the `Reading: X, because Y` line in a worker's VISIBLE output
(assistant text, not thinking) before its first write or world-changing command?

Usage: accept.py <repo-dir>...   e.g. accept.py /tmp/r5/ryoku-arch /tmp/r5/aur-prefetch
Exit 0 = every repo passed.
"""
import json
import re
import sys
from pathlib import Path

MUT_TOOLS = {"edit", "write"}
SKIP_WORDS = {"cd", "sudo", "env", "time", "timeout", "echo", "set", "export", "if", "then",
              "fi", "else", "for", "do", "done", "xargs", "nohup"}
MUT_WORDS = {"rm", "mv", "cp", "mkdir", "touch", "tee", "dd", "mktemp", "chmod", "chown",
             "ln", "rmdir", "truncate", "install", "patch"}
BUILD_WORDS = {"make", "cargo", "go", "npm", "pnpm", "yarn", "pip", "bash", "sh", "zsh"}
GIT_MUT = {"commit", "checkout", "reset", "apply", "clean", "add", "push", "stash", "merge",
           "rebase", "worktree", "restore", "switch", "rm"}


def mutating(cmd):
    """True if the command text plausibly writes or changes something (conservative)."""
    for seg in re.split(r"&&|\|\||[;\n|]", re.sub(r"\d?>\s*/dev/null|2>&1", "", cmd)):
        words = seg.split()
        while words and (words[0] in SKIP_WORDS
                         or re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*=.*", words[0])
                         or words[0].startswith("-")):
            words.pop(0)
        if not words:
            continue
        w = words[0].strip("'\"()")
        if w in MUT_WORDS or w.startswith("./") or w.endswith(".sh"):
            return True
        if w == "git" and len(words) > 1 and words[1] in GIT_MUT:
            return True
        if w == "sed" and any(x.startswith("-i") for x in words):
            return True
        if w in BUILD_WORDS and (w not in {"bash", "sh", "zsh"} or len(words) > 1):
            return True
        if w in {"cat", "echo", "printf", "python", "python3", "node"} and ">" in seg:
            return True
        if w in {"curl", "wget"} and any(x.startswith(("-o", "-O")) or ">" in seg for x in words):
            return True
    return False


READING = re.compile(r"^reading:\s*\S", re.I)


def session_file(repo):
    d = Path.home() / ".pi/agent/sessions" / ("--" + str(repo).strip("/").replace("/", "-") + "--")
    hits = sorted(d.glob("*.jsonl"), key=lambda p: p.stat().st_mtime)
    return hits[-1] if hits else None


def reading_line(text):
    for raw in text.splitlines():
        s = raw.strip().lstrip("*_>-# `").strip()
        if READING.match(s):
            return raw.strip()
    return None


def scan(repo):
    f = session_file(repo)
    if not f:
        return {"repo": repo, "error": "no session"}
    first_mut, reading, first_tool, cmds, texts = None, None, None, [], 0
    for line in f.read_text(errors="replace").splitlines():
        try:
            o = json.loads(line)
        except Exception:
            continue
        if o.get("type") != "message":
            continue
        m = o.get("message", {})
        if m.get("role") != "assistant":
            continue
        ts = o.get("timestamp")
        for p in m.get("content", []) if isinstance(m.get("content"), list) else []:
            if p.get("type") == "text":
                texts += 1
                if reading is None:
                    hit = reading_line(p.get("text", ""))
                    if hit:
                        reading = (ts, hit)
            if p.get("type") == "toolCall":
                name, args = p.get("name"), p.get("arguments", {}) or {}
                first_tool = first_tool or (ts, name)
                if name in MUT_TOOLS:
                    first_mut = first_mut or (ts, name, str(args)[:100])
                elif name == "codemode":
                    cmd = str(args.get("code", ""))
                    cmds.append((ts, cmd[:200]))
                    if not first_mut and mutating(cmd):
                        first_mut = (ts, "codemode", cmd[:140])
                elif name == "bash":
                    cmd = str(args.get("command", ""))
                    cmds.append((ts, cmd))
                    if not first_mut and mutating(cmd):
                        first_mut = (ts, "bash", cmd[:140])
    return {"repo": repo, "first_mut": first_mut, "reading": reading,
            "first_tool": first_tool, "texts": texts, "cmds": cmds, "error": None}


def main():
    repos = sys.argv[1:] or ["/tmp/r5/ryoku-arch", "/tmp/r5/aur-prefetch"]
    bad = 0
    for repo in repos:
        r = scan(repo)
        print(f"== {repo}")
        if r["error"]:
            print(f"   FAIL {r['error']}")
            bad += 1
            continue
        print(f"   first tool: {r['first_tool']}")
        print(f"   visible text parts: {r.get('texts')}")
        print(f"   first mutating: {r['first_mut']}")
        print(f"   reading line: {r['reading']}")
        ok = bool(r["reading"]) and (r["first_mut"] is None or r["reading"][0] <= r["first_mut"][0])
        print(f"   {'PASS' if ok else 'FAIL'}: visible Reading line before first write/change")
        bad += not ok
    print(f"\n{len(repos) - bad}/{len(repos)} passed")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
