# IT3 blind antagonist review (round 3)

Read order: own checks first (overlays, transform, gates, layout), then `it3-1.md`,
then `it3-2.md`. Nothing edited; the only file I touched was the `__pycache__` my
own `rust-skills/checks/check.sh` run created, which I removed. No real
`update-all.sh --skills-only` re-run: it mutates the tree; ordering was verified in
code (`dotfiles/jcode/update-all.sh:913`) and behaviour in a fake `$HOME`.

## IT3-1 — CONFIRMED (nine fixes present; three sub-claims refuted)

Re-ran, all true:

- **herdr-theme is a copy**: `stat -c '%i %h' ~/.config/herdr/bin/herdr-theme` →
  inode 1636780, links=1; dotfiles inode 2925354; `cmp -s` SAME; the step is
  `install_if_different` at `dotfiles/jcode/update-all.sh:749-758`. Claims TRUE.
- **`~/.jcode/config.toml` is a preserved copy**: `cmp` DIFF, `[cloud]` line 1,
  `[session]` line 4; `install_live_jcode_config` at `update-all.sh:650-659` logs
  `PRESERVED`. TRUE.
- **flow is not synced**: `update-all.sh --dry-run` rc=0, `grep -c 'DRY: sync'`=34,
  `grep -c flow`=0; ledger 35 unique names, `grep -x flow` exit 1; both `flow` paths
  are git-tracked and `readlink -f` identical. TRUE.
- **fish is three links**: `namei -l ~/.config/fish/config.fish` shows three hops,
  two root-owned; `dotfiles/nix/modules/shell.nix:4` is the `mkOutOfStoreSymlink`.
  TRUE.
- **deepwiki**: `.pi/agent/mcp.json:7` `toolExposure`; `read_wiki_structure`/
  `read_wiki_contents` `hidden`; this session's only callable one is
  `mcp__deepwiki__ask_wiki_question`; the one-liner prints the dict. TRUE.
- **hc forms**: `hc wait --help` → default 180; `hc run --bg` + `hc wait` printed
  `{"ended":true,"exit_code":0,…}`; `hc list` → `unrecognized subcommand`; `hc
  read/get/ls` exist; `timeout 6 tail -q -f --pid=$P` returned rc=0. TRUE.
- **Gates**: gen-pi-agents md5 `22544a4f03f39dc533fccc79e225deb2` unchanged on the
  second run (5172 B); `flow/scripts/check.sh` OK; rust check 265 rules / 823
  examples OK; `AUDIT-TOTAL: 0`; cap-check 145 descriptions / 270 B. The fragment and
  reference diffs only rewrite lines; no rule was deleted.

Refuted points:

1. **F1's source citations are stale and do not point at the code.**
   `memory-harness-home.md:54` cites `update-all.sh:683-692` (actual 749-758),
   `:55` cites `:663-680` (actual 735-744), `:56` cites `:584-593` (actual 650-659).
   Cause: `update-all.sh` mtime 18:44 (+70/-3, `git -C dotfiles diff --numstat`),
   the memory file 18:18. The report's proof `grep -n herdr/bin/herdr-theme` now
   returns 749/751, not 683/685.
2. **F7's "the reason the ban does not cover it" is unsupported.**
   `grep -x flow` on `upstream-sources` proves flow is unsynced, not that
   `/home/prm/AGENTS.md:29` permits the write. `flow/SKILL.md:80` and
   `memory-harness-home.md:101-103` redefine the ban as "the 34 synced dirs", but the
   authority file still says "Never edit `/home/prm/.agents/skills/`" and "Skill
   fixes go to `/home/prm/dotfiles/skills-overlay/`". Both paths are the same inode
   (`readlink -f`), so the write target moved in spelling only; the contradiction
   survives.
3. **F4 cites `AGENTS.md:63`; the command line is `:64`.**

Also wrong-but-acknowledged: `gen-pi-agents.py:6` still says "the six pi tool-form
imperatives".

Unverified-but-checkable: `memory-code-lookup.md:24` says a `mcp.json` edit needs "a
restart: unverified". `dist/extensions/mcp/index.js` header states the servers are
connected "when a session starts" and no watcher exists, so a hand edit needs a
restart. `nvim` is likewise checkable and true (`namei -l`, `readlink -f` →
`dotfiles/nvim/.config/nvim`), not an unknown.

## IT3-2 — REFUTED (point 6 corrupts a live card; points 1-5 hold)

Re-ran, true:

1. **caveman-help**: `SKILL.md:41` is `## Choosing the mode`; `rg -a
   CAVEMAN_DEFAULT_MODE ~/.npm-global/lib/node_modules/@caveman-ai/cli` rc=1;
   `~/.config/caveman/config.json` missing; `rg -c caveman ~/.claude/settings.json`
   = 0; no caveman plugin under `~/.config/opencode`. TRUE. But the twin false claim
   is at `ponytail-help/SKILL.md:51,55` (report says `:53,58`).
2. **oc**: `oc sites` = 24; the `Sites:` line lists exactly those 24 (my extra token
   was `open` from the same line); the pre-fix line had 29. TRUE.
3. **deepwiki tool name**: `feature-compare/SKILL.md:18`;
   `rg -c 'mcp__DeepWiki__|ToolSearch'` rc=1. TRUE.
4. **Overlay class**: 20/20 with the anchor removed → rc=3, no marker (paperclip
   retested with the pre-existing marker deleted); 20/20 on the installed tree →
   rc=0 + marker; pre-patch fixtures → rc=0, marker, NEW text present, file changed
   (incl. megacave/ultracave from fresh upstream, paperclip); drift → rc=2, no marker
   for `caveman-help`, `tiger-style-review`, `megacave`; missing `SKILL.md` → rc=3;
   the `cua-driver`/`paperclip` guard refusals → rc=3. No overlay reached the marker
   with the expected patch absent. Class CONFIRMED.
5. **brag locations**: the four `~/.claude/skills/...` files exist; `format.md`,
   `motion.md`, `look.md`, `story.md`, `types/` do not. TRUE, but the proof is
   vacuous — `reference/types/\*` (singular) matches nothing while the card contains
   `references/types/*`; `references/look.md` is absent because the card says
   `look.md`. And `brag/SKILL.md:114` says `references/` "holds" five files; it holds
   16 entries.

6. **Slash transform — REFUTED.**

   - `dotfiles/jcode/skill_slash.py:27` allows `.` after the name and anything except
     `\w / . : ~ $ -` before the slash.
   - Live damage in the committed card: `brag/SKILL.md:130,132` now read
     `<output-dir>/skill:brag.mp4` and `<output-dir>/skill:brag.jpg` (git diff shows
     `brag.mp4` → `skill:brag.mp4`). Step 4's gate therefore names a file that cannot
     exist.
   - Reproduce: `normalize('<output-dir>/brag.mp4')` →
     `'<output-dir>/skill:brag.mp4'`.
   - The claimed-safe forms are safe: `/tmp`, `/clear`, URLs, `./x`, `/tmp/brag` all
     stay. The class is the miss.
   - Wipe/sync: fake `$HOME`, upstream card copied in → 4 rewrites, 0 bare; wiped and
     re-copied → same; the `~/.pi` symlink copy is updated through the link; an
     unwritable card → exit 1. No family missed: 145 files, 137 names, all 34
     `~/.pi/agent/skills` symlinks share their target basenames, 0 bare left, and the
     coarse grep's 7 files are only `/tmp`, `/clear`, `/login`, `/auto`, `/plugin`,
     `/reload-plugins`, `/plan-review`, `/compact`. Mutation is the problem, not
     coverage.

Refuted points: 6 (a path is rewritten, contrary to "paths untouched"), 5's proof
command, 1's ponytail-help line numbers.

## Cross-ticket

- IT3-1 wrote `update-all.sh` line numbers at 18:18; IT3-2's +70/-3 edit at 18:44
  invalidated them in the durable memory file. The two reports' citations cannot both
  be true, and the delivered file is the wrong one.
- IT3-1 §4: "`update-all.sh` — no defect in the code"; IT3-2 fixed two real ones in
  the same pipeline (cap `SLASH` regex, activation-before-cap ordering).

## Worst problem

The transform corrupts paths: `<output-dir>/brag.mp4` became
`<output-dir>/skill:brag.mp4` in the live card, so brag's Step 4 gate can never find
its render. It recurs on every sync for any `<dir>/<skill-name>.<ext>`, and
`skills-audit` still reports 0.
