---
name: flow
description: "Order of operations for real repository work on this machine. Use when: starting, resuming a bug fix, a feature, a pull request, a rule learned earlier applies."
---

# flow

Order and exits. The skills keep their own rules; this only says which one runs when.

## Before you start

- **Ambiguity gate.** The rule, its scale, its question budget and the visible `Reading: X, because Y` line have one home: ~/.agents/references/memory-clarify.md. Read it before acting. This skill adds only the order: the gate runs before Locate, and the escape hatch below skips Plan, never the gate.
- **Precedence when they disagree:** checked code > rules learned below > this table.
- **Escape hatch.** Run Locate first. If its file:line list names one file and the change is a small edit, skip Plan: go to the build skill and its check. No line counting.

## Phases

| Phase | One default | Exit |
| --- | --- | --- |
| **Locate** | plain grep, find and read calls | you can name every file the change reaches, plus its callers and tests |
| **Plan** | `ds-plan-loop` when more than one file changes, `ds-blueprint` when the shape is undecided | its own stop condition holds |
| **Build** | `diagnosing-bugs` cause unknown · `surgical-patch` bug with a known cause · `lean-build` feature · `ds-tdd` bug with a cheap test · `migration` schema or data · `safe-refactor` moves · `prototype` open design question. `ds-verify-loop` on any failure | its own stop condition holds, with the check output read |
| **Review** | `ds-review-loop` in a fresh context (see below) | its own stop condition holds |
| **Ship** | `ds-ready`; `ds-ship` only when the user asked to merge | its own stop condition holds, PR URL printed |

Escalate inside a phase when the task demands it: `ds-jury` high-stakes multi-model review ·
`code-review` standards and spec · `ponytail-review` bloat · `tiger-style-review` safety ·
`ds-blast-radius` risky diff · `ds-adopt` inherited PR · `ds-revive` stale PR · `ds-unstick`
two failed fixes · `ds-pr-comments` any comment posted as the user · `cavecrew` cheap
locate, edit or review delegation.

## Fresh context

A review is worth more from a context that never saw the discussion. Find the mechanism first;
do not assume this session has one:

| If this session has... | Use |
| --- | --- |
| T3 Code tools (`delegate_task`, `watch_pull_request`) | delegate with the model pinned; the parent still owns the PR |
| herdr (`HERDR_ENV=1`, hc on PATH) | `hc run --bg --name rev pi`, then `hc send`; the report arrives by intercom; never sleep-poll |
| another agent CLI (cmd, claude, codex) | run it as the reviewer and capture its output |
| none of these | review in this context, label it "not a fresh-context review", and say why |

Probe, do not guess:

```bash
echo "herdr=${HERDR_ENV:-0}"; command -v hc cmd claude codex 2>/dev/null
```

The probe decides more than review: T3 Code owns PR delegation and watching, herdr owns panes
and spawns, plain Pi owns neither. Name the mechanism you actually used in the report, and
never present a same-context review as a goldfish review. The same ladder runs
`caveman-explore` and the EGM reviewers.

## EGM, where it pays

`egm-brainstorm` when the idea is not yet requirements · `egm-draft` then `egm-review` for
an architecture worth a document · `egm-drift-report` when a doc may have drifted from the
code · `egm-review-loop` over this skill's rules file when it gets long or self-contradictory.
Never for a bug fix, which is EGM's own rule.

## Before you stop

If the user corrected you twice, a check failed twice, or a rule below proved wrong, run
`ds-lessons`. If it yields a durable rule, append one line to the rules file
(`~/dotfiles/agents/.agents/skills/flow/rules.md`, then commit the dotfiles repo):

```
- 2026-11-13 | rule text here
```

Dated, one physical line, max 15. A rule older than ten tasks that no task has confirmed
gets deleted at the next audit. Structural fixes beat prose: if a check, type or test can
carry the lesson, it goes there instead and no rule is written.

## Rules file

`flow` is not a synced skill, so the file that runs is the git-tracked dotfiles file:
write it through the repo path and commit, never as an uncommitted in-place edit. Which
skills are editable and which are sync-owned is stated once, in the bullet
`Which skills are editable, stated once here` in `/home/prm/AGENTS.md` — not restated here.
To check the tree you are in:
`cut -f1 ~/.jcode/state/upstream-sources | grep -qx flow` exits 1, which is "not
sync-owned, edit the dotfiles file".

Read it when it has rows; skip it until then:

```bash
R=~/dotfiles/agents/.agents/skills/flow/rules.md   # same file as ~/.agents/skills/flow/rules.md
[ "$(grep -c '^- ' "$R")" -gt 0 ] && cat "$R"
```

Run the self-check after editing it:

```bash
bash ~/.agents/skills/flow/scripts/check.sh
```

It fails on a malformed rule, more than 15 rules, a missing rules file, or a skill named
here that is not installed.
