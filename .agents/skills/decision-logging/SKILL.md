---
name: decision-logging
description: Maintain a running decision log while working: record every decision the agent makes that the user did not explicitly specify, with reasoning and alternatives rejected. Use when starting any multi-step task, implementation, or exploration session, or when the user asks for a decision log / "why did you do X" review.
---

# Decision Logging

Log every decision you make that the user did not explicitly specify. Explicit instructions need no entry — autonomous choices do.

## The rule

The moment you make a choice the user did not dictate, write one log entry before moving on. If a task produces zero autonomous decisions, write no entries and say so when reporting.

## Log location and format

- Default: `DECISIONS.md` in the project root (create on first entry).
- If a scratchpad/session directory is provided and the log is ephemeral, put it there instead and say so.
- Format, one entry per decision, appended chronologically:

```markdown
## YYYY-MM-DD HH:MM — <short title>

- **Decision:** what you chose, in one sentence.
- **Why:** the reasoning, including what you observed that forced the choice.
- **Alternatives rejected:** what else was on the table and why it lost.
- **Source:** who/what prompted it — inferred from code, prior user preference, deepwiki/web finding, etc.
- **Reversible:** yes/no, and how to undo.
```

## What counts as a decision

- Naming things (files, functions, variables) the user did not name.
- Picking a library, command, flag, or approach with a viable alternative.
- Choosing scope: what to skip, simplify, or defer.
- Choosing config values, defaults, thresholds.
- Resolving ambiguity by assuming (log the assumption — this is the most important category).

## What does NOT count

- Anything the user explicitly specified (quote it instead if it matters).
- Mechanical consequences of an explicit instruction.
- Trivial syntax with no real alternative.

## Workflow integration

1. Start the log (or note its reuse) at the beginning of a multi-step task.
2. Append entries as decisions happen — never batch them at the end from memory.
3. When you change an earlier decision, append a new entry referencing the old one; do not rewrite history.
4. At task completion, summarize only the entries the user should review — decisions they may want to veto. Keep the summary under 10 lines; the file holds the detail.

## Example

User says: "fix the login bug." You discover two candidate causes and pick the token-expiry check.

```markdown
## 2026-01-15 14:03 — fixed token expiry check, not session refresh

- **Decision:** patched `<` to `<=` in `auth/token.go:41` instead of adding a session-refresh retry.
- **Why:** repro showed tokens dying exactly at boundary; refresh would mask the bug.
- **Alternatives rejected:** session-refresh retry (masks cause, more code).
- **Source:** traced repro log; expiry == session length in failing requests.
- **Reversible:** yes — one-character revert.
```
