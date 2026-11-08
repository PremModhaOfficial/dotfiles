---
name: making-skills
description: Write, review, and shrink agent skills (SKILL.md). Use when creating a new skill, editing an existing one, or when a skill feels too long, vague, or rigid.
---

A skill is a short set of orders, not a document. The agent needs constraints, not philosophy.

## Write

- One job per skill. Split if it does two.
- Name it for the job: lowercase, hyphenated, verb-first (`making-skills`).
- Write the description as the trigger: what it does + when to use it. Be specific enough to fire, narrow enough not to misfire.
- Use imperatives. "Do X. Never Y." Cut "should", "try to", "it is important".
- Keep the rule, drop the why. Keep the why only if the agent would otherwise break the rule.
- Use leading words that carry meaning ("relentlessly", "one at a time") instead of paragraphs.
- Say each rule once. Never restate it in a summary, glossary, or success list.
- Define a term inline where it first appears. Add a glossary only if terms are reused and unclear.
- Show one short example only if wording alone is ambiguous.
- Put detail in separate files, linked from the skill. Keep the core under one screen.

## Keep

- Hard safeguards: authorization, stale-state protection, ownership, bounds, verification.
- Terminal conditions. Every loop gets an end state and a budget.
- Rules that stop a real failure mode. Cut rules that only sound careful.

## Cut

- Repeated mantras across sections.
- Handoff, summary, or success sections that restate earlier rules.
- Explanations of how the agent already works.
- Hedges, intros, and "this skill helps you".

## Don't over-constrain

- State lifecycles as "typical", but require a terminal state.
- Name the hard line. Leave the rest to judgment.

## Know the layers

- Skill = behavioral policy. It cannot enforce anything.
- Runtime = persistence, events, cancellation, isolation, permissions.
- Never claim in a skill that a runtime capability exists. Say what to do when it doesn't.

## Review

Run these checks on any draft:

1. Does each line prevent a failure? Delete it if not.
2. Is any idea stated twice? Keep the strongest.
3. Can the agent act on each line without asking? Rewrite if not.
4. What breaks with two tasks, a late correction, a failure, or an unsafe request? Add a rule only for a real gap.
5. Is anything a rule trying to be a runtime feature? Move it or disclose the limit.
6. Does the description trigger on the right requests only?

## Ship

Shrink, then re-check that every safeguard survived. Stop when removing more makes the agent re-derive rules.
