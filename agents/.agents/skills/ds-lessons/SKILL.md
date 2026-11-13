---
name: ds-lessons
description: "Use when: /ds-lessons, a user correction, the same fix comes up twice, at the end of a long session, a retro."
---

# ds-lessons

An instruction an agent can skip is a wish. Make repeated mistakes fail loudly instead.

## Steps

1. Gather mistakes. Read the current session, recent commits, reverts, review comments, agent instruction files and workaround comments. Group them into classes. A class counts once it happened twice.
2. Scan the environment, not the code. For the session the user names (default: this one) read the primary sources — session logs on this machine, the repo's own check command (`package.json`/build-tool `lint`/`check` scripts, its CI workflow) — and look for:
   - **Navigation**: did finding the right file take too long? Hidden dependencies between files? Add a navigation pointer.
   - **Automated checks**: a mistake a lint, type or test could have caught. A repo that already has a check command but no pre-commit hook and no CI job running it is itself a finding. A mechanical violation (fixed syntactic pattern, banned API, import shape, file location) gets a deterministic check, full stop.
   - **Coding standards**: a rule the reviewer agent should enforce, or one it failed to catch. Reserve standards prose for judgement calls no guardrail could ever cover.
   - **Steering files**: instructions in `AGENTS.md`/`CLAUDE.md` that belong in standards or a check instead, and instructions that change nothing. Trigger: the AGENTS.md file is particularly large — in the repo OR the user's global scope.
   - **Tool economy**: expensive tool calls, a token-inefficient CLI or MCP tool. Information the agent lacked and a tee or a read-only grant would have given it.
   Context pressure decides the owner: the implementer is exploring and debugging, the reviewer only reads a diff. So the reviewer, not the implementer, carries the standards.
3. For each class, pick the highest level that works:
   1. Structure: one owner per piece of state, one supported way per task, hidden internals, delete old patterns an agent would copy.
   2. Types: make the bad state impossible to write.
   3. Lint or CI check: the error message names the right file, type or function to use. If the bad pattern is already common, fail only on new additions.
   4. Test: checks behavior, not internals.
   5. Docs or agent rules: only for judgment calls that cannot be checked. Add a short example of the failure.
4. Present these candidates to the user, in order of severity. Then stop unless the user asks for the fixes. `/ds-lessons` reports; it does not edit the repo unasked.
5. Fix the classes the user picks, one commit each.
6. Prove each new check. Re-introduce a real past mistake, run the check, and show it fails. Then remove it and show it passes.
7. Keep a table in the agent instruction file: rule, and what enforces it. If a rule already existed but nothing enforced it, treat it as a repeat and enforce it now.
8. End-of-session reflection: list what went wrong, what took extra loops and what the user corrected. Route each item to a check, a skill edit or a rule. Drop one-off issues.

## Where a fix lands

- `AGENTS.md`/`CLAUDE.md`: navigation pointers only, kept small; every agent in the repo pays for it.
- `CODING_STANDARDS.md`: read during review, not implementation. Judgement calls only. Add navigation pointers to docs folders if the standards file gets more than 1,000 lines long.
- Docs and skills: reference material, pointed at from the two files above rather than inlined. Look for existing docs before writing new ones. A skill is for prose docs or a user-invoked command; follow `writing-for-agents` for the wording.

## Stop when

- Each chosen class has an enforcement that you showed failing on a real mistake.
- Or you have presented the top three classes this session. Note the rest.

## Rules

- If the fix is structural, do not also add prose. The prose was the symptom.
- Report each class with evidence, the level chosen, and why a higher level did not work.
