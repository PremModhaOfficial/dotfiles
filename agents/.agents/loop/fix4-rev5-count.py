#!/usr/bin/env python3
"""FIX-4 rev5 obligation recount. One row per obligation, nothing summed in.

Method a stranger can rerun:
  1. A bullet is a line in ~/.agents/AGENTS.md, ~/.pi/agent/AGENTS.md or
     ~/.commandcode/AGENTS.md that starts with "- ".
  2. Every bullet is claimed by exactly one row below. The one exception is a pi
     bullet that is byte-identical to a shared bullet: that is the D12 authorised
     copy of a rule already counted, so it is claimed silently and never added.
  3. class=obligation  standing directive that constrains agent behaviour.
     class=definition  fixes a term or scale.
     class=syntax      a command form or invocation, no duty.
     class=index       one pointer line in the References section.
     class=descriptive recorded fact, recipe condition or implementation note.
  4. The published number is the count of class=obligation rows. No definition,
     syntax form, index line or descriptive note is ever added to it.
     That number is *classified*, not *proven*: the class is a hand-written label,
     so re-classing a row moves it with exit 0. What is enforced is coverage (every
     bullet claimed, every proof present). Honest range: 37-39, because N6, N7, C6
     and O2 are condition-shaped and could be read as descriptive.
  5. Assertions: every row's proof substring and every bullet is claimed; the
     shared file's content bullets partition into obligations + definitions.

Run: python3 ~/.agents/loop/fix4-rev5-count.py
Exit 1 on any unclaimed bullet or failed proof.
"""
import sys
from pathlib import Path

A = Path.home() / ".agents" / "AGENTS.md"
P = Path.home() / ".pi" / "agent" / "AGENTS.md"
C = Path.home() / ".commandcode" / "AGENTS.md"

# (id, class, file, proof substring) -- one row per bullet that carries a duty
ROWS = [
    # ~/.agents/AGENTS.md, content sections
    # rev7: the six ambiguity bullets are the always-loaded gate; the scale, the
    # refusal path and the retry detail live in references/memory-clarify.md only.
    ("C1", "obligation", A, "Score each prompt 0-10 before starting"),
    ("C2", "obligation", A, "Act at 3 or lower"),
    ("C3", "obligation", A, "Up to 4 questions that move the score"),
    ("C4", "obligation", A, "Announce the score and what you weigh"),
    ("C5", "obligation", A, "Questions must be about what alters the work"),
    ("C6", "obligation", A, "Never fill a gap by quiet assumption"),
    ("H1", "obligation", A, "Always prefer `~/.agents` over harness dirs"),
    ("H2", "obligation", A, "Harness files may only import, symlink or point"),
    ("H3", "obligation", A, "If a harness needs a fixed path"),
    ("D2", "definition", A, "Long means builds, tests, watchers"),
    ("N1", "obligation", A, "Never block a shell command"),
    ("N2", "obligation", A, "Never block on an agent"),
    ("N3", "obligation", A, "Do not wrap a wait call"),
    ("N4", "obligation", A, "Say one line about what is running"),
    ("N5", "obligation", A, "Peek at the job's log"),
    ("N6", "obligation", A, "One wait alone, or none"),
    ("N7", "obligation", A, "User waiting on one delegated result"),
    ("N8", "obligation", A, "Kill what you started before done"),
    ("L1", "obligation", A, "If `graft` exists, use it for local code"),
    ("L2", "obligation", A, "If `graft` exists: build once"),
    ("L3", "obligation", A, "Use deepwiki for dependencies"),
    ("L4", "obligation", A, "Open a file only when it is new"),
    ("S1", "obligation", A, "Synchronous work: the harness's own subagent tool"),
    ("S2", "obligation", A, "Detached work: the harness's detached spawn"),
    ("S3", "obligation", A, "Hand off on disk with absolute artifact paths"),
    ("S4", "obligation", A, "Never paste upstream content"),
    ("S5", "obligation", A, "Bound scope: labelled slices"),
    ("S6", "obligation", A, "Never re-run a failed task"),
    ("S7", "obligation", A, "Make every delegation send build/test output"),
    ("T1", "obligation", A, "Batch independent reads, greps and MCP lookups"),
    ("T2", "obligation", A, "Never print or return raw tool output"),
    ("W1", "obligation", A, "Read pages with `oc`"),
    ("W2", "obligation", A, "If built-in search or fetch is denied"),
    ("W3", "obligation", A, "Never retry a denied built-in call"),
    ("O1", "obligation", A, "Real repo work (bug, feature, PR)"),
    ("O2", "obligation", A, "Questions, research and chat do not need it"),
    ("Q1", "obligation", A, "Interactive agents only, never one-shot"),
    ("Q2", "obligation", A, "Every spawned agent's task text"),
    ("Q3", "obligation", A, "Check on it rather than assuming"),
    ("I1", "index", A, "Ambiguity cost — `~/.agents/references/memory-clarify.md`"),
    ("I1b", "index", A, "Full scale, refusal path and retry detail"),
    ("I2", "index", A, "Harness paths, pointer forms"),
    ("I3", "index", A, "Background, wait, kill"),
    ("I4", "index", A, "graft/deepwiki forms"),
    ("I5", "index", A, "Delegation hygiene"),
    ("I6", "index", A, "`oc` and donsetch forms"),
    ("I7", "index", A, "flow phases"),
    # ~/.pi/agent/AGENTS.md, local to pi (shared bullets are D12 copies)
    ("E1", "definition", P, "EGM skills are the `/skill:egm-*` commands"),
    ("E2", "obligation", P, "Resolve `agents/`, `resources/`"),
    ("F1", "syntax", P, "Launch interactive: `hc run --bg"),
    ("F2", "syntax", P, "One-shot is blocked here"),
    ("N1p", "copy", P, "Never block a shell command: start long work in the background"),
    ("N5p", "copy", P, "Peek with `bash`"),
    ("S1p", "copy", P, "pi has no in-process subagent tool"),
    ("S2p", "copy", P, "Detached work: `hc run --bg`"),
    ("W2p", "copy", P, "use a fallback MCP fetch server only when one is configured"),
    # rev7: pi's six ambiguity bullets are byte-identical to the shared gate and are
    # claimed silently; only the pi-only skip line needs a row. The scale and the
    # retry detail are not in pi at all -- they live in the reference.
    ("C7p", "copy", P, "If told to start anyway"),
    ("I6p", "index", P, "`oc` and web-fetch forms"),
    # ~/.commandcode/AGENTS.md, local to cmd: facts and recipe conditions
    ("K1", "syntax", C, "The blocking shell tool", False),
    ("K2", "descriptive", C, "Herdr agent-detection overrides"),
    ("K12", "descriptive", C, "`cmd.on('subagent_stop')` fires for detached runs"),
    ("K3", "descriptive", C, "Status reporting is driven by"),
    ("K4", "descriptive", C, "Debug with `herdr agent list`"),
    ("K5", "descriptive", C, "key background launches by toolCallId"),
    ("K6", "descriptive", C, "Wake with `cmd.sendUserMessage"),
    ("K7", "descriptive", C, "queues NEVER start a turn"),
    ("K8", "descriptive", C, "Mods cannot invoke `agent_output`"),
    ("K9", "descriptive", C, "Background manager is in-memory"),
    ("K10", "descriptive", C, "Empirical proof (pty-driven TUI"),
    ("K11", "syntax", C, "One-shot delegation here is `cmd -p`"),
]

# Bullets already folded into a survivor by this revision, kept as history only.
# They are not in ROWS, so they cannot be counted twice.
FOLDED = [
    ("rev4 C6", "C1", "the every-prompt scope clause moved into C1's bullet"),
    ("rev4 H2", "H1", "the canonical-files clause moved into H1's bullet"),
    ("rev4 N3", "N1", "the do-not-wait clause moved into N1's bullet"),
    ("rev4 L3 + L4", "L2", "the callers and tally clauses moved into L2's bullet"),
    ("rev4 R1-R8", "definition/syntax", "command forms, never duties; listed per reference file"),
    ("rev4 K1/K3/K5", "descriptive", "recorded facts, not standing rules"),
]


def bullets(path):
    return [l for l in path.read_text().splitlines() if l.startswith("- ")]


def main():
    texts = {f: bullets(f) for f in (A, P, C)}
    shared = set(texts[A])
    claimed = {f: set() for f in texts}
    bad = 0
    for row in ROWS:
        rid, cls, f, proof = row[:4]
        in_bullet = row[4] if len(row) > 4 else True
        ok = proof in f.read_text() and (not in_bullet or any(proof in b for b in texts[f]))
        bad += 0 if ok else 1
        for b in texts[f]:
            if proof in b:
                claimed[f].add(b)
        print(f"{rid:5} {cls:12} {str(f).replace(str(Path.home()) + '/', '~/'):28} {'OK' if ok else 'FAIL'}  {proof[:48]}")

    for b in texts[P]:
        if b in shared:
            claimed[P].add(b)

    print()
    for f, bs in texts.items():
        miss = [b for b in bs if b not in claimed[f]]
        label = str(f).replace(str(Path.home()) + "/", "~/")
        print(f"{label:28} bullets={len(bs):3} unclaimed={len(miss)}")
        for b in miss:
            print(f"    UNCLAIMED: {b[:110]}")
        bad += len(miss)

    counts = {}
    for row in ROWS:
        cls = row[1]
        counts[cls] = counts.get(cls, 0) + 1
    obligations = [r for r in ROWS if r[1] == "obligation"]
    shared_content = [b for b in texts[A] if "`~/.agents/references/" not in b]
    non_oblig_shared = counts.get("definition", 0) - 1  # E1 is pi-local
    assert len(shared_content) == len([r for r in ROWS if r[2] == A and r[1] != "index"]), \
        "shared content bullets are not 1:1 with rows"
    print(f"\nby class: {counts}")
    print(f"shared content bullets: {len(shared_content)} = "
          f"{len(shared_content) - non_oblig_shared} obligations + {non_oblig_shared} definitions")
    print(f"folded before counting (history only): {[d for d, _, _ in FOLDED]}")
    print(f"\nOBLIGATIONS: {len(obligations)}")
    print("CLASSIFIED, NOT PROVEN: hand-labelled class; coverage enforced, class not. "
          "Honest range 37-39 (N6, N7, C6, O2 are condition-shaped).")
    print(f"NOT COUNTED: definitions={counts.get('definition', 0)} "
          f"syntax={counts.get('syntax', 0)} index={counts.get('index', 0)} "
          f"descriptive={counts.get('descriptive', 0)} d12-copies={counts.get('copy', 0)}")
    print(f"failed proofs / unclaimed bullets: {bad}")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
