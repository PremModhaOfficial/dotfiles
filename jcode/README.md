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
  bin/
    jcode-theme              # switch TUI color palettes (fluoromachine flavors, etc.)
  themes/
    delta.toml               # fluoromachine flavor: delta  (the active palette)
    fluoromachine.toml       # fluoromachine flavor: fluoromachine
    retrowave.toml           # fluoromachine flavor: retrowave
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

## Switching the TUI theme

jcode reads its palette from the `[display.colors]` block in `~/.jcode/config.toml`.
The theme switcher swaps that block from a preset in `jcode/themes/`:

```bash
~/.jcode/bin/jcode-theme            # list themes + which is active
~/.jcode/bin/jcode-theme delta      # apply the delta palette
~/.jcode/bin/jcode-theme retrowave  # apply the retrowave palette
~/.jcode/bin/jcode-theme fluoromachine
~/.jcode/bin/jcode-theme export     # print the current palette as TOML
```

The three fluoromachine flavors (from `maxmx03/fluoromachine.nvim`) are
pre-baked: `delta` (active), `retrowave`, and `fluoromachine`. The new palette
takes effect on the next jcode launch; to apply to the running TUI without
restarting, run `/colors` in jcode (any edit triggers a re-read).

### herdr theme switcher

Same three fluoromachine flavors, for the herdr TUI (`~/.config/herdr/config.toml`).
The switcher and presets live with herdr under `~/.config/herdr/`:

```bash
~/.config/herdr/bin/herdr-theme     # list themes + which is active
~/.config/herdr/bin/herdr-theme delta      # apply the delta palette
~/.config/herdr/bin/herdr-theme retrowave  # apply the retrowave palette
~/.config/herdr/bin/herdr-theme fluoromachine
~/.config/herdr/bin/herdr-theme export     # print the current theme config
```

Presets live in `~/.config/herdr/themes/` (sourced from `herdr/themes/` in this
repo) and map each flavor onto herdr's 16 color tokens (`accent, panel_bg,
surface*, text, mauve, green, yellow, red, blue, teal, peach`). Herdr picks the
change up on reload (prefix+shift+r) or the next launch.

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
