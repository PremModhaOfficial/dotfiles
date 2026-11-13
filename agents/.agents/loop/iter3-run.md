# Iteration 3 — lens: run the rules for real

Method: three ordinary jobs, done end to end, obeying `~/.pi/agent/AGENTS.md` (the loaded
inline copy of `~/.agents/AGENTS.md`) plus `~/.agents/references/*` and the `flow` skill,
exactly as written. Nothing edited in any rule file. Everything changed was reverted and
byte-checked. Previous rounds' reports were not read.

Blind: I did not ask what earlier rounds fixed; every defect below is from this run only.

---

## Job 1 — find where a config value is set, change it, revert

Target: `EDITOR`.

| Step | Rule said | What happened |
| --- | --- | --- |
| Locate | AGENTS.md:33 "If `graft` exists, use it for local code; otherwise grep and read" + memory-code-lookup.md:3 "check it is on PATH" | `which graft` absent, as `/home/prm/AGENTS.md:41` said. Fell back to grep. |
| grep | "grep and read" | `rg 'EDITOR' dotfiles/fish dotfiles/nix` → **empty**. Dotfiles is almost entirely `.config/`, and `rg` skips hidden dirs by default. Empty read looked like "not set here". Recovered only with `--hidden` / `-uu`. **Defect D7.** |
| confirm live | memory-harness-home.md:20-21 "live paths are symlinks into it" | `ls -ld ~/.config/fish` → `/nix/store/4d3…-home-manager-files/.config/fish` (home-manager `mkOutOfStoreSymlink`, two hops). Needed `realpath` + `md5sum` before trusting the edit target. **Defect D8.** |
| change | — | `set EDITOR nvim` → `vim` in `dotfiles/fish/.config/fish/config.fish:50`; live path showed the change immediately (`fish -c` printed `EDITOR=vim`). |
| revert | — | Back to `nvim`; md5 back to `c5a070678cfb583bf8c334e20bb68820`. Clean. |

Cost in this job: 2 wasted greps, 3 confirmation commands, 1 wrong first conclusion
("EDITOR is not in dotfiles").

---

## Job 2 — add a small function and prove it

Target: `dotfiles/herdr/bin/herdr-theme` (bash, 4.4 kB, already has a helper per command).

| Step | Rule said | What happened |
| --- | --- | --- |
| gate | AGENTS.md:8 "Score each prompt 0-10 before starting" | This prompt scored ~4 on "which three jobs / what counts as a defect". Asking is forbidden (that is taste, memory-clarify.md:14) and not asking is forbidden (>3, do not start). I proceeded on the narrowed reading. **Defect D10.** |
| order | AGENTS.md order-of-operations → `flow` for real repo work | Read `flow/SKILL.md`. Line 12 sends you to memory-clarify; line 14's escape hatch (one file, small edit → skip Plan) applied. |
| build skill | flow:22 "`lean-build` feature" | 18 lines, cheap, no waste. Worked as intended. |
| prove (dotfiles copy) | lean-build:18 "run focused proof" | `herdr-theme count` → `3`, matching `ls themes/*.toml | wc -l`. |
| prove (live command) | memory-harness-home.md:20-21 "dotfiles is source of truth, live paths are symlinks into it" | `~/.config/herdr/bin/herdr-theme count` → `error: no theme 'count'`. The live file is a **copy**, not a symlink (`cmp` differs); it is refreshed only by `update-all.sh:683-686 install_if_different`. Had I run only the dotfiles copy I would have reported a green that the user's command does not have. **Defect D9.** |
| revert | — | Function and case removed; `git -C dotfiles diff herdr/bin/herdr-theme` empty. |

---

## Job 3 — diagnose a failing command

Two real failures.

(a) A rule's own command fails. memory-code-lookup.md:14 says use deepwiki
`read_wiki_structure` first. `tools.mcp__deepwiki__read_wiki_structure` → *does not exist*.
Root cause confirmed in `/home/prm/.pi/agent/mcp.json`: that server exposes
`ask_wiki_question: direct`, and `read_wiki_contents` / `read_wiki_structure: hidden`.
Recovery needed a second call (`searchTools`). **Defect D2.**

(b) The wait for a background job has no legal form. Following
`/home/prm/.pi/agent/AGENTS.md:26` I launched
`nohup bash ~/.jcode/bin/update-all.sh --dry-run > /tmp/it3-ua.log 2>&1 &` (pid 784992).
`hc wait` needs an hc terminal name, which a nohup shell job does not have; the remaining
option in memory-never-block.md:11 is "a background log plus a peek", and the peek is
exactly the poll loop that :14-15 forbids. I improvised one `sleep 3; ps -p; tail`.
**Defect D3.** Reading `hc wait --help` then showed the default cap is 180 s
(`--timeout`), not the 600 s `bash-guard` bound the rule quotes. **Defect D4.**

Also verified while there: `gen-pi-agents.py` regenerated to /tmp is **identical** to
`~/.pi/agent/AGENTS.md` (no drift), and `update-all.sh --dry-run` (69 lines, ~2 s) touches
**no** `flow` skill — only five vendored ones. That becomes D6.

---

## Defects, ranked by time wasted

1. **memory-harness-home.md:21** — told me: "dotfiles is source of truth (stow-style: live
   paths are symlinks into it)". Machine: `~/.config/herdr/bin/herdr-theme` is a plain copy
   (`cmp` differs; `update-all.sh:683-686` copies it). Cost: one failed prove run at the
   live path, plus `cmp` and a grep of `update-all.sh` (3 commands), and the near-miss of
   reporting a fix as proven when the user's command still fails. A claim that is true for
   nix-managed configs (fish) and false for the bin scripts written by the same updater.

2. **memory-harness-home.md:34-37** — told me: "`/home/prm/.agents/skills/` — regenerated by
   `update-all.sh`; fixes go in `<skill>.sh` under `skills-overlay/`". Machine:
   `updater-src/` holds five vendors (babysitter, caveman, herdr, ponytail, tiger-style);
   the dry-run log contains zero occurrences of `flow`; `skills-overlay/` has no `flow.sh`.
   `flow`, `ds-*` and the rest are plain files in the dotfiles repo. Cost: an overlay script
   that would never run, i.e. a silently dropped fix, plus the evidence hunt (3 commands:
   dry-run log grep, `ls updater-src`, `ls skills-overlay`).

3. **memory-never-block.md:8-11 + pi AGENTS.md:26** — told me: wait with `hc wait <name>`,
   else "a background log plus a peek". Machine: `hc wait` requires a *terminal*; a `nohup`
   shell job has none, so the only listed alternative is a peek, and peeking a still-running
   job is the poll loop the same file forbids (:14-15). A nohup job also emits no event, so
   "end the turn, the next message is the signal" loses the result. Cost: forced
   improvisation (`sleep 3; ps -p 784992`) on a 2 s job; on a 10 min job there is no legal
   move at all.

4. **pi AGENTS.md:63 (aggregation of AGENTS.md:58)** — told me: "Check on it rather than
   assuming: its output, its recent lines, its session log". Machine: no command form given
   for an `hc` agent; I guessed `hc list` → `usage: unrecognized subcommand 'list'`,
   `hc --help` (40 lines) to find `hc ls`, whose output is raw JSON needing `jq`. The only
   peek form in the references (`tail -n 20 <log>`) covers nohup jobs, not agents. Cost: one
   wasted command, one help dump, one re-read of output.

5. **memory-harness-home.md:20-21** — told me: live paths are symlinks into dotfiles.
   Machine: `~/.config/fish` → `/nix/store/…-home-manager-files/.config/fish` (a two-hop
   `mkOutOfStoreSymlink` chain; the file inside is the dotfiles file). Cost: `test -w`,
   `realpath`, `md5sum` (3 commands) before I trusted the edit target, and a moment of
   believing the value lived in the nix store.

6. **flow/SKILL.md:65-69 vs /home/prm/AGENTS.md:29** — told me: "append one line to the rules
   file" (`~/.agents/skills/flow/rules.md`) and: "Never edit `/home/prm/.agents/skills/`".
   The first path *is* the second path. Cost: the documented lesson exit is unreachable as
   written; a compliant agent either breaks the HARD rule or stalls. (The dotfiles copy is
   the legal target, but neither file says so; only a memory lookup tells you.)

7. **pi AGENTS.md:33 / AGENTS.md:28** — told me: "otherwise grep and read". Machine: this
   machine's dotfiles are all `.config/…`, so plain `rg` returns nothing and reads as
   "absent". Cost: 2 wasted greps and one wrong conclusion; recovery required knowing `-uu`.

8. **memory-code-lookup.md:14** — told me: use deepwiki `read_wiki_structure` first.
   Machine: that tool is marked `"hidden"` in `/home/prm/.pi/agent/mcp.json` and the call
   throws. The file's warning at :3-4 covers a missing `graft` binary, not a hidden MCP tool.
   Cost: 1 failed tool call + 1 `searchTools` recovery call.

9. **memory-never-block.md:9-12** — told me: `hc wait` is bounded by the 600 s `bash` cap.
   Machine: `hc wait --help` → `--timeout … default: config wait_timeout, else 180`, and it
   "checks in, leaving it running". A 180 s return looks identical to "the agent stopped".
   Cost: one wrong report or one extra wait per long delegation; the only stated number is
   the wrong one.

10. **pi AGENTS.md:49 (AGENTS.md:44)** — told me: "Never print or return raw tool output;
    return only the extracted fields". Machine: in Locate you cannot name fields for output
    you have not seen yet, so the first batched call printed lines I then had to re-grep to
    read again. Cost: 1 duplicate command per locate round; the rule is right for reports,
    wrong for discovery, and does not say which.

11. **memory-harness-home.md:10-11 + flow/SKILL.md:86** — told me: "content copied into a
    harness dir drifts silently" and offered `check.sh` as the self-check. Machine:
    `check.sh` validates the rules file only; `gen-pi-agents.py --check` does not exist
    (`unrecognized arguments: --check`). The only drift test is regenerate to /tmp and diff.
    Cost: 1 failed flag + 1 regen + 1 diff; the drift risk the file warns about has no check.

12. **memory-clarify.md:8-16** — told me: score every prompt, do not start above 3, never ask
    about preferences. Machine: a task like "pick three ordinary jobs" is ambiguous only in a
    preference (which three), so the rule forbids both starting and asking. Cost: one turn if
    obeyed literally; a "any reasonable choice satisfies the ask → act" exit is missing.

Non-defects checked and left alone: `flow`'s escape hatch and its skill sizes (18/16 lines —
cheap, they earned their load); `update-all.sh --dry-run` (2 s, ran as documented);
`oc open` (works, compact as advertised); `bash-guard` 600 s (confirmed in
`extensions/bash-guard.ts:21`); regeneration of `~/.pi/agent/AGENTS.md` (identical, no drift).

## Reverts

- `dotfiles/fish/.config/fish/config.fish` — `EDITOR vim` → `nvim`, md5 back to pre-run value.
- `dotfiles/herdr/bin/herdr-theme` — added `count_themes` + `count` case removed;
  `git diff` empty.
- `/tmp/it3-pi-agents.md`, `/tmp/it3-ua.log` — deleted. No other file touched.
