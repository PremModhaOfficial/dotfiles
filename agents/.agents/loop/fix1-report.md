# FIX-1 revision 1 — skill description budget

Worker report. Every number is reproducible with the commands shown.

## Verdict

| measure | before | after |
| --- | --- | --- |
| SKILL.md files | 133 | 132 (1 duplicate deleted) |
| description words, all skills ("raw") | 4948 | 4166 |
| **description words in the catalog** (skills the model can invoke itself) | **3937** (99 skills) | **1458** (41 skills) |
| catalog characters | 25 434 | 9 043 |
| descriptions over 60 words | 17 (1343 words) | 0 |
| skills carrying `disable-model-invocation: true` | 34 | 91 (57 added here) |

**The 1500 target is met on the catalog: 1458 words, exit 0.** Raw words across all 132 files are 4166 and cannot reach 1500: the only rewrite the ticket allows is "descriptions over 60 words down to 40 or fewer", so the 116 descriptions at or under 60 words are untouchable, and they hold 3605 words between them (4948 - 1343). A raw 1500 would need every sub-60-word description rewritten, which is outside the allowed actions.

The ticket quotes 4965 raw words; this machine measures 4948. The counter joins YAML block scalars into one line and strips quoting, which is where the difference comes from. The same command produced every column above:

```bash
python3 ~/.agents/loop/fix1-count.py          # totals, PASS/FAIL on the catalog
python3 ~/.agents/loop/fix1-count.py --top    # biggest descriptions
```

`fix1-count.py` is the arbiter: it counts `description` words in every `SKILL.md`, splits the catalog (no `disable-model-invocation: true`) from raw (all files), and exits 0 only when the **catalog** count is <= 1500. Current output ends `CATALOG words : 1458`, `target : 1500 -> PASS`.

Before numbers were measured before any edit, then re-measured from the frozen tree:

```bash
mkdir -p /tmp/fix1-before && tar xzf ~/.agents/loop/fix1-backup-skills.tar.gz -C /tmp/fix1-before
```

## Where the 1458 has to go

`~/.agents/skills/flow/SKILL.md` is on the forbidden list, and so is everything it references: its Plan/Build/Review/Ship ladder plus the escalations. That pinned set is 28 skills worth **1028 words** and it stays in the catalog, because a phase that says "escalate to `ds-jury`" is dead if `ds-jury` is manual-only. Add `flow` itself (57 words, under 60 so it cannot be rewritten) and 1085 of the 1500 are spoken for, leaving 415 for every other skill. The other catalog entries spend 373 of that. That is why 57 skills had to leave the catalog: there was no other lever.

## Reachability after the 57 flags

- `/skill:<name>` still runs every one of them — that is what the flag means (sources 3 and 5 below), and all 57 `SKILL.md` files are still on disk.
- 15 of the 57 are named in `ds-help`, which stays in the catalog and maps task to skill name: `ds-best-of-n ds-catchup ds-context-reset ds-design ds-design-audit ds-explain ds-ledger ds-mode ds-pr ds-principles ds-sharpen ds-swarm ds-unslop ds-watch-pr tdd`.
- No skill named in `flow/SKILL.md` was flagged. Check: scan every `[a-z-]+` token in that file against the flagged set — result `FLOWNAMED_MANUAL: []`.

## Two skills live outside this directory

`~/.agents/skills/cua-driver` and `~/.agents/skills/superwhisper` are **symlinks**, to `~/.cua-driver/skills/cua-driver` and to the Superwhisper app bundle (`~/.local/share/superwhisper/app/current/assets/agent-skill/superwhisper`). Editing their frontmatter writes to those targets, so the rewrite lands in an app-managed directory and a Superwhisper upgrade may replace it. Their original files are preserved at `~/.agents/loop/fix1-symlink-originals/`, because the tarball stores them as symlinks rather than as content. Everything else under `~/.agents/skills` is a real directory.

## What I could not do

- **Raw 1500.** Impossible under the allowed actions, as shown above.
- **Fit the vendor budget, not just the ticket number.** 1458 words is 9043 characters, about 2260 tokens at 4 chars/token. The Claude Code listing budget is 1% of the window — ~2000 tokens (~8000 characters) on a 200k window — and Codex's default is 8000 characters. At 1458 words the listing is therefore still ~13% over that line; ~1290 words would fit it. I stopped at the ticket number instead of removing ~5 more useful catalog entries. Operator's call.
- **The ticket's claim about Claude Code.** It says Claude Code drops *all* descriptions at once. The Claude Code doc says it drops descriptions *starting with the skills you invoke least*. Drop-all is what Codex's renderer does (`SKILL_DESCRIPTIONS_REMOVED_WARNING_PREFIX`, quoted below). Both sources are cited; neither changes the work.

## Tables

### Rewrites: every description that was over 60 words

| skill | words before -> after | chars before -> after |
| --- | --- | --- |
| `ghostex-agents` | 123 -> 34 | 704 -> 195 |
| `archify` | 103 -> 30 | 740 -> 223 |
| `ai-image-generation` | 101 -> 29 | 746 -> 226 |
| `decision-ledger` | 89 -> 36 | 604 -> 215 |
| `ghostex-help` | 89 -> 32 | 534 -> 194 |
| `tiger-style` | 79 -> 38 | 606 -> 293 |
| `feature-compare` | 78 -> 35 | 489 -> 219 |
| `ghostex-cli` | 78 -> 26 | 654 -> 218 |
| `superwhisper` | 72 -> 34 | 527 -> 277 |
| `ghostex-manage-beads` | 71 -> 30 | 423 -> 167 |
| `cua-driver` | 70 -> 40 | 431 -> 234 |
| `ghostex-visuals` | 70 -> 34 | 411 -> 210 |
| `code-review` | 68 -> 40 | 419 -> 235 |
| `tiger-style-review` | 67 -> 40 | 521 -> 295 |
| `ponytail-review` | 63 -> 38 | 370 -> 212 |
| `ds-context-reset` | 61 -> 39 | 349 -> 219 |
| `tiger-style-audit` | 61 -> 39 | 422 -> 264 |

### Deletions

| deleted | survivor | evidence the survivor does the same job |
| --- | --- | --- |
| `event-loop-orchestration` | `v2-event-loop-orchestration` | byte-identical body except 23 extra lines of examples in v2: `diff <(tail -n +5 /tmp/fix1-before/event-loop-orchestration/SKILL.md) <(tail -n +5 ~/.agents/skills/v2-event-loop-orchestration/SKILL.md)` reports `6c6,28` and nothing else, after extracting the frozen tree as shown above (the live v1 copy is the one being deleted), so v2 = v1 + examples. v1's own description said "Superseded by v2-event-loop-orchestration; use this one only when you specifically need the original v1 flow", and no rules differ. |

### Made manual-only (57 skills, `disable-model-invocation: true`)

34 skills already carried the flag before this ticket and were left alone. Every row below is a flag this ticket added.

| skill | words before -> after | reason it left the catalog |
| --- | --- | --- |
| `ai-image-generation` | 101 -> 29 | rare task the user names |
| `axi` | 26 -> 26 | rare task the user names |
| `babysit` | 40 -> 40 | description already says invoke as /name, so the catalog entry adds nothing |
| `brag` | 51 -> 51 | description already says invoke as /name, so the catalog entry adds nothing |
| `caveman-commit` | 19 -> 19 | family variant loaded by its named entry point |
| `caveman-compress` | 33 -> 33 | description already says invoke as /name, so the catalog entry adds nothing |
| `caveman-discover` | 31 -> 31 | rare task the user names |
| `caveman-evidence-review` | 26 -> 26 | rare task the user names |
| `caveman-help` | 15 -> 15 | one-shot help or stats card, typed by name |
| `caveman-learn` | 49 -> 49 | rare task the user names |
| `caveman-manage` | 23 -> 23 | side effect: writes, commits, deploys or spawns outside the chat turn |
| `caveman-optimize` | 28 -> 28 | side effect: writes, commits, deploys or spawns outside the chat turn |
| `caveman-review` | 23 -> 23 | family variant loaded by its named entry point |
| `caveman-setup` | 28 -> 28 | side effect: writes, commits, deploys or spawns outside the chat turn |
| `caveman-stats` | 25 -> 25 | one-shot help or stats card, typed by name |
| `codebase-design` | 40 -> 40 | reference material read on demand, not a routing target |
| `coordinator` | 9 -> 9 | side effect: writes, commits, deploys or spawns outside the chat turn |
| `docker-agent-command-code` | 51 -> 51 | reference material read on demand, not a routing target |
| `domain-modeling` | 23 -> 23 | reference material read on demand, not a routing target |
| `driving-t3-previews` | 36 -> 36 | rare task the user names |
| `ds-best-of-n` | 50 -> 50 | description already says invoke as /name, so the catalog entry adds nothing |
| `ds-catchup` | 44 -> 44 | description already says invoke as /name, so the catalog entry adds nothing |
| `ds-context-reset` | 61 -> 39 | description already says invoke as /name, so the catalog entry adds nothing |
| `ds-design` | 34 -> 34 | rare task the user names |
| `ds-design-audit` | 35 -> 35 | rare task the user names |
| `ds-explain` | 44 -> 44 | description already says invoke as /name, so the catalog entry adds nothing |
| `ds-ledger` | 38 -> 38 | rare task the user names |
| `ds-mode` | 39 -> 39 | description already says invoke as /name, so the catalog entry adds nothing |
| `ds-pr` | 25 -> 25 | side effect: writes, commits, deploys or spawns outside the chat turn |
| `ds-principles` | 31 -> 31 | reference material read on demand, not a routing target |
| `ds-sharpen` | 44 -> 44 | description already says invoke as /name, so the catalog entry adds nothing |
| `ds-swarm` | 41 -> 41 | rare task the user names |
| `ds-unslop` | 35 -> 35 | rare task the user names |
| `ds-watch-pr` | 34 -> 34 | side effect: writes, commits, deploys or spawns outside the chat turn |
| `feature-compare` | 78 -> 35 | rare task the user names |
| `find-skills` | 53 -> 53 | rare task the user names |
| `grilling` | 25 -> 25 | family variant loaded by its named entry point |
| `intent-interview` | 50 -> 50 | rare task the user names |
| `investigate-first` | 18 -> 18 | overlaps a flow-routed skill that stays in the catalog |
| `learned` | 49 -> 49 | rare task the user names |
| `linking-t3-prs` | 23 -> 23 | rare task the user names |
| `openhilclimb` | 53 -> 53 | rare task the user names |
| `ponytail-audit` | 54 -> 54 | rare task the user names |
| `ponytail-debt` | 28 -> 28 | one-shot help or stats card, typed by name |
| `ponytail-gain` | 21 -> 21 | one-shot help or stats card, typed by name |
| `ponytail-help` | 20 -> 20 | one-shot help or stats card, typed by name |
| `poster-design-generation` | 27 -> 27 | rare task the user names |
| `prem-search` | 56 -> 56 | overlaps a flow-routed skill that stays in the catalog |
| `rust-skills` | 48 -> 48 | reference material read on demand, not a routing target |
| `tdd` | 20 -> 20 | overlaps a flow-routed skill that stays in the catalog |
| `tiger-style` | 79 -> 38 | description already says invoke as /name, so the catalog entry adds nothing |
| `tiger-style-audit` | 61 -> 39 | rare task the user names |
| `tiger-style-commit` | 52 -> 52 | side effect: writes, commits, deploys or spawns outside the chat turn |
| `tiger-style-help` | 28 -> 28 | one-shot help or stats card, typed by name |
| `v2-event-loop-orchestration` | 29 -> 29 | rare task the user names |
| `verify-and-stop` | 21 -> 21 | rare task the user names |
| `wizard` | 47 -> 47 | side effect: writes, commits, deploys or spawns outside the chat turn |

### Still in the catalog after this ticket (41 skills, 1458 words)

````
archify cavecrew caveman caveman-explore code-review cua-driver decision-ledger diagnosing-bugs ds-adopt ds-blast-radius ds-blueprint ds-help ds-jury ds-lessons ds-plan-loop ds-pr-comments ds-ready ds-review-loop ds-revive ds-ship ds-tdd ds-unstick ds-verify-loop flow herdr lean-build making-skills migration ponytail ponytail-review pr prototype research rex safe-refactor superwhisper surgical-patch t3-code tiger-style-review web-browsing-cli writing-for-agents
````

## Verification (run after the edits)

```bash
$ python3 ~/.agents/loop/fix1-count.py
CATALOG words      : 1458
target             : 1500  -> PASS
exit 0

$ bash ~/.agents/skills/flow/scripts/check.sh
note: EGM skills at /home/prm/.pi/agent/git/github.com/*/elephant-goldfish-model/skills
OK: flow rules and skill references valid
exit 0
```

- YAML: all 132 `SKILL.md` frontmatters parse with `yaml.safe_load`; every `name` matches its directory; every description is non-empty and at most 437 characters, well under the 1024 cap (`bad: []`).
- No `AGENTS.md` opened for writing. No commit: `git -C /home/prm/dotfiles log --oneline -1` is still `cce6223` before and after; the only `AGENTS.md` paths in `git status` are pre-existing untracked files under `agents/` and `nvim/`, untouched here.
- `flow/scripts/check.sh` still resolves every skill `flow/SKILL.md` names, and `flow/rules.md` is unchanged.
- The deletion is reversible from `~/.agents/loop/fix1-backup-skills.tar.gz`; for the two symlinked skills use `~/.agents/loop/fix1-symlink-originals/`.

## Sources

Read before changing anything; each claim above points at one of these.

1. **https://agentskills.io/specification** — `description`: "Must be 1-1024 characters", "Should include specific keywords that help agents identify relevant tasks"; progressive disclosure: "Metadata (~100 tokens): The `name` and `description` fields are loaded at startup for all skills". Used for the 1024 cap and for why the catalog is a per-request cost.
2. **https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices** — `description`: "Must be non-empty * Maximum 1,024 characters * Cannot contain XML tags"; "At startup, the name and description from all Skills' YAML frontmatter are loaded into the system prompt"; "Claude uses it to choose the right Skill from potentially 100+ available Skills". Used for the 1024 cap and for keeping trigger words in the rewrites.
3. **https://code.claude.com/docs/en/skills** — three claims:
   - budget: "The listing always contains every skill name, but if you have many skills, Claude Code drops some descriptions to fit the listing's character budget ... The budget scales at 1% of the model's context window. When the listing overflows, Claude Code drops descriptions starting with the skills you invoke least".
   - per-entry cap: "the combined `description` and `when_to_use` text is truncated at 1,536 characters in the skill listing".
   - the flag: table row `disable-model-invocation: true` -> "You can invoke: Yes | Claude can invoke: Not on its own | When loaded into context: Description not in context, full skill loads when invoked"; and "**Hide individual skills** by adding `disable-model-invocation: true` to their frontmatter. This removes the skill from Claude's context entirely."
4. **https://raw.githubusercontent.com/openai/codex/main/codex-rs/ext/skills/src/render.rs** — Codex's renderer, verbatim: `SKILL_METADATA_CONTEXT_WINDOW_PERCENT: usize = 2` (2% of the window), `DEFAULT_SKILL_METADATA_CHAR_BUDGET: usize = 8_000`, `MAX_CATALOG_SKILL_DESCRIPTION_CHARS: usize = 1_024`, and `SKILL_DESCRIPTIONS_REMOVED_WARNING_PREFIX = "Exceeded skills context budget. All skill descriptions were removed and"` — that is the drop-all-at-once behaviour. Also `allocate_description_chars`, which hands description space out round-robin "so no skill monopolizes the remaining budget": one huge description is not only its own problem.
5. **~/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent/docs/skills.md** (local, this harness) — "Pi scans configured skill locations and adds each skill's name, description, and path to the system prompt"; "Set `disable-model-invocation: true` in frontmatter when a skill should be available only through its explicit command ... manually entered `/skill:name` commands still work"; frontmatter table: "`disable-model-invocation` | Hide the skill from automatic model selection". This is why the flags free the catalog *and* keep `/skill:<name>` working here, not only in Claude Code.

## Files this ticket wrote

- `~/.agents/loop/fix1-report.md` (this file)
- `~/.agents/loop/fix1-count.py` (the counter, and the acceptance command)
- `~/.agents/loop/fix1-apply.py` (idempotent edit script: rewrite map, keep list, reason for every flag)
- `~/.agents/loop/fix1-backup-skills.tar.gz` (pre-change tree), `~/.agents/loop/fix1-symlink-originals/` (the two files the tarball stores as symlinks)
- 69 `~/.agents/skills/*/SKILL.md` frontmatters changed (17 rewritten, 57 flagged, 5 both), and `~/.agents/skills/event-loop-orchestration/` removed
