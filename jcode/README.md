# jcode + tooling configs

Everything needed to keep the agent stack updated and reproducible, versioned in
this dotfiles repo so it survives machine changes.

## The one command

```bash
~/.jcode/bin/update-all.sh            # full update
```

It is a symlink to this file. It:

1. **jcode core** — fetches upstream (`1jehuang/jcode`), rebases our fork branch
   `local/turn-end-gate` (the babysitter turn-end-gate feature) onto upstream
   main, force-pushes it to our fork (`PremModhaOfficial/jcode`), and builds.
2. **Skills** — pulls upstream skill sources (ponytail/caveman, tiger-style,
   tuicr, babysitter, herdr) into `~/.jcode/updater-src`, re-syncs them into
   `~/.agents/skills`, and regenerates `babysit` with our jcode adaptation
   (harness=pi, in-turn continuation note).
3. **Tools** — mise herdr@latest, herdr-pickr plugin, babysitter SDK probe
   (npx always-latest), gopls.
4. **Configs** — installs these dotfiles into live locations, then commits and
   pushes the dotfiles repo:
   - `jcode/.jcode/config.toml` → `~/.jcode/config.toml`
   - `jcode/.jcode/hooks/*.sh` → `~/.jcode/hooks/` (herdr-agent-state,
     babysitter-gate)
   - `herdr/plugins/config/pickr/config.toml` → `~/.config/herdr/...`
   - `babysitter/processes/*.js` → `.a5c/processes/` + `~/.a5c/processes/`
5. **Manifest** — regenerates `~/.agents/skills/README.md` (skill → source →
   commit).

## Layout

```
jcode/
  update-all.sh              # THE updater (canonical; symlinked from ~/.jcode/bin)
  .jcode/
    config.toml              # jcode config incl. [hooks] (turn_end_gate opt-in)
    hooks/
      herdr-agent-state.sh   # reports agent state to herdr (observer hooks)
      babysitter-gate.sh     # turn_end_gate: babysitter continuation bridge
herdr/
  plugins/config/pickr/config.toml   # herdr-pickr: tuicr/hunk/delta/browser
babysitter/
  processes/jcode-turn-gate.js       # custom babysitter process (as code)
  turn-gate-*.json                   # example run artifacts
```

## Custom things that are preserved

- `local/turn-end-gate` jcode branch, maintained in `PremModhaOfficial/jcode`
- `babysitter-gate.sh` — the turn_end_gate hook (opt-in; uncomment in config)
- `babysitter/processes/jcode-turn-gate.js` — the orchestrator process
- herdr pickr config (tuicr default) + herdr-agent-state hook
- any skill in `~/.agents/skills/` with no upstream listed in the updater

## First-time / notes

- Requires the jcode build with the `turn_end_gate` feature (the fork branch,
  or newer upstream). `jcode self-dev --reload` after a rebuild.
- Pushing the jcode fork needs `workflow` scope on the gh token:
  `gh auth refresh -h github.com -s workflow`
- `update-all.sh --dry-run` shows every step without touching anything.
