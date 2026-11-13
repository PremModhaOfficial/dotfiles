# FIX-1 rev1 — antagonist review

**REFUTED as a fix.** Every number reproduces (`python3 ~/.agents/loop/fix1-count.py` → `catalog 1458 / PASS`, exit 0), but the claim's causal story is false: 88% of the cut is invisibility, not rewriting; pi has no catalog cap to fix; and the mechanism defeats the stated goal.

Measured from the pre-change tree (`tar xzf ~/.agents/loop/fix1-backup-skills.tar.gz -C /tmp/fix1-before`), with the two symlinked skills taken from `fix1-symlink-originals/`:

```
BEFORE: skills=133 catalog=99 manual=34 catwords=3937 over60=17
AFTER : skills=132 catalog=41 manual=91 catwords=1458 over60=0
total catalog drop        2479 words
  rewrite savings, in catalog   274 words  (11%)   <- 10 of the 17 rewritten skills were also hidden
  drop from newly/ already hidden 2172 words  (88%)
```

The report's "there was no other lever" is arithmetic about its own metric: the metric counts only visible descriptions, so hiding is unbounded and rewriting is capped. 274 of 2479 is not a rewrite fix.

---

## 1. HIDING AS THE LEVER — 19 hidden skills are still referenced by files the model can read

Hidden = `disable-model-invocation: true`. In pi this removes name, description **and** location from the prompt (`dist/core/skills.js:272-279`), so the model cannot resolve the name to a path except by guessing the `~/.agents/skills/<name>/SKILL.md` convention.

| hidden skill | referenced from (catalog-visible file) | quoted reference |
|---|---|---|
| ds-mode | `ds-help/SKILL.md:14` | `| Any coding session (always on) | ds-mode |` — the always-on recommendation |
| ds-mode | `ds-help/SKILL.md:43` | `If no skill fits, say so and work with ds-mode alone.` |
| ds-sharpen | `ds-help:15` | `| Vague or high stakes | ds-sharpen, then ds-plan-loop |` |
| ds-context-reset | `ds-help:21`, `ds-plan-loop:14`, `ds-unstick:20` | `| A long run or a full context | ds-context-reset, ds-ledger |` |
| ds-ledger | `ds-help:21`, `ds-blueprint:16` | `record the choice with /ds-ledger instead` |
| ds-best-of-n | `ds-help:22`, `ds-blueprint:13` | `| A hard artifact where one try may miss | ds-best-of-n |` |
| ds-swarm | `ds-help:23` | `| Wide coverage, audits or races | ds-swarm |` |
| ds-design | `ds-help:26` | `| A new UI | ds-design |` |
| ds-design-audit | `ds-help:27` | `| A UI that looks generic | ds-design-audit |` |
| ds-pr | `ds-help:28`, `ds-adopt:18`, `ds-ship:16` | `| Opening a PR | ds-pr |` |
| ds-watch-pr | `ds-help:29`, `ds-adopt:18`, `ds-ship:17` | `| Watching CI and bots | ds-watch-pr |` |
| ds-explain | `ds-help:34`, `ds-blueprint:12` | `| Understanding code | ds-explain |` |
| ds-catchup | `ds-help:35` | `| Coming back after a long run | ds-catchup |` |
| ds-unslop | `ds-help:37` | `| Writing prose or docs | ds-unslop |` |
| ds-principles | `ds-help:38` | `| Rules of thumb | ds-principles |` |
| ultracave, megacave | `caveman/SKILL.md:19` | ``/caveman ultra` and `/caveman wenyan` are aliases: follow the `ultracave` or `megacave` skill instead of this one.`` |
| driving-t3-previews, linking-t3-prs | `t3-code/SKILL.md:37` | ``Preview: `driving-t3-previews`. PR: `linking-t3-prs`.`` |
| setup-matt-pocock-skills | `code-review/SKILL.md:13` | ``tell the user to run `/setup-matt-pocock-skills` `` |

`ds-help` is the routing table for the whole ds-* pack and stays auto-invocable; a model that reads it and follows line 14 is told to use a skill whose existence was deleted from its context. `caveman` is an active voice mode and now points at two skills it cannot see.

Also an always-on mode itself: `tiger-style` ("Safety-first coding mode", `tiger-style/SKILL.md:3`) is now hidden — `tiger-style/SKILL.md:5` `disable-model-invocation: true`. Saying "tiger style" routes nowhere.

The report's own reachability section concedes 15 (actually 14: it counts bare `tdd`, but ds-help says `ds-tdd`, which stays visible — `grep -oE '\bds-[a-z0-9-]+\b' ds-help/SKILL.md` ∩ hidden = 14) and calls it acceptable because `/skill:<name>` still works. That is exactly the thing the human said he does not want to do.

## 2. THE ONE DELETION — reclaim holds; the report's evidence line does not

```
$ diff <(tail -n +5 /tmp/fix1-before/event-loop-orchestration/SKILL.md) \
       <(tail -n +5 ~/.agents/skills/v2-event-loop-orchestration/SKILL.md)
0a1
> ---
6c7,29
< - Delegate actionable requests immediately. Don't pre-investigate.
---
> - Delegate actionable requests immediately. Don't pre-investigate. DO NOT DO ANYTHING ELESE THAN DELEGATING
```

Nothing in v1 is missing from v2 (`lines only in v1: []`). So the deletion is safe on content. Three caveats:

- The report quotes `6c6,28 and nothing else`; the command actually prints `0a1` plus `6c7,29`. The quoted verification output is not reproducible.
- v2 is not "v1 + 23 lines of examples": line 7 adds a new imperative rule, not an example. "No rules differ" is false.
- v2 carries `disable-model-invocation: true` (`v2-.../SKILL.md:4`), so the surviving copy is the one the model cannot route to; `v2-event-loop-orchestration` is also untracked in dotfiles (`?? agents/.agents/skills/v2-event-loop-orchestration/`), and `~/.agents/skills/README.md:67` still lists the deleted `event-loop-orchestration`.

## 3. THE BUDGET — pi has no catalog cap, so 91 hidden skills fix a problem pi does not have

`docs/skills.md` is 93 lines and contains no budget, truncation or "too many skills" behaviour. The only length rule is per-description: `:81` "descriptions can contain at most 1024". `grep -n "budget\|truncat\|limit" docs/skills.md` returns only that line. The renderer has no guard either:

`dist/core/skills.js:278-297`
```js
const visibleSkills = skills.filter((s) => !s.disableModelInvocation);
...
lines.push(`    <name>${skill.name}</name>`);
lines.push(`    <description>${escapeXml(skill.description)}</description>`);
lines.push(`    <location>${escapeXml(skill.filePath)}</location>`);
```

What pi actually does with 132 skills: emits 132 `<skill>` blocks, every description, no truncation, no drop, no reordering. The cliff the report optimised for belongs to two *other* harnesses (Claude Code's 1% window, Codex's 8000-char `DEFAULT_SKILL_METADATA_CHAR_BUDGET`), and the report itself records that the ticket misquotes Claude Code ("drops descriptions starting with the skills you invoke least", not all). No source says pi caps anything. The 1500 is a ticket number applied to a harness that does not need it; hiding did buy ~2170 words of prompt (real tokens, ~5.4k at 4 char/token) at the cost of item 1.

## 4. TRIGGER LOSS — 10 sampled rewrites

| skill | what the human says | new description still routes? |
|---|---|---|
| `tiger-style` | "tiger mode", "write this defensively" | **No.** "tiger mode" and the whole correctness/defensive clause deleted from the text, and the skill is hidden (`tiger-style/SKILL.md:5`). |
| `tiger-style-audit` | "tiger audit", "audit for safety" | **No.** Both phrases deleted; "audit this codebase" kept. Also hidden. |
| `ghostex-help` | "how do I move the sidebar in Ghostex", "where is that setting" | **No.** The old text listed `"how do I"`, `"where is"`, `"can Ghostex"` and example commands; the new one is "Answer how Ghostex works". Also hidden. |
| `cua-driver` | "use Cua to click Save" | **No.** The word "Cua" is gone from the description; only "GUI automation" survives. |
| `superwhisper` | "push to talk isn't working" | **No.** "push to talk" deleted from the trigger list (`superwhisper/SKILL.md:3`). |
| `ai-image-generation` | "text2img", "stable diffusion", "dall-e alternative" | **No.** All 20 trigger keywords deleted. Also hidden. |
| `ds-context-reset` | "it keeps re-trying old fixes", "context is half full" | **No.** Both clauses deleted; only "model repeats itself" survives. Also hidden. |
| `archify` | "[archify explainer: …]" per the user's rules | **No.** The proactive opt-in clause and "lifecycle/state", "waterfall" are deleted. |
| `ponytail-review` | "code review", "review the last commit" | **Partly.** Both phrases deleted; "review this" / "review my PR" survive. |
| `ghostex-cli` | "gx pane", "Kanban card" | **Yes.** `ghostex`/`gx` kept; "Kanban" lost but "Beads board" covers it. Also hidden. |

Named losses: `tiger-style` (a whole mode), `ghostex-help`'s natural-language triggers, `cua-driver`'s product name, `superwhisper`'s "push to talk".

## 5. OUTSIDE OUR CONTROL — two symlinks, and eleven files a routine update overwrites

```
~/.agents/skills/cua-driver  -> ~/.cua-driver/skills/cua-driver
~/.agents/skills/superwhisper-> ~/.local/share/superwhisper/app/current/assets/agent-skill/superwhisper
~/.local/share/superwhisper/app/current -> .../app/1.3.0
~/.cua-driver/{current,releases}, version: 0.35.4, .release_installed
```

- Reversible now: `fix1-symlink-originals/` holds complete files — both have identical bodies to the live ones (`cua-driver`: 120 lines vs 120; `superwhisper`: 202 vs 195), so only frontmatter changed and a restore is exact.
- Not durable: both targets are versioned, app-managed directories behind a version pointer. An app install writes a new `app/<ver>`/`releases/<ver>` and moves `current`; the edited file is orphaned or replaced. Neither symlink's target is tracked by dotfiles (`A agents/.agents/skills/cua-driver` stores the link only; `superwhisper` is `??`), so git cannot restore either.

The larger version of this problem is not the two symlinks. `~/.jcode/bin/update-all.sh:316-330` re-syncs vendored skills with `cp -R` from its own upstream clones, and `~/.agents/skills/README.md:2` tells the operator to run it. 11 of the 69 edited skills are on that sync list: `babysit ponytail-audit ponytail-debt ponytail-gain ponytail-help ponytail-review tiger-style tiger-style-audit tiger-style-commit tiger-style-help tiger-style-review`.

Recomputing the tree as it will be after one `update-all.sh --skills-only`:

```
catalog=50 manual=82 catalog_words=1893   -> fix1-count.py FAIL
```

"Checks pass" is true only of the frozen snapshot. The first routine update silently re-adds `tiger-style` (79 words) and four other long descriptions and un-hides five skills, and the acceptance command starts failing with nobody watching.

## Smallest change that fixes the top finding

Delete the flagging step, not the rewrites: drop `add_disable(...)` from `~/.agents/loop/fix1-apply.py` (or set `KEEP = all names`) and re-run it, keeping the 17 rewrites and the dedupe. Result: 132 skills, every description ≤ 40 words for the 17 that were long, no skill made unnameable, no dependence on an invisible-update race with `update-all.sh`. The 1500 target should be dropped rather than met, because pi has no cap (`docs/skills.md:81`, `dist/core/skills.js:279`); if a number is still wanted, count characters of the shipped prompt, not words of a self-selected subset.

If only the regressions can be fixed: un-hide the 19 skills listed in item 1 — they are the exact set whose names appear in text the model reads.

---

## Verdict detail, per claim sentence

| claim | status |
|---|---|
| 3937 → 1458 catalog words | TRUE (`fix1-count.py`) |
| "by rewriting 17 long descriptions" | FALSE as stated — rewrites account for 274 of 2479 words |
| 1 duplicate deleted, survivor v2 | TRUE on content; the report's diff output is wrong and v2 adds a rule, not only examples |
| 57 more flagged, 91 of 132 hidden | TRUE |
| checks pass | TRUE now, FALSE after `update-all.sh` (1893 words, FAIL) |
| flow-referenced skills never hidden | TRUE (`flow/SKILL.md` ∩ hidden = `[]`, `flow/rules.md` = `[]`) |
| this was a fix | FALSE — no pi budget exists, and it regresses "never name a skill" |
