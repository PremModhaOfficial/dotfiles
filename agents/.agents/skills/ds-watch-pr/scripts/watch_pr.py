#!/usr/bin/env python3
"""Watch one GitHub PR and print one line per new event. Needs the gh CLI.

usage: watch_pr.py <pr> [--repo owner/name] [--until green|ready|any] [--interval 30] [--max-minutes 60]

Exit codes:
  0  --until condition met, or the PR merged
  1  needs action: a check failed, conflicts, changes requested, PR closed,
     gh kept failing, or the time limit ran out
  2  bad arguments or unknown PR
"""
import argparse
import json
import subprocess
import sys
import time

FIELDS = "state,mergeable,mergeStateStatus,reviewDecision,headRefOid,statusCheckRollup,comments,reviews,url"
FAILED = {"FAILURE", "ERROR", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED", "STARTUP_FAILURE"}
PASSED = {"SUCCESS", "NEUTRAL", "SKIPPED"}
MAX_GH_ERRORS = 5


def fetch(pr, repo):
    cmd = ["gh", "pr", "view", pr, "--json", FIELDS] + (["--repo", repo] if repo else [])
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or "gh failed")
    return json.loads(out.stdout)


def check_result(c):
    # CheckRun has status/conclusion; StatusContext has state.
    if c.get("__typename") == "StatusContext":
        state = c.get("state", "")
        return "PENDING" if state in ("PENDING", "EXPECTED") else state
    if c.get("status") != "COMPLETED":
        return "PENDING"
    return c.get("conclusion") or "PENDING"


def summarize(pr):
    checks = {(c.get("name") or c.get("context") or "?"): check_result(c) for c in pr.get("statusCheckRollup") or []}
    failed = sorted(n for n, r in checks.items() if r in FAILED)
    pending = sorted(n for n, r in checks.items() if r not in FAILED | PASSED)
    notes = {("comment", c.get("id") or c.get("url")): c for c in pr.get("comments") or []}
    notes.update({("review", r.get("id")): r for r in pr.get("reviews") or []})
    return {"checks": checks, "failed": failed, "pending": pending, "notes": notes}


def events(prev, cur):
    if prev is None:
        return []
    out = []
    for name in cur["failed"]:
        if name not in prev["failed"]:
            out.append(f"check failed: {name}")
    if cur["checks"] and not cur["pending"] and prev["pending"]:
        out.append(f"checks finished: {len(cur['failed'])} failed of {len(cur['checks'])}")
    for key, note in cur["notes"].items():
        if key not in prev["notes"]:
            who = (note.get("author") or {}).get("login", "?")
            body = " ".join((note.get("body") or "").split())[:120]
            out.append(f"new {key[0]} by {who}: {body}")
    return out


def outcome(pr, cur, until):
    """Return (exit_code, reason) when the watch should end, else None."""
    if pr["state"] == "MERGED":
        return 0, "merged"
    if pr["state"] == "CLOSED":
        return 1, "closed"
    if cur["failed"]:
        return 1, "failed checks: " + ", ".join(cur["failed"])
    if pr.get("mergeable") == "CONFLICTING" or pr.get("mergeStateStatus") == "DIRTY":
        return 1, "conflicts with base"
    if pr.get("reviewDecision") == "CHANGES_REQUESTED":
        return 1, "changes requested"
    green = not cur["pending"]
    if until == "green" and green:
        return 0, "checks green"
    if until == "ready" and green:
        if pr.get("mergeStateStatus") == "BEHIND":
            return 1, "branch is behind base"
        if pr.get("mergeStateStatus") in ("CLEAN", "HAS_HOOKS", "UNSTABLE"):
            return 0, "ready: checks green, mergeable"
    return None


def main(argv=None):
    ap = argparse.ArgumentParser(description="Watch a GitHub PR until a condition is met.")
    ap.add_argument("pr")
    ap.add_argument("--repo")
    ap.add_argument("--until", choices=["green", "ready", "any"], default="ready")
    ap.add_argument("--interval", type=int, default=30)
    ap.add_argument("--max-minutes", type=int, default=60)
    a = ap.parse_args(argv)
    if a.interval < 5 or a.max_minutes < 1:
        ap.error("--interval must be >= 5 and --max-minutes >= 1")

    deadline = time.time() + a.max_minutes * 60
    prev, errors = None, 0
    while time.time() < deadline:
        try:
            pr = fetch(a.pr, a.repo)
            errors = 0
        except (RuntimeError, subprocess.TimeoutExpired, json.JSONDecodeError) as e:
            errors += 1
            print(f"gh error ({errors}/{MAX_GH_ERRORS}): {e}", file=sys.stderr)
            if prev is None and "Could not resolve" in str(e):
                return 2
            if errors >= MAX_GH_ERRORS:
                print("stop: gh unreachable")
                return 1
            time.sleep(a.interval)
            continue
        cur = summarize(pr)
        new = events(prev, cur)
        for line in new:
            print(line, flush=True)
        if prev is None:
            print(f"watching {pr['url']} head {pr['headRefOid'][:8]}", file=sys.stderr)
        if a.until == "any" and new:
            return 0
        done = outcome(pr, cur, a.until)
        if done:
            print(f"stop: {done[1]}", flush=True)
            return done[0]
        prev = cur
        time.sleep(a.interval)
    print("stop: time limit reached")
    return 1


if __name__ == "__main__":
    sys.exit(main())
