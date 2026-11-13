# Clarify: the ambiguity rule (authoritative)

The single full definition of the ambiguity rule. It lives here because the rule fires
before any skill is loaded: `AGENTS.md` states the threshold and `flow` points here rather
than carrying a second copy. Do not restate this wording elsewhere.

Score each prompt 0-10 before acting, short ones and follow-ups included; above 3, do not
start the task.

- Scale: 0 = one reading, complete requirements; 10 = no usable reading.
- Ask at most 4 score-moving questions per round, re-score, act at <= 3.
- State the score and competing readings in one line before asking.
- Ask only about ambiguities that change the work; never about preferences.
- Never resolve ambiguity by silent assumption.
- Told to skip: state score, open readings, assumption; proceed only on confirm.

Decision 2026-11-13 (FIX-6): where the older `flow` one-liner disagreed with the wording
above, this file won — a question must be score-moving and about the work (not a
preference), the four-question budget resets per round, the score is announced before
asking, and a refusal gets the open readings and the assumption stated.

## Why the rule exists

A wrong assumption costs a whole turn of work; one question costs one line. That
trade is the whole reason the score exists, and it is the argument to use when a
user pushes back on being asked.
