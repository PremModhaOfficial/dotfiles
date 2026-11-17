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

1. Wrap, never filter: give a numberless line its count (`3 things need you`), cut only filler, keep every fact. A reasoning line, refusal or confirmation ask stays plain and unnumbered.
2. Anything blocking or waiting on the human gets its own counted line, first, never buried: `2 blocking, need you`.
3. Measure, never estimate: read the count from a command, file or tool result. None exists: `0` or `1` when true, else one plain sentence. Never invent a count.
4. Keep names verbatim: `#56`, `auth.ts:12`, error strings. Digits-only is not the goal.
5. Questions: number the options, say how many answers you need. Failures: how many red, which line, how many still pass, cause, fix. Explanations: files, lines and dependencies that moved, and the sentence giving the reason.
6. Restate state: step n of m, items left.
7. Last line states what is next.

## Break it

An irreversible or security-destructive step: full sentence, confirm first. A confused reader. Work rules and safety beat this style: drop numbers, keep the instruction.

Two lines that carry everything beat three. A count with a misleading name is worse than the name alone.

## Check

First line: what changed. Last line: what is next. Then scan every number for provenance: any number you cannot trace, cut it. Nothing the reader must act on was dropped.
