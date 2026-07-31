---
name: update-all
description: Run the self-maintaining update for the whole agent stack (jcode fork rebase, skills sync, tools, configs, manifest) and then reload so the new list is live. Use when asked to "update everything", "update all", "self-update", "keep the stack fresh", or to run the high-level maintenance workflow. Invokes ~/.jcode/bin/update-all.sh and verifies the result.
version: 1.0.0
---

# update-all — self-maintaining stack update

The user wants the entire agent stack updated in one shot, keeping our custom
features on top, then having the fresh skill list take effect immediately, and
finally proving the update worked. Do ALL of the following, in order.

## 1. Run the updater

Run the canonical updater (symlinked from dotfiles, so it survives machine
changes and is itself versioned):

```bash
~/.jcode/bin/update-all.sh
```

It performs, in order:

1. **jcode core** — fetches upstream (`1jehuang/jcode`), rebases our fork branch
   `local/turn-end-gate` (the babysitter turn-end-gate feature) onto upstream
   main, force-pushes it to our fork `PremModhaOfficial/jcode`, and builds.
2. **Skills** — pulls ponytail/caveman, tiger-style, tuicr, babysitter, herdr
   into `~/.jcode/updater-src`; re-syncs them into `~/.agents/skills`;
   regenerates `babysit` with our jcode adaptation (harness=pi).
3. **Tools** — mise herdr@latest, herdr-pickr plugin, babysitter SDK probe,
   gopls.
4. **Configs** — installs dotfiles configs live (jcode config + hooks, pickr
   config, babysitter processes) and commits + pushes the dotfiles repo.
5. **Manifest** — regenerates `~/.agents/skills/README.md` (skill → source →
   commit).

Use a long timeout (the first run clones skill sources and may rebuild jcode;
subsequent runs are fast). If it fails, read the tail of
`~/.jcode/logs/update-all.log` and fix the specific step before proceeding.

## 2. Reload so the new list is live

After the updater succeeds, make the fresh skill list take effect in the
current session:

```bash
# jcode: reload all skills (this agent)
jcode skills reload-all   # or use the skill_manage reload_all equivalent
```

If jcode core itself was rebuilt, tell the user to run `jcode self-dev --reload`
(or restart jcode) so the new binary with the `turn_end_gate` feature is active.

## 3. Verify and report

Confirm the update actually landed:

- Check the manifest exists and count the skills:
  `head -5 ~/.agents/skills/README.md`
- Confirm the custom bits survived: `local/turn-end-gate` is still on the fork
  (`gh api repos/PremModhaOfficial/jcode/branches/local/turn-end-gate`),
  `babysit` still carries the "jcode harness note", `babysitter-gate.sh` is in
  `~/.jcode/hooks/`.
- Check the log tail: `tail -10 ~/.jcode/logs/update-all.log`.

Then give the user a short summary:

```
Updated: <jcode core? skills? tools? configs?> 
Skills now: <N> (from <manifest>)
Custom bits preserved: turn-end-gate on fork ✓, babysit harness=pi ✓, babysitter-gate ✓
Log: ~/.jcode/logs/update-all.log
Next: <anything needing a restart, or ready to work>
```

## Notes

- `~/.jcode/bin/update-all.sh` is a symlink to
  `~/dotfiles/jcode/update-all.sh` (canonical, versioned in dotfiles).
- Our custom things are preserved every run: `local/turn-end-gate` jcode
  branch, babysitter-gate hook, babysitter processes, pickr config, herdr
  hook, and any skill with no upstream source.
- Use `--dry-run` first if the user wants to preview.
