---
name: tiger-style-audit
description: "Whole-repo audit for Tiger Style safety. Use when: audit this codebase, tiger audit, audit for safety, find the unguarded paths, harden this repo, /tiger-style-audit."
---

Audit the whole codebase for Tiger Style violations. Do not read every file
cover to cover. Use targeted grep/glob to find risk patterns, then read the
hot spots to confirm. Report ranked by severity: what will bite first.

## Method

1. **Inventory.** Map the entry points: main functions, request handlers,
   public APIs, and their call graphs.
2. **Pattern scan.** Grep for the risk patterns:
   - `while` loops without obvious bounds, `for (;;)`, `loop {`
   - `TODO`, `FIXME`, `XXX`, `HACK`, `later`
   - recursion (functions calling themselves)
   - ignored errors: `_ =`, bare `try`, `except: pass`, empty `catch`
   - dynamic allocation in hot paths: `new`, `malloc`, `make(`, `alloc`
   - architecture-dependent types: `usize`, `size_t`, `int`, `long`
   - global mutable state
3. **Confirm hot spots.** Read the files where patterns cluster. Count real
   violations, not pattern hits.
4. **Report.** Ranked list, most likely to cause production failure first.

## Report Format

`<file>:L<line>: <tag> <violation>. <fix>.` then a scoreboard:

```
## Safety Scoreboard
- Assertions: 12 functions, 7 lack any check (58% coverage)
- Bounds: 4 unbounded loops, 2 unbounded queues
- Errors: 6 swallowed errors, 1 in a money/security path
- Allocation: 3 alloc-per-request in hot paths
- Debt: 9 TODOs, 2 are known races
- Dependencies: 31 total, 4 only used for one call
```

## Ranked Findings

1. `<severity: critical|high|medium|low>` first item
2. ...

## Boundaries

One-shot report. Does not apply fixes. Correctness and safety only; feature
requests and taste out of scope. When asked to fix afterwards, switch to the
main tiger-style mode. "stop tiger-style-audit": revert.
