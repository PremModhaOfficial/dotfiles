---
name: numbers-first
description: Every chat line you send a human carries a number, so state is countable and progress is visible. Use for /numbers-first, "numbers first", "numeric replies", "count everything", "make progress scannable". Chat only: never files, commits, or agent-to-agent messages.
---

# numbers-first

A chat reply is scanned, not read. A quantity per line makes state countable, progress visible, and a claim checkable in one glance.

Standalone. No dependency on i-have-adhd or ultracave, and no conflict with them: it only governs how chat text reads, never what gets built.

## Scope

**In:** text you write to the human in chat, including questions, failures, explanations and closers.

**Out:** files you write, commit messages, code and comments, PR/issue bodies, messages to subagents or other agents, tool arguments. Those keep normal prose.

Ambiguous, or a human reading it inside a file? Normal prose.

## Persistence

Every reply, whole session, until "stop numbers-first" or "normal mode".

## Shape

```
#56 unblocked, pushed, loop running.
Merged 7 · in flight 6 · blocked 0 · open 6
Next: I report when the loop lands.
```

Three habits, not a template:

1. **Anchor line** — one fact, one number.
2. **Tally line** — counts, `·` separated, short labels.
3. **Next line** — last line, always, with what remains.

A question, a failure, an explanation take the same treatment. Pick the shape that fits the fact, not the same three lines every time.

## Rules

1. **A line with no number gets rewritten**, or dropped. No adjectives doing work a count could do.
2. **Numbers are measured, never estimated.** Read them from a command, file or tool result. No number exists: write `0` or `1` when true, otherwise one plain sentence. Never invent a count.
3. **Names stay verbatim.** `#56`, `auth.ts:12`, `41 tests`, error strings. Digits-only is not the goal; the number attaches to the real name.
4. **Questions** — number the options, say how many answers you need.
5. **Failures** — how many failed, which line, how many still pass, cause and fix.
6. **Explanations** — files, lines, dependencies, counts that moved. The reasoning still gets its sentence; that sentence carries the number.
7. **State restated** — step n of m, items left. Nothing held over from an earlier turn.
8. **Next line last.**

## Loose on purpose

Not a rigid form. Two lines beat three when two carry everything. A count with a misleading name is worse than the name alone. The test is whether the reader can act and can tell what changed, not whether the shape matches the sample.

Break it for: a number that would be false, an irreversible action or security warning (full sentence, confirm first), a reader who is confused, anything persisted outside chat, and any harness rule that outranks it.

## Pre-send check

Count the lines. Every line has a number that something else dictated, not one you reached for to fill the shape. First line states the change, last line states what is next. Both readable alone, without the middle.
