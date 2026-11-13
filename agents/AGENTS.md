# /home/prm — machine orientation
A home directory, not a repository. The rules every session follows live in
`/home/prm/.agents/AGENTS.md` — read them there, not repeated here. Below is
only the layout and the traps that cost a session time.

## Who owns what

- `/home/prm/.agents` → `/home/prm/dotfiles/agents/.agents` (symlink), canonical
  home for rules, `skills/` and `references/`; editing it is a dotfiles commit
  (`git -C /home/prm/dotfiles status`).
- `/home/prm/.pi/agent` and `/home/prm/.commandcode` — pi and cmd state;
  `/home/prm/.jcode` — upstream-managed, read-only except via its updater.
- Other paths, full ownership list: `~/.agents/references/memory-harness-home.md`.

## Skills are the workflow layer

- Entry point for repository work is the `flow` skill (`/skill:flow` in pi): it
  names one skill per phase. Questions, research and chat do not need it.
- Do not re-derive the tree by reading the 126 `SKILL.md` files. Read
  `/home/prm/.agents/skills/README.md`: one generated table of every skill,
  its upstream and commit.

## Guard rules that bite

- Spawn agents interactive only: `hc run --bg --name <n> pi`, then `hc send`
  and `hc read`. One-shot `pi -p`, `claude -p`, `codex exec` through hc/herdr
  is blocked by `/home/prm/.pi/agent/extensions/herdr-interactive-only.ts`.
  Restated because a hook enforces it, not memory.
- Never edit `/home/prm/.agents/LEDGER.md`, `/home/prm/.pi/agent/{npm,git,sessions}`
  or `/home/prm/.commandcode/{sessions,projects,history.jsonl}`, and never edit
  `/home/prm/.jcode`: app-managed or app state. Which skills are editable, stated
  once here: every skill dir named in `~/.jcode/state/upstream-sources` (35 today)
  is sync-owned and changes only through `/home/prm/dotfiles/skills-overlay/<skill>.sh`,
  every other skill under `/home/prm/.agents/skills/` is committed dotfiles source and
  is edited at `/home/prm/dotfiles/agents/.agents/skills/<skill>/` (same file,
  through the repo path) and committed, never in place.
- Everything else: `/home/prm/.agents/AGENTS.md`.

## Facts that cost a day to learn

1. `bash /home/prm/.jcode/bin/update-all.sh --dry-run` is the one command that
   reconciles skills, overlays and harness configs; log at
   `/home/prm/.jcode/logs/update-all.log`.
2. No `graft` here; `rg` and `fd` come from `/home/prm/.pi/agent/bin` on PATH.
