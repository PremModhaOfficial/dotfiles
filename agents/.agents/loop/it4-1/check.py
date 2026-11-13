#!/usr/bin/env python3
"""IT4-1 check: the clarify gate must not stall an unattended run, must re-score on
evidence, and the recorded IT4 prompts must each resolve to an action, not a stop.

Runs the three recorded prompts as text against the rule. No live agents, no network.
Exit 0 = the current wording passes and the old wording fails the same check.
"""
import sys
from pathlib import Path

HOME = Path.home()
SPEC = HOME / ".agents/references/memory-clarify.md"
SHARED = HOME / ".agents/AGENTS.md"
PI = HOME / ".pi/agent/AGENTS.md"
MACHINE = HOME / "AGENTS.md"
FLOW = HOME / ".agents/skills/flow/SKILL.md"

# Recorded IT4 runs: the prompt as typed, and the score the run actually assigned.
PROMPTS = [
    ("this thing is slow, fix it", 8),
    ("the deploy broke, find out why", 7),
    ("add a way to export the table", 6),
]

# Negative control: the wording in place during the IT4 runs.
OLD_SPEC = """\
## HARD RULE: clarify until ambiguity <= 3
- Score each prompt 0-10 before starting.
- Act at 3 or lower; if higher, do not start.
- Up to 4 questions that move the score, in one message, then re-score.
- Never fill a gap by quiet assumption.
- Told to start anyway: state the score and the reading you guessed, then go.

A wrong assumption costs a whole turn of work; one question costs one line.
"""

fails = []


def want(ok, label, detail=""):
    print(("PASS  " if ok else "FAIL  ") + label + (f"  [{detail}]" if detail and not ok else ""))
    if not ok:
        fails.append(label)


def block(text):
    """The clarify rule block of a rules file, or the whole file if it has no section."""
    for head in ("## HARD RULE: clarify", "## Before any work"):
        if head in text:
            start = text.index(head)
            rest = text[start + len(head):]
            nxt = rest.find("\n## ")
            return text[start:] if nxt < 0 else text[start:start + len(head) + nxt]
    return text


def unattended_branch(rule):
    """The unattended instructions: the spec section, or the sentence starting "Unattended ="."""
    out = []
    lines = rule.splitlines()
    for i, line in enumerate(lines):
        if line.startswith("## Unattended"):
            for nxt in lines[i + 1:]:
                if nxt.startswith("## "):
                    break
                out.append(nxt.strip())
        elif line.lstrip("- ").startswith("Unattended"):
            out.append(line.strip())
    return " ".join(x for x in out if x)


def rescore_clause(rule):
    out = []
    for seg in rule.replace("\n", " ").split("."):
        low = seg.lower()
        if "re-score" in low and any(w in low for w in ("evidence", "command", "read", "test")):
            out.append(seg.strip())
    return " ".join(out)


def decide(rule, attended, score):
    """What the rule says to do. Only the rule's own text may produce 'act' or 'ask'."""
    branch = unattended_branch(rule)
    if not attended and score > 3:
        if branch and any(w in branch.lower() for w in ("cheapest", "falsif", "continue")):
            return "act"
        if "do not start" in rule.lower() or "wait" in rule.lower():
            return "stop"
        return "stop"
    if attended and score > 3:
        return "ask" if "ask up to 4" in rule.lower() or "at most 4" in rule.lower() else "stop"
    return "act"


def unconditional_stop(rule):
    """Every 'do not start' must be scoped to an attended human, never global."""
    bad, head = [], ""
    for line in rule.splitlines():
        if line.startswith("## "):
            head = line
            continue
        low = line.lower()
        if "do not start" in low and not any(
            w in low or w in head.lower() for w in ("attended", "human", "person", "reply")
        ):
            bad.append(line.strip())
    return bad


def main():
    for p in (SPEC, SHARED, PI, MACHINE, FLOW):
        if not p.is_file():
            sys.exit(f"FAIL  missing {p}")
    spec = SPEC.read_text(encoding="utf-8")
    shared = block(SHARED.read_text(encoding="utf-8"))
    pi = block(PI.read_text(encoding="utf-8"))
    machine = MACHINE.read_text(encoding="utf-8")
    flow = FLOW.read_text(encoding="utf-8")
    live = spec + "\n" + shared

    # 1. The gate can tell whether a human can answer (IT4-1 requirement 1).
    low = spec.lower()
    for marker in ("another agent", "scheduled", "background", "task file", "launched with a task", "can reply"):
        want(marker in low, f"spec defines unattended checkably: {marker!r}")

    # 2. A non-stalling unattended branch (requirement 2).
    branch = unattended_branch(live)
    want(bool(branch), "spec+block carry an unattended branch", branch[:60])
    want("nobody can reply" in branch.lower() or "unattended" in branch.lower(), "branch is gated on no human")
    want(any(w in branch.lower() for w in ("cheapest", "falsif")), "branch takes a falsifying step")
    want("stall" in branch.lower(), "branch forbids stalling")
    want("report" in branch.lower(), "unanswered question becomes a report line")
    want(not unconditional_stop(live), "no unconditional 'do not start' left", "; ".join(unconditional_stop(live))[:80])

    # 3. Re-score on evidence, attended or not (requirement 3).
    rescore = rescore_clause(live)
    want(bool(rescore), "spec+block carry a re-score-on-evidence clause", rescore[:60])
    want("attended or not" in rescore.lower() or "regardless" in rescore.lower(), "re-score applies attended or not")

    # 4. The guarantee survives: the reading is stated and cheap to reverse.
    want("quiet assumption" in shared.lower(), "shared block keeps 'never fill a gap by quiet assumption'")
    want("reversible in one command" in low, "spec prefers a reading reversible in one command")

    # 5. The three recorded prompts, as text, must each end in an action under the
    #    unattended reading that matches how they were actually launched.
    for prompt, score in PROMPTS:
        got = decide(live, attended=False, score=score)
        want(score > 3, f"{prompt!r} is above the threshold as recorded", str(score))
        want(got == "act", f"{prompt!r} unattended -> act, not stop", got)

    # 6. Negative control: the wording that ran during IT4 fails the same checks.
    old_branch = unattended_branch(OLD_SPEC)
    want(not old_branch, "negative control: old wording has no unattended branch", old_branch[:60])
    want(not rescore_clause(OLD_SPEC), "negative control: old wording has no re-score-on-evidence clause")
    old_decisions = [decide(OLD_SPEC, attended=False, score=s) for _, s in PROMPTS]
    want(all(d == "stop" for d in old_decisions), "negative control: old wording stops on all three", str(old_decisions))

    # 7. Pointers say one thing: each names the spec, none restates a contradicting stop.
    for name, text in (("shared AGENTS.md", shared), ("pi fragment output", pi),
                       ("~/.agents/AGENTS.md", shared), ("/home/prm/AGENTS.md", machine),
                       ("flow/SKILL.md", flow)):
        want("memory-clarify.md" in text, f"{name} points at the spec")
        want(not unconditional_stop(text), f"{name} carries no unscoped stop")

    # 8. Size cap on the shared rules file.
    size = len(SHARED.read_bytes())
    want(size <= 4096, "shared AGENTS.md under 4096 bytes", str(size))

    print()
    if fails:
        print(f"FAIL: {len(fails)} check(s) failed")
        return 1
    print("OK: unattended branch, re-score clause, 3/3 prompts act, negative control fails")
    return 0


if __name__ == "__main__":
    sys.exit(main())
