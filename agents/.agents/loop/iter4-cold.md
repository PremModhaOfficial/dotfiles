# Iteration 4 — cold-machine discovery

Lens: does this setup survive a machine that is not this one. Read blind (no earlier
rounds). Every command ran with `HOME=/tmp/cold4` (or `/tmp/cold6`), verified before each
step; the live tree was never written except this file.

## Method

```
/tmp/cold4   fresh `git clone /home/prm/dotfiles dotfiles` — committed tree only (what a
             fresh machine gets), no uncommitted files, no ~/.jcode, no ~/.agents, no
             symlink fleet, no ~/.local share, no npm-global prefix
/tmp/cold6   same clone + the hand-made symlinks (~/.agents, ~/AGENTS.md) to test the
             documented bootstrap path
```

Guardrails used: `npm_config_prefix=/tmp/cold4/.npm-global` so no global install could
touch the real machine; network allowed (a new machine has network).

Run: `HOME=/tmp/cold4 bash /tmp/cold4/dotfiles/jcode/update-all.sh`
Result: **exit 1 — 73/82 steps OK, 8 failed, 1 skipped**. Nothing was installed into
`~/.jcode/config.toml`, `~/.jcode/hooks/`, `~/.pi/agent/AGENTS.md`, or the manifest.

What worked cold: the 5 upstream skill clones, 34 `sync_dir` copies, 17 overlays,
`skills-activation` (44 rewrites), `mise install herdr@latest`, `npm exec babysitter`,
`go install gopls`, the caveman signed installer, theme/config copies when called directly.
So the machine-independent parts are fine; the *assembly* is not.

The 8 failures: `update_core_phase`, `update_skills`, `skill catalogue cap`,
`generate_pi_agents`, `pi rules file`, `apply_pi_patches`, `pi patches`, and
`skip configs/manifest (earlier phase failed)`.

## Findings, ranked

### 1. A fresh machine installs **zero** configs: the config phase is gated behind a phase that can never pass cold
`jcode/update-all.sh:207` (`[ -d "$JCODE_SRC/.git" ] || fail "no jcode source …"`, with
`JCODE_SRC="$HOME/.jcode/source/jcode"` at `:64`), and the gate at `:960` / `:968`
(`if [ "$rc" = 0 ]` … `else checklist_add skip "configs/manifest (earlier phase failed)"`).
`~/.jcode/source/jcode` is created by `jcode self-dev --setup` — a jcode feature, not
something this repo provides. On a fresh machine core fails in <1s, so `sync_configs` and
`write_manifest` are skipped by design.
Symptom: `update-all finished (exit=1)` and no `~/.jcode/config.toml`, no hooks, no
`~/.jcode/themes`, no `~/.a5c/processes`, no `~/.agents/skills/README.md` — even though
every one of those files exists in the repo and the config step then succeeds in isolation
(verified: `sync_configs` called directly returns 0).

### 2. `~/.agents` is a hand-made symlink; nothing in the repo creates it, and the sync silently installs 35 of 130 skills without it
`jcode/update-all.sh:65` (`SKILLS_DIR="$HOME/.agents/skills"`), `jcode/gen-pi-agents.py:91`
(`default=HOME / ".agents/AGENTS.md"`), `agents/.agents/references/memory-harness-home.md:50`
(“made by hand (`ln -s`)”).
Cold, `mkdir -p "$SKILLS_DIR"` created a real directory and wrote 35 synced skills into it:
`dotfiles/agents/.agents/skills` has **130** entries, the cold `~/.agents/skills` got **35**.
Symptom: fewer than a third of the skills exist; 10 overlays log
`OVERLAY-WARN: no installed skill …` (`ai-image-generation cua-driver ghostex-agents
ghostex-browser-use ghostex-cli ghostex-computer-use ghostex-help ghostex-manage-beads
ghostex-visuals paperclip`) — those 9 skills *are* in the repo, just not where the overlay
looks; `gen-pi-agents` exits `ERROR: missing /tmp/cold4/.agents/AGENTS.md` so
`~/.pi/agent/AGENTS.md` is never generated (rules absent from the agent); every
repo-tracked skill fix is invisible on the new machine. With `~/.agents` and `~/AGENTS.md`
symlinked (sandbox 2) the same command wrote `~/.pi/agent/AGENTS.md` (5172 B, 42 rules) —
so the symlink fleet is the whole difference.

### 3. Both jcode hook installs fail on a fresh machine — no `mkdir -p` for `~/.jcode/hooks/`
`jcode/update-all.sh:727-729` (`for hook …; install_if_different "$hook" "$HOME/.jcode/hooks/…"`)
vs `:736` which does `mkdir -p "$HOME/.jcode/bin"` for the sibling step.
Evidence (sync_configs run directly against a clean HOME): two `ERROR: install …/hooks/
babysitter-gate.sh -> … exited 1` and the same for `herdr-agent-state.sh`; `cp` cannot
create the file, and `install_if_different` never creates the destination dir.
Symptom: on a fresh machine `turn_end_gate` — the header calls it the *sole*
continuation-decision hook — and the agent-state hook are simply absent; the agent runs
with no turn-end behavior and no error beyond one red checklist line.

### 4. PyYAML is assumed present from the user site dir, with no check
`jcode/skills-cap-check.py:23` (`import yaml`, hard import), `jcode/skills-cap.py:91`
(soft import, degrades).
Proof: `HOME=/home/prm python3 -c "import yaml"` → `/home/prm/.local/lib/python3.14/site-packages/yaml/__init__.py`;
`HOME=/tmp/cold4 …` → `ModuleNotFoundError: No module named 'yaml'`.
Symptom: `skills-cap: PyYAML missing, cannot parse frontmatter safely` +
traceback, `ERROR: skill catalogue cap failed` — a skills-phase failure that (finding 1)
also blocks configs. Nothing in the repo installs or declares PyYAML.

### 5. The pi patch step assumes pi lives in the npm-global prefix, and no probe exists
`jcode/apply-pi-patches.sh:28` (`PI_ROOT="${PI_ROOT:-$HOME/.npm-global/lib/node_modules/…}"`),
fail at `:45`.
Symptom: `apply-pi-patches: ERROR: no pi install at … (set PI_ROOT to override)` on any
machine where pi came from nvm/pnpm/`/usr/local`/distro — i.e. most machines. It is a hard
phase failure, so with finding 1 it takes the configs down with it. `PI_ROOT` is the only
escape and is undocumented in the run output a user sees.

### 6. `$HOME/dotfiles` is hardcoded; the correct repo location is only a convention
`jcode/update-all.sh:73` (`DOTFILES="$HOME/dotfiles"`); every config path, `PATCH_DIR`
(`apply-pi-patches.sh:29`), and the ledger stem from it.
Symptom: clone to `~/src/dotfiles` (or any other path) and the config phase logs
`skip: no dotfiles repo at $DOTFILES` at `:692` and **returns 0** — a green-looking run
that installed nothing. No check, no derivation from `BASH_SOURCE`, no error.

### 7. A tracked `.pyc` makes the dotfiles tree permanently dirty, so pull/push never runs
15 tracked `__pycache__/*.pyc` files (e.g. `jcode/__pycache__/skill_slash.cpython-314.pyc`),
no `.gitignore` entry; the guard is `dotfiles_user_edits` at `jcode/update-all.sh:675`.
Evidence: after one sync the pristine sandbox clone showed exactly
` M jcode/__pycache__/skill_slash.cpython-314.pyc` and the config phase logged
`PRESERVED: dirty dotfiles; skip pull/staging/commit/push`.
Symptom: the new machine never pulls upstream dotfiles changes and never pushes, and says
so only as `PRESERVED:`/`WARN: skipping dotfiles push` — a sync that is silently one-way
and stale from the first run.

### 8. `--config-only` does not turn off the pi phases, so the repair command for a failed cold run fails for the same reasons
`jcode/update-all.sh:92` (`--config-only) DO_JCODE=0; DO_SKILLS=0; DO_TOOLS=0; DO_MANIFEST=0 ;;`
— `DO_PI`/`DO_PATCHES` untouched). Verified: `--config-only` on the cold sandbox ran
`pi rules file` and `pi patches`, both failed, so `:960` skipped configs anyway. Same for
`--jcode-only` and `--skills-only`.
Symptom: the one-flag recovery path the header offers cannot repair a cold machine; you
must `source` the script and call `sync_configs` (that is how finding 3 was found).

### 9. The committed script swallows `skills-activation` failures; the fix is uncommitted
Committed `jcode/update-all.sh:500`: `python3 … skills-activation.py 2>&1 | tee -a "$LOG" || rc=1`
— the pipeline's status is `tee`'s, so a transform refusing to write still counts as done.
The live working tree already fixes this with `PIPESTATUS[0]` but that hunk is not in the
commit a new machine clones (`git diff` between live file and clone: exactly this hunk).
Symptom: on a fresh machine a bad activation rewrite passes as `done` and `--config-only`
style checks stay green; only the live machine is protected.

### 10. Installed configs carry `/home/prm` absolute paths
`jcode/.jcode/config.toml:239` (`dir = "/home/prm/dotfiles/nvim/.config/nvim"` — this file
*is* installed by the sync), `herdr/.config/herdr/config.toml:59,71`
(`command = "/home/prm/.config/herdr/bin/sessionizer"`, `…/herdr-theme`).
Symptom: on any machine whose user is not `prm`, the `cmd+;` launch hotkey opens nothing,
and herdr keybindings invoke nonexistent absolute paths — silent, no error. The generated
`~/.pi/agent/AGENTS.md` also carries `/home/prm/...` references, so an agent on the new
machine is told to read paths it will never find.

### Not counted (checked, held up)
`flock`, `cargo`, `npm`, `mise`, `node`, `go`, `git`, `sha256sum` are all probed with
`command -v` before use (`:934`, `:206`, `:593-615`, `apply-pi-patches.sh:47-48`); the
lock, log retention, `GIT_TERMINAL_PROMPT=0`, atomic writes and the `--dry-run` no-state
rule behaved correctly cold. `mise use -g` and `go install` both stayed inside `$HOME`.

## Prerequisites for a fresh machine, in the order a person runs them

1. `git`, `bash`, `python3` (3.10+), `flock`, `sha256sum` — the only ones that fail loudly
   and early. `cargo` is required by the core phase (`:206`) but is not needed if you skip
   core.
2. `python3 -m pip install --user pyyaml` — finding 4; the run does not do it.
3. Install **jcode** (its own installer), then `jcode self-dev --setup` to create
   `~/.jcode/source/jcode`; without it the core phase and therefore the config phase fail
   (finding 1). Needs a git credential for the `PremModhaOfficial/jcode` fork push.
4. `git clone <dotfiles> ~/dotfiles` — the path is not optional (finding 6).
5. Create the symlink fleet by hand, because nothing does it (finding 2):
   `~/.agents -> dotfiles/agents/.agents`, `~/AGENTS.md -> dotfiles/agents/AGENTS.md`,
   `~/skills -> dotfiles/agents/.agents/skills`,
   `~/.skill-lock.json -> dotfiles/agents/.agents/.skill-lock.json`,
   `~/.jcode/bin/update-all.sh -> ~/dotfiles/jcode/update-all.sh`.
6. Install **pi** with npm in the default global prefix (or export `PI_ROOT`), then
   `~/.pi/agent` exists and `~/.pi/agent/AGENTS.md` can be written (finding 5).
7. `mkdir -p ~/.jcode/hooks` — finding 3; the sync writes into it but never creates it.
8. `mkdir -p ~/.pi/agent/skills ~/.commandcode/skills ~/.a5c/processes` if you want the
   overlays and host skills to land instead of `OVERLAY-WARN` (findings 2).
9. `npm`, `node`, `mise`, `go`, `curl` for the tools phase (network: 5 GitHub clones,
   `mise install herdr`, `npm exec babysitter`, `go install gopls`, caveman installer).
10. Then `bash ~/dotfiles/jcode/update-all.sh`. Expect exit 1 until findings 1/3/4 are
    fixed; check `~/.jcode/state/update-all/CHECKLIST.md` for the `skip configs/manifest`
    line, which is the one that means nothing was installed.
11. Manually link the app configs the sync does not touch (nvim, ghostty, herdr config,
    fish, niri, …) — and fix the `/home/prm` paths in the two it does install (finding 10).

## Evidence trail

```
/tmp/cold4/logs/coldA.out                                  full cold run, exit=1
/tmp/cold4/.jcode/state/update-all/CHECKLIST.md            73/82 ok, 8 fail, 1 skip
/tmp/cold4/.jcode/logs/update-all-*/jobs.*/*.output         per-phase output quoted above
/tmp/cold4/logs/direct.log                                 sync_configs run in isolation (finding 3)
/tmp/cold6/.pi/agent/AGENTS.md                             5172 B / 42 rules, symlinks present
```
