#!/usr/bin/env python3
"""FIX-1 apply: rewrite >60-word descriptions to <=40 words and mark
rare/side-effecting skills manual-only. Run once, idempotent.

Evidence and rationale: ~/.agents/loop/fix1-report.md
"""
import os
import re
import shutil
import sys

ROOT = os.path.expanduser("~/.agents/skills")

# --- 1. rewrites: every description over 60 words -> <=40, triggers kept ----
REWRITE = {
    "ghostex-agents": "Launch, message, wait on and close Claude, Codex or other agents in Ghostex sessions, and read or search another session's thread. Use when other agents do part of the work or need to coordinate.",
    "archify": "Create validated architecture, workflow, sequence, data-flow, ERD, class, tree and timeline diagrams as standalone HTML, or a one-page explainer (做成一页). Use when visualizing systems, schemas, pipelines, API calls or states.",
    "ai-image-generation": "Generate AI images with GPT-Image-2, FLUX, Gemini, Grok, Seedream and 50+ models via inference.sh: text-to-image, image-to-image, inpainting, LoRA, upscaling. Use for AI art, mockups, concept art, illustrations, product shots.",
    "decision-ledger": "Records what a setup, install, config, integration, migration or deploy task did, what it skipped, and what stays unverified. Use on such a task, even when the user never asks, and when they report something missed.",
    "ghostex-help": "Answer how Ghostex works: what a feature, view, button or setting does, how to do something in it, or change the app for them. Reads `ghostex guide`, changes settings through `ghostex settings`.",
    "tiger-style": "Safety-first coding mode from TigerBeetle's Tiger Style: assertions, explicit limits, static resources, no technical debt. Levels lite, full, strict. Use when the user says \"tiger style\", \"assert everything\", \"safety first\", \"bound everything\", \"NASA rules\", or wants defensive code.",
    "feature-compare": "Build a feature-parity table across two or more products of any kind, from DeepWiki for open-source repos and official docs otherwise. Use when asked to compare, diff or benchmark feature sets, or \"who supports what\".",
    "ghostex-cli": "Use for anything involving Ghostex or the `ghostex`/`gx` CLI: projects, workspaces, panes, sessions, agent orchestration, automations, the Beads board, prompt history, server management, logs, screenshots, diagnostics.",
    "superwhisper": "Configure and troubleshoot Superwhisper dictation on Linux through its CLI: processing mode, language, microphone, keyboard shortcuts, sound, auto-paste, history, vocabulary, models, why dictation is not working. Triggers: superwhisper, dictation, speech to text, voice typing.",
    "ghostex-manage-beads": "Work a Ghostex project board bead or card by id through the `bd` CLI: create, update, comment, review, close, link the session to a card, and make review beads safely.",
    "cua-driver": "Drive a native GUI app on macOS, Windows or Linux through the cua-driver CLI or MCP server: snapshot its accessibility tree, act on element tokens, menu paths, window geometry or pixels, and verify. Use for GUI automation on the host.",
    "ghostex-visuals": "Show charts, stat tiles, tables and text layouts inline in the Ghostex chat, ask questions as a form, and publish self-contained HTML pages with `ghostex show`. Use only when the user asks for $ghostex-visuals.",
    "code-review": "Review changes since a commit, branch, tag or merge-base on two axes: Standards (does the code follow this repo's documented standards?) and Spec (does it match the originating issue or spec?). Use to review a branch, PR or WIP change.",
    "tiger-style-review": "Code review for Tiger Style violations only: missing assertions, unbounded loops and queues, unhandled errors, hidden control flow, unchecked invariants, unsafe memory, broken explicit limits. One line per finding: location, violation, fix. Use on \"review for safety\", \"check my invariants\".",
    "ponytail-review": "Quality review of a change: is the logic right, is it safe, does it hold under load, is risky code tested, is it fast, is every line needed. Use for \"review this\", \"review my PR\", \"is this over-engineered\".",
    "ds-context-reset": "Keep a PROGRESS.md for long tasks and move to a fresh session or subagent that reads only it when context gets long or stale. Use when a task spans many steps or sessions, or the model repeats itself. /ds-context-reset.",
    "tiger-style-audit": "Whole-repo audit for Tiger Style safety, not a diff: a ranked report of every missing assertion, unbounded loop, unhandled error, unsafe allocation and deferred debt. Use on \"audit this codebase\", \"find the unguarded paths\", \"harden this repo\". Reports only.",
}

# --- 2. skills that stay in the catalog (auto-invocable) -------------------
KEEP = """
flow ds-help ds-plan-loop ds-blueprint diagnosing-bugs surgical-patch lean-build
ds-tdd migration safe-refactor prototype ds-verify-loop ds-review-loop ds-ready
ds-ship ds-jury code-review ponytail-review tiger-style-review ds-blast-radius
ds-adopt ds-revive ds-unstick ds-pr-comments cavecrew ds-lessons caveman-explore
herdr t3-code making-skills writing-for-agents research
web-browsing-cli superwhisper cua-driver archify ponytail
caveman decision-ledger pr rex
""".split()

# --- 3. deleted duplicates: name -> (survivor, evidence) --------------------
DELETE = {"event-loop-orchestration": "v2-event-loop-orchestration"}

# --- 4. why each remaining skill goes manual-only --------------------------
SIDE = "side effect: writes, commits, deploys or spawns outside the chat turn"
RARE = "rare task the user names"
SELF = "description already says invoke as /name, so the catalog entry adds nothing"
HELP = "one-shot help or stats card, typed by name"
FAM = "family variant loaded by its named entry point"
REF = "reference material read on demand, not a routing target"
DUP = "overlaps a flow-routed skill that stays in the catalog"

REASON = {
    "ask-matt": SELF, "chief-of-staff": SELF, "claude-handoff": SIDE,
    "axi": RARE, "babysit": SELF, "brag": SELF, "ai-image-generation": RARE,
    "caveman-commit": FAM, "caveman-compress": SELF, "caveman-discover": RARE,
    "caveman-evidence-review": RARE, "caveman-help": HELP, "caveman-learn": RARE,
    "caveman-manage": SIDE, "caveman-optimize": SIDE, "caveman-review": FAM,
    "caveman-setup": SIDE, "caveman-stats": HELP,
    "codebase-design": REF, "domain-modeling": REF,
    "coordinator": SIDE, "docker-agent-command-code": REF,
    "driving-t3-previews": RARE, "ds-best-of-n": SELF, "ds-catchup": SELF,
    "ds-context-reset": SELF, "ds-design": RARE, "ds-design-audit": RARE,
    "ds-explain": SELF, "ds-ledger": RARE, "ds-mode": SELF, "ds-pr": SIDE,
    "ds-principles": REF, "ds-sharpen": SELF, "ds-swarm": RARE, "ds-unslop": RARE,
    "ds-watch-pr": SIDE, "feature-compare": RARE,
    "grill-me": FAM, "grill-with-docs": FAM, "grilling": FAM,
    "handoff": SELF, "i-have-adhd": SELF,
    "implement": SELF, "implement-spec": SELF, "improve-codebase-architecture": RARE,
    "intent-interview": RARE, "investigate-first": DUP,
    "learned": RARE, "linking-t3-prs": RARE, "loop-me": SELF, "find-skills": RARE,
    "megacave": SELF, "merge": SIDE,
    "openhilclimb": RARE,
    "ponytail-audit": RARE, "ponytail-debt": HELP, "ponytail-gain": HELP,
    "ponytail-help": HELP, "poster-design-generation": RARE, "prem-search": DUP,
    "rebase": SIDE, "retro": RARE, "rust-skills": REF,
    "setup-matt-pocock-skills": SIDE, "tdd": DUP, "teach": RARE,
    "tiger-style": SELF, "tiger-style-audit": RARE, "tiger-style-commit": SIDE,
    "tiger-style-help": HELP, "to-questionnaire": SELF, "to-spec": SELF,
    "to-tickets": SELF, "triage": SIDE, "ultracave": SELF,
    "v2-event-loop-orchestration": RARE, "verify-and-stop": RARE,
    "wait-what": SELF, "wayfinder": RARE, "wizard": SIDE,
    "workmux": REF, "worktree": SIDE, "open-pr": SIDE,
}


def split_fm(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        raise SystemExit("no frontmatter")
    return m.group(1), text[m.end():]


def set_description(fm, value):
    lines = fm.split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("description:"))
    end = start + 1
    first = lines[start].split(":", 1)[1].strip()
    if first in ("|", ">", "|-", ">-", "|+", ">+"):
        while end < len(lines) and (lines[end].startswith((" ", "\t")) or not lines[end].strip()):
            end += 1
    escaped = value.replace('"', '\\"')
    return "\n".join(lines[:start] + ['description: "%s"' % escaped] + lines[end:])


def add_disable(fm):
    if re.search(r"^disable-model-invocation:", fm, re.M):
        return fm
    return fm + "\ndisable-model-invocation: true"


def main():
    names = sorted(d for d in os.listdir(ROOT) if os.path.isfile(os.path.join(ROOT, d, "SKILL.md")))
    for gone in DELETE:
        if gone not in names:
            print("already deleted:", gone)
            continue
        if os.path.exists(os.path.join(ROOT, DELETE[gone])):
            shutil.rmtree(os.path.join(ROOT, gone))
            print("deleted:", gone)
        else:
            raise SystemExit("survivor missing for %s" % gone)

    for name in names:
        if name in DELETE:
            continue
        path = os.path.join(ROOT, name, "SKILL.md")
        with open(path, encoding="utf-8") as f:
            text = f.read()
        fm, body = split_fm(text)
        if name in REWRITE:
            new = REWRITE[name]
            w = len(new.split())
            if w > 40:
                raise SystemExit("%s rewrite is %d words" % (name, w))
            fm = set_description(fm, new)
        if name not in KEEP:
            if name not in REASON and not re.search(r"^disable-model-invocation: true", fm, re.M):
                raise SystemExit("no reason for manual-only: " + name)
            fm = add_disable(fm)
        out = "---\n%s\n---\n%s" % (fm, body)
        if out != text:
            with open(path, "w", encoding="utf-8") as f:
                f.write(out)
            print("updated:", name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
