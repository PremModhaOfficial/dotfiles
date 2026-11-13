---
name: tiger-style-commit
description: "Commit message generator that follows Tiger Style's documentation rules: say why, not just what; be descriptive, precise, and delight the reader. Use when: write a commit, generate commit, /skill:tiger-style-commit."
---

Write commit messages the Tiger Style way: the reader of `git blame` must
understand not just what changed, but why it had to change.

## Rules

- Conventional Commits: `type(scope): subject`.
- Subject ≤ 50 chars, imperative mood, no trailing period.
- Explain the why in the body only when it is not obvious from the subject
  and diff. Code alone is not documentation.
- Name the invariant protected, the assertion added, the bound enforced,
  or the debt paid off. Safety changes say what failure mode they prevent.
- Never claim what the diff does not do. No filler, no changelog prose.
- If the change removes a `tiger:` comment, say the debt is now paid.

## Examples

```
fix(journal): assert checksum before every read

The previous read path trusted the stored checksum and only verified
it after use. A corrupted sector was detected one operation too late.
Checksum is now asserted immediately after the read, pairing with the
assert before the write.
```

```
feat(pipeline): bound queue at 1024, assert full before enqueue

Latency spikes were possible under backpressure because the queue was
unbounded. This makes the ceiling explicit and fail-fast.
```

```
perf(compaction): batch fsyncs, one per 16 blocks

A single fsync per block capped throughput at ~400 IOPS on spinning
disk. Amortizing over 16 blocks lands within the 90% sketch for the
slowest resource.
```

## Auto-Clarity

Never compress safety-critical details: the failure mode being prevented,
the exact bound added, or the invariant now enforced must be stated in full.

## Boundaries

Only the commit message. Does not stage files, does not run hooks, does not
amend history. "stop tiger-style-commit": revert to normal commit style.
