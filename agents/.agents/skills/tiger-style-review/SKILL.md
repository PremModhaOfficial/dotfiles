---
name: tiger-style-review
description: "Code review focused exclusively on Tiger Style violations. Use when: review for safety, tiger style review, assert everything review, check my invariants, review this for correctness, /tiger-style-review."
---

Review diffs and code for Tiger Style violations. One line per finding:
location, what violates the style, what fixes it. Safety first, always.

## Format

`L<line>: <tag> <violation>. <fix>.`, or `<file>:L<line>: ...` for
multi-file diffs.

Tags:

- `assert:` missing assertion. A function argument, return value, invariant, or precondition that is used without being checked. Fix: name the assertion.
- `bound:` unbounded resource. A loop, queue, buffer, cache, or concurrency limit with no maximum. Fix: name the bound and enforce it.
- `error:` unhandled error. A failure path that is ignored, swallowed, or only logged. Fix: handle it explicitly.
- `flow:` hidden control flow. Recursion, magic, implicit conversion, or callbacks that hide the execution order. Fix: make it explicit or bound it.
- `scope:` variable declared too early or too widely. Fix: shrink scope, calculate near use.
- `alloc:` dynamic allocation or leak risk where a static/pooled resource belongs. Fix: pre-allocate or pool.
- `debt:` known problem deferred. A TODO, a known race, a potential latency spike, exponential complexity. Fix: solve it now.
- `naming:` ambiguous or abbreviated name. Fix: give the units-qualified name.
- `deps:` dependency added where stdlib or 10 lines of code would do. Fix: cut it.

## Examples

❌ "This function doesn't check if the index is valid before accessing the
array, which could lead to an out of bounds access."

✅ `L23: assert: index used before validity check. assert(index < items_len) before access.`

❌ "Consider whether this loop might run forever in some cases."

✅ `L41: bound: while loop has no upper bound. Add iteration_max and assert it.`

✅ `L67: error: fs.readFile error ignored. Handle ENOENT explicitly.`

✅ `L89: flow: recursion in walk(). Bound depth and assert it, or convert to explicit stack.`

✅ `L104: scope: batch_size declared 40 lines before use. Declare at the loop.`

✅ `L120: alloc: new slice per request in hot path. Pool it or pre-allocate at startup.`

✅ `L138: debt: TODO to handle overflow. Fix now, do not ship known overflow.`

✅ `L152: naming: to (ms? bytes?). Rename to timeout_ms or size_bytes.`

## Comment voice

When severities are mixed, prefix the tag:

- `🔴 bug:` broken behavior, will cause an incident.
- `🟡 risk:` works but fragile (race, missing null check, swallowed error).
- `🔵 nit:` style, naming, micro-optimisation. The author can ignore it.
- `❓ q:` a genuine question, not a suggestion.

Drop: "I noticed that", "it seems like", "you might want to consider",
"this is just a suggestion but..." (use `nit:` instead), hedging ("perhaps",
"maybe", "I think"; use `q:` when unsure), praise on every comment (say it once
at the top), and any restatement of what the line already does.

Worked before-and-after:

❌ "I noticed that on line 42 you're not checking if the user object is null
before accessing the email property. This could potentially cause a crash if the
user is not found in the database. You might want to add a null check here."
✅ `L42: 🔴 bug: user can be null after .find(). Add guard before .email.`

❌ "It looks like this function is doing a lot of things and might benefit from
being broken up into smaller functions for readability."
✅ `L88-140: 🔵 nit: 50-line fn does 4 things. Extract validate/normalize/persist.`

❌ "Have you considered what happens if the API returns a 429? I think we
should probably handle that case."
✅ `L23: 🟡 risk: no retry on 429. Wrap in withBackoff(3).`

Keep: exact line numbers, exact symbols in backticks, a concrete fix rather
than "consider refactoring", and the why when the fix is not obvious from the
problem.

Auto-clarity: a security finding (CVE-class), an architectural disagreement,
or an author who is new to the code gets a normal paragraph with the reasoning,
then terse resumes for the rest.

## Scoring

End with the only metric that matters: `safety: <N> violations. <M> critical.`

If there is nothing to fix, say `Solid. Ship.` and stop.

## Not this one

`flow`'s default review is `ds-review-loop` (the loop with a fresh reviewer).
`code-review` runs the standards and spec axes. `ponytail-review` judges the
whole change for correctness, scale and bloat. This one is only the safety and
invariant tags above.

`caveman-review` is the standalone terse review: same one-line shape, the four
severity prefixes, no Tiger Style tag taxonomy. It owns comment voice with no
safety pass; `## Comment voice` above is that same contract applied to these
tags, which is why this file carries it rather than deferring. Use this one
whenever the ask involves invariants.

## Boundaries

Scope: Tiger Style safety and correctness only. Style, taste, and feature
requests are out of scope. Performance is in scope only where it is a
correctness/safety issue (unbounded latency, exponential blowup). Does not
apply the fixes, only lists them. Does not approve or request changes, does not
run linters. Output the comments ready to paste into the PR.
"stop tiger-style-review" or "normal mode": revert to standard review style.
