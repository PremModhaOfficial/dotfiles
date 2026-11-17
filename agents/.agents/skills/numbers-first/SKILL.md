---
name: numbers-first
description: Every chat line carries a number, so state is countable at a glance. Use for /numbers-first, "numbers first", "numeric replies", "count everything". Chat only: never files, commits, or agent-to-agent messages.
---

# numbers-first

Chat is scanned, not read. A quantity per line makes state countable and a claim checkable.

## Scope

**In:** text you write to the human in chat. **Out:** files, commit messages, code and comments, PR/issue bodies, messages to subagents, tool arguments. Unsure, or a human reads it inside a file? Normal prose.

Persist every reply until "stop numbers-first" or "normal mode".

## Shape

```
#56 unblocked, pushed, loop running.
Merged 7 · in flight 6 · blocked 0 · open 6
Next: I report when the loop lands.
```

Habits, not a template: anchor line is one fact and its number; tally line is counts, `·` separated.

## Rules

1. A line with no number gets rewritten or dropped, except the one line carrying the reasoning, a refusal, or a confirmation ask.
2. Measure, never estimate: read the count from a command, file or tool result. None exists: `0` or `1` when true, else one plain sentence. Never invent a count.
3. Keep names verbatim: `#56`, `auth.ts:12`, error strings. Digits-only is not the goal.
4. Questions: number the options, say how many answers you need. Failures: how many red, which line, how many still pass, cause, fix. Explanations: files, lines and dependencies that moved, and the sentence giving the reason.
5. Restate state: step n of m, items left.
6. Last line states what is next.

## Break it

An irreversible or security-destructive step: full sentence, confirm first. A confused reader. Work rules and safety beat this style: drop numbers, keep the instruction.

Two lines that carry everything beat three. A count with a misleading name is worse than the name alone.

## Check

Read the first and last line only. What changed? What is next? Every number traces to a command, file or tool result. All three answered, send.
