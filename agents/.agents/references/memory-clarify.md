# Clarify: the ambiguity rule (authoritative)

The single full definition of the ambiguity rule. It lives here because the rule fires
before any skill loads: `AGENTS.md` carries the gate as one bullet block, the pi fragment
adds nothing, and `flow` points here instead of copying. Do not restate this wording.

Score each prompt 0-10 before acting, short ones and follow-ups included. The score says
what the next action is; it is not a stop sign on its own. Scale: 0 = one reading,
complete requirements; 10 = no usable reading.

## First: can a human answer?

Decide this before deciding what a score above 3 means, because it changes what asking
costs.

- **Unattended** = no person can reply in this session. True when the request arrived from
  another agent (intercom, `hc`, a delegated worker, a peer); from a scheduled or background
  run (`hc run --bg`, cron, a watcher, a hook); from a task file, ticket or loop artifact
  rather than a live message; or the session was launched with a task (a prompt, a script, a
  queued task) instead of by a person typing.
- **Check it, do not feel it.** `hc ls` prints every terminal; `$HC_TERMINAL_ID` names
  yours, and a `parent` on that entry means another agent launched you. A prompt that names
  a task and nothing conversational, with nobody mid-conversation, is a task.
- **Attended** = someone can reply now, with evidence: a person in the conversation,
  answering or steering. A session a person opened and is sitting in, with no scheduler,
  peer or parent in the chain, is attended.
- **Cannot tell = unattended.** A reversible reading costs one revert; a stall costs the
  run, so doubt resolves toward acting.

## Attended

- At most 4 questions per round, in one message, each able to change the score or the work.
- Never about taste or preference.
- Announce the score and what you weigh before asking; re-score after the answers.
- Act at <= 3. Above 3, do not start.
- Told to start anyway: state the score and the reading you guessed, then go.

## The reading is one visible line

Before any tool call, your first visible line of output states the reading — assistant text
the user can see, never reasoning:

    Reading: <what you take the prompt to mean>, because <evidence or the gap>.

Same shape every time, so it is greppable. A reply that starts with a tool call has broken
this rule. Then take the cheapest step that can falsify the reading. No gap is ever filled
silently: the line is the record, and the reading is chosen so being wrong is cheap to
undo. This is what lets an unattended run proceed — visible and reversible.

## Unattended: never stall

A question with nobody to answer it is not one line of cost; it ends the run. So:

- Do not stop to ask. Take the cheapest step that can falsify the reading — one read, one
  grep, one command, one test — before deciding anything larger.
- A question is allowed only if a human is reachable. When none is, it becomes one line in
  the report ("open question: X; I took Y"), never a stop.
- Prefer the reading whose failure is reversible in one command. A reading expensive to
  undo earns a smaller step first, not a stop.

## Re-score on evidence, always

Any command, file read or test that resolves or moves an ambiguity re-scores the task
before anything else happens, attended or not. If the score drops to <= 3, continue; if it
rises, use the new score to pick the next cheapest step. A score taken during recon and
never revised is the bug: 8/10 held after the evidence that made it a 3 is a frozen score.

Decision (IT2-1): a told-to-start override wins; the gate stops silent guessing, not a
person who decides for you. Decision (FIX-6): this file beats any older `flow` one-liner.
Decision (IT4-1): no dependency on a human being present — unattended runs name a reading,
take the cheapest falsifying step, continue, and re-score. Decision (IT4-3): the reading
must be a visible `Reading:` line, never only reasoning.
