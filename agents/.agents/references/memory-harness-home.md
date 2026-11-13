# Harness-agnostic home: pointer forms (detail)

Cheapest first:

- An import line where supported: `@~/.agents/AGENTS.md`.
- Where the harness reads one fixed filename instead, symlink it.
- An inline repeat, only where the harness has no import and a pointer would be
  inert.

Why: one edit under `~/.agents` must reach every harness; content copied into a
harness dir drifts silently.

# This machine's layout (lookup, not rules)

Pointed at from `/home/prm/AGENTS.md`; keep the rules there and the enumeration here.

## Resolve before you edit — the rule that survives any depth

Do not infer from "stow-style" or from how the layout was designed. Depth is not fixed
on this machine: `~/.config/fish` resolves through **three** links, one of them
root-owned in the nix store. Run this on the exact path you are about to write:

```bash
readlink -f <live-path>   # the final target, every hop resolved
namei -l <live-path>      # each hop, with owner; shows where a write actually lands
ls -l <live-path>         # `-> ...` = link; a plain `-rw-`/`-rwx...` = a copy
```

- **Link** — the write lands at the resolved target and is live immediately. Confirm
  with `readlink -f`, not with the number of arrows you expect.
- **Copy** — the write lands in *that file only*. Some step must copy it again
  (`update-all.sh`), or the user's command keeps running the old bytes.
- **Generated** — neither. `update-all.sh` rebuilds it from other sources, so a hand
  edit is overwritten. The generator's name is in the first line of the file or in the
  script.

Then prove a fix where the user runs it, not where the source lives:

```bash
cmp -s <live-path> <repo-path> && echo SAME || echo DIFF   # copy: DIFF means not installed yet
```

A green run at the repo path proves nothing about the user's command when the live path
is a copy. That near-miss is why this section exists.

## Per path: link, copy, or generated

| live path | kind | reason |
| --- | --- | --- |
| `/home/prm/.agents` | symlink → `dotfiles/agents/.agents` | made by hand (`ln -s`); the canonical home has one location |
| `~/.config/fish` | 3 links: → `/nix/store/…-home-manager-files/.config/fish` → `/nix/store/…-hm_fish` (both root-owned) → `dotfiles/fish/.config/fish` | home-manager `mkOutOfStoreSymlink` (`dotfiles/nix/modules/shell.nix:4`); the store links are not yours to write, the final file is |
| `~/.config/nvim` | same shape | `dotfiles/nix/modules/editor.nix:8` |
| `~/.config/herdr/config.toml` | symlink → `../../dotfiles/herdr/.config/herdr/config.toml` | linked by hand; the only herdr file that is |
| `~/.config/herdr/plugins/`, `bin/herdr-theme`, `themes/*.toml` | **dir and copies, not links** | `plugins/` is a real dir that herdr and hand installs fill; **no updater step syncs it** — the repo copy at `dotfiles/herdr/.config/herdr/plugins/` is partial (measured 2026-11-13: live has 9 `config/` plugins, the repo has `pickr`; the repo's `local/herdr-sesh` is absent live). `bin/` and `themes/` are written by `install_if_different` in `update-all.sh`, on its `"$DOTFILES/herdr/bin/herdr-theme"` and `"$DOTFILES/herdr/themes"` lines |
| `~/.jcode/bin/jcode-theme`, `~/.jcode/themes/*.toml`, `~/.jcode/hooks/*.sh` | **copy** | the same `install_if_different` block, `"$DOTFILES/jcode/bin/jcode-theme"` |
| `~/.jcode/config.toml` | **copy, preserved when it differs — it differs today** | `install_live_jcode_config` in `update-all.sh` (logs `PRESERVED: live jcode config differs`): a local runtime edit wins over the repo. Measured 2026-11-13: `cmp` says DIFF, the live file has `[cloud]`/`[session]` keys the repo lacks. A dotfiles edit here may never reach the live file — compare before claiming it did |
| `~/.a5c/processes/` | **copy** | `cp -R` in `update-all.sh` |
| `~/.pi/agent/AGENTS.md` | **generated** | `gen-pi-agents.py` from `~/.agents/AGENTS.md` + `dotfiles/jcode/pi-agents.fragment.md`. Hand edits are overwritten: edit the fragment, then regenerate |
| `~/.pi/agent/skills/<name>` | one symlink **per entry** → `../../../.agents/skills/<name>` | the dir itself is real; all 34 entries are links |
| `~/.commandcode/skills/<name>` | **mixed**: 83 symlinks, 117 real dirs | cmd installs its own; only the links follow `~/.agents` |
| `/home/prm/.jcode` | upstream-managed fork | read-only except through its updater |

Cite the function and one string it contains, never a line number: `update-all.sh` grows
(991 lines today, 683 when that citation was written), so every pinned range rots and a
reader who follows it lands somewhere else. Counts were measured on 2026-11-13 —
treat them as evidence, not constants. Re-run the commands above; they outrank this table.

## `/home/prm/.agents/skills/` — which skills the updater actually writes

`update-all.sh` does not regenerate the tree. It writes two things:

1. `sync_dir` — 34 calls copying skill dirs out of 5 cloned upstreams
   (`~/.jcode/updater-src/{ponytail,caveman,tiger-style,herdr,babysitter}`), plus
   `babysit`, which is regenerated from a template. `caveman` is enumerated from its
   registry, so the count moves between releases. The full set today is
   `cut -f1 ~/.jcode/state/upstream-sources` (35 names = these 34 + `babysit`).
2. `apply_skill_cap` — rewrites **every** `SKILL.md` description under
   `~/.agents/skills` (synced or not) down to 270 B.

Everything else — `flow`, `ds-*`, `rust-skills`, the EGM bundle — is a plain
git-tracked file of the dotfiles repo at `dotfiles/agents/.agents/skills/`. No sync
writes it, so no overlay is needed and there is no `skills-overlay/flow.sh`.

The check that decides, for any skill name:

```bash
cut -f1 ~/.jcode/state/upstream-sources | grep -qx <skill>
# exit 0 → the sync owns this dir: fix it in dotfiles/skills-overlay/<skill>.sh
# exit 1 → the dir is its own source: edit dotfiles/agents/.agents/skills/<skill>/ + commit
```

`~/.jcode/state/upstream-sources` is written by `stamp_source` at sync time and never
pruned: a name present is authoritative for "the updater writes this dir", and a name
absent is authoritative for "it does not".

The rule that follows: a fix written into a synced skill disappears at the next sync,
and a fix written into an overlay for an unsynced skill is a second copy that drifts
from the one file that runs. For `flow` and every other local skill the dotfiles file
*is* the running file — write it there and commit. Only names in `upstream-sources`
get a `<skill>.sh` overlay.

Where this meets the ban on editing `/home/prm/.agents/skills/`: the bullet
`Which skills are editable, stated once here` in `/home/prm/AGENTS.md` states the whole
rule — synced dirs change through an overlay, every other skill through its dotfiles path,
ledger and app state never. It is not restated here; edit it there if the split changes.

Still app-managed — do not edit:

- `/home/prm/.agents/LEDGER.md` — only the loop router writes it.
- `/home/prm/.pi/agent/npm`, `/home/prm/.pi/agent/git`, `/home/prm/.pi/agent/sessions`,
  `/home/prm/.commandcode/sessions`, `/home/prm/.commandcode/projects`,
  `/home/prm/.commandcode/history.jsonl` — app state, rewritten by pi and cmd.
- `/home/prm/.jcode` — only via its updater.
