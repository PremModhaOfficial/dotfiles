# Reference: question bank, failure modes, composition

## Question bank by fork type

| Fork | The question that resolves it | What a bad answer looks like |
|---|---|---|
| Outcome | "What does done look like, and who sees it?" | "Make it better" — unobservable |
| Boundary | "What is explicitly out of scope?" | Nothing named, so everything is in scope |
| Authority | "May I touch X without asking?" | Every step becomes a permission request |
| Reversibility | "If this is wrong, how expensive is the undo?" | Unknown, so it stalls |
| Surface | "Where does the result live — file, pane, repo?" | Ambiguous, so it lands in the wrong place |
| Success proof | "What check proves it worked?" | "Looks good" — the supervisor's problem |
| Deferral | "What is the smallest version that is still useful?" | Full scope, no stopping point |

## Failure modes

- **Interview as procrastination.** Questions that only delay work. Fix: read the
  ground before asking; cap at two high-impact questions; then write the contract.
- **Interview as extraction.** Ten questions, no deliverable. Fix: the contract is
  mandatory output. Without it, the interview did not happen.
- **Forged intent.** Proposing an outcome the user never implied and treating
  agreement as consent. Fix: put the drafted outcome in front of them before any work.
- **Decision laundering.** Silently choosing an unstated fork. Fix: it goes in
  `ASSUMED`, reversible, never in the plan as if it were asked.
- **Recursion.** Interviewing the interview. Fix: the contract ends it.
- **Question spam in chat.** A wall of numbered forks. Fix: one question, and only
  when the answer changes the build.

## Composition

- **decision-logging** — every `ASSUMED` line becomes a ledger entry sourced
  "assumed after intent-interview". Logged assumptions are the only silent choices.
- **ask-first** — supplies the ranked fork list this skill narrows to one question.
  Redundant when this skill is active; keep this one.
- **caveman** — governs the chat register and the worker status line
  (`PASS` / `FAIL <reason>` / `BLOCKED <question>`), never the brief, the contract,
  or any prose another human reads.
- **writing-for-agents** — governs this skill's own construction: single source of
  truth, no-op sentences deleted, leading words over restatement, reference behind
  pointers.

## Contract template

```markdown
OUTCOME: <one sentence artifact or behaviour, and who sees it>
DONE WHEN: <the check, and the literal output that means pass>
ASSUMED: <fork> = <pick> (reversible)
OUT OF SCOPE: <named exclusions>
```
