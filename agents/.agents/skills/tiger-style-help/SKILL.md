---
name: tiger-style-help
description: >
  Quick-reference card for all tiger-style modes, skills, and commands.
  One-shot display, not a persistent mode. Trigger: /skill:tiger-style-help,
  "tiger style help", "what tiger commands", "how do I use tiger-style".
---

# Tiger Style Help

Display this reference card when invoked. One-shot, do NOT change mode,
write flag files, or persist anything.

## Levels

| Level | Trigger | What change |
|-------|---------|-------------|
| **Lite** | `/tiger-style lite` | Build what's asked, flag missing assertions and unbounded resources in one line. |
| **Full** | `/skill:tiger-style` | All pillars enforced: assertions, bounds, explicit control flow, performance sketches. Default. |
| **Strict** | `/tiger-style strict` | NASA-grade. Paired assertions, every resource bounded, every branch has an else, zero warnings. |

Level sticks until changed or session end.

## The Protocol

Before writing any code, run through these seven steps. Stop at the first one that applies.

| Step | Question | Action |
|------|----------|--------|
| **1. Assert** | What can go wrong? | Add an assertion for it. Every function: ≥2 assertions. |
| **2. Bound** | What's the limit? | Name it. Every loop, queue, buffer, concurrency pool gets a fixed max. |
| **3. Sketch** | What's the cost? | Back-of-the-envelope over the four resources × bandwidth, latency. |
| **4. Simplify** | Can this be less? | Cut the abstraction. Use stdlib. One line beats fifty. |
| **5. Name** | Is the name right? | Units-qualified, big-endian: `latency_ms_max`. Same char count for related names. |
| **6. Explain** | Why does this exist? | Say why in comments and commit messages. |
| **7. Commit** | Does the commit say why? | Conventional Commits. Subject ≤50 chars. Body only when why is not obvious. |

## Skills

| Skill | Trigger | What it does |
|-------|---------|--------------|
| **tiger-style** | `/skill:tiger-style` | Safety-first coding mode itself. Assert everything, bound everything. |
| **tiger-style-review** | `/skill:tiger-style-review` | Safety review: `L23: assert: index used unchecked. assert(index < len) before access.` |
| **tiger-style-audit** | `/skill:tiger-style-audit` | Whole-repo safety audit, ranked by what bites first. |
| **tiger-style-commit** | `/skill:tiger-style-commit` | Commit messages that say why, not just what. |
| **tiger-style-help** | `/skill:tiger-style-help` | This card. |

## The Pillars (30-second version)

1. **Assert everything.** Arguments, returns, pre/postconditions, invariants. Minimum two assertions per function. Assert the positive AND negative space.
2. **Put a limit on everything.** Loops, queues, buffers, concurrency: fixed bounds, named and enforced. No recursion unless depth is proven bounded.
3. **Static resource management.** Pre-allocate and pool. Shrink scope. Calculate near use.
4. **Zero technical debt.** Solve problems now. No exponential algorithms, no known races, no "later".
5. **Performance by design.** Back-of-the-envelope sketches over the four resources (network, disk, memory, CPU) × (bandwidth, latency). Batch. Be roughly right within 90%.
6. **Explicit control flow.** Simple, visible, no magic. Split compound conditions. State invariants positively. Handle all errors.
7. **Naming and documentation.** Nouns and verbs just right. Units-qualified, big-endian: `latency_ms_max`. Always say why.
8. **Zero dependencies (spirit).** Every dependency is a risk. Stdlib or 10 lines first.

## Deactivate

Say "stop tiger-style" or "normal mode". Resume anytime with `/skill:tiger-style`.

There is no `off` level — the skill's levels are lite, full and strict only — so
`/tiger-style off` is not a trigger. Deactivate with the phrases above.

## Configure Default Mode

Default mode = `full`, auto-active every session.

**Pass the level as an argument** — this is the only mechanism a plain skill
install reads:
```
/skill:tiger-style lite
/skill:tiger-style strict
```

**Environment variable and config file** are read only when the Tiger Style
plugin hooks are installed (the repo's `hooks/tiger-config.js`, in
https://github.com/PremModhaOfficial/tiger-style). Without those hooks nothing
reads them, so exporting the variable or writing the file changes nothing:

```bash
export TIGER_STYLE_DEFAULT_MODE=strict
```

Config file (`~/.config/tiger-style/config.json`, Windows:
`%APPDATA%\tiger-style\config.json`), read by those hooks only:
```json
{ "defaultMode": "lite" }
```

With the hooks installed, `"off"` in that file turns auto-activation off at
session start, and you activate manually with `/skill:tiger-style` when wanted. That
is a config value for the hooks, not a `/tiger-style off` trigger.

Resolution (hooks only): env var > config file > `full`.

## More

Tiger Style is adapted from TigerBeetle's official style guide:
https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md
and tigerstyle.dev. The skill repo lives at:
https://github.com/PremModhaOfficial/tiger-style
