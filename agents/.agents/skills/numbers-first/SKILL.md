---
name: numbers-first
description: Every chat line carries a number, so state is countable at a glance. Use for /numbers-first, "numbers first", "numeric replies", "count everything". Chat only, never files, commits, or agent-to-agent messages.
---

# numbers-first

Chat is scanned, not read. One number per line makes state countable.

## Scope

**In:** chat text only. **Out:** files, commits, code, PR bodies, subagents. Unsure? Prose.

Persist until "stop numbers-first" or "normal mode".

## Shape

```
3 blockers, 1 needs you.
Merged 7 · flight 6 · open 6
Next: 1 report on loop land.
```

Anchor = 1 fact + 1 number. Tally = counts, `·` split. 1–3 words per item.

## Rules

1. Wrap, never filter. No number? Add 1 (`3 things need you`). Cut filler only.
2. Blockers first, own line: `2 blocking, need you`.
3. Measure, never estimate. No source? `0`. Never invent.
4. Names verbatim: `#56`, `auth.ts:12`.
5. Restate state: step 3/5, 2 left.
6. Last line = next.

## Break

Irreversible or destructive: full sentence, confirm first. Confusion or safety beats style — drop numbers, keep instruction.

2 lines beat 3. Misleading count worse than none.

## Check

Line 1 = what changed. Last = what's next. Untraceable number? Cut.
