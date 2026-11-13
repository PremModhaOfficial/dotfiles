---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS (`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows) - not the current workspace.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

## Start the fresh agent (optional)

The document alone is enough. If the user wants the new agent running immediately, seed it with the file as its prompt. Any installed agent CLI works; this card uses `pi` as the example (confirm it is there with `command -v pi`):

```bash
pi -n "<descriptive name>" -p "$(cat <summary file>)"
```

`-p`/`--print` runs non-interactively and exits when the run finishes; add a trailing `&` to keep working while it runs. It starts in the current working directory. Passing the file keeps the shell from running backticks or expanding `$` in the summary. The user finds the run again with `pi --resume`.

Always pass `-n`/`--name` with a descriptive name (e.g. `--name "Fix login bug"`); it sets the session display name in the picker and terminal title. For another agent CLI (`codex`, `cmd`, `opencode`), take its own name and non-interactive flags from `--help` — do not reuse `pi`'s flags on a different binary.

## Not this one

`ds-context-reset` keeps the state in a `PROGRESS.md` committed in the repo and resets inside it, which is the opposite of this card's "portable file, outside the workspace". Use that one for a long task in one repo; use this one for a new harness, a new directory, a colleague, or a side task forked mid-phase.
