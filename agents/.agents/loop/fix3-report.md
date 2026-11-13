# FIX-3 (rev 1) — style-mode precedence, no orchestrator

## 1. Every skill that self-declares session persistence (grep, not the ticket's list)

Command: `grep -rniE "whole session|entire session|every (response|reply)|always[- ]on|stays? on|## Persistence|every response for the rest" --include=SKILL.md ~/.agents/skills ~/.pi/agent/skills`

Seven mode skills, all real dirs under `~/.agents/skills` (`~/.pi/agent/skills/*` are symlinks to them):

| # | file:line | the claim |
|---|-----------|-----------|
| 1 | `~/.agents/skills/caveman/SKILL.md:6` + `:15` `:17` | description "Stays on until stop caveman or normal mode"; §Persistence "Every response, whole session" |
| 2 | `~/.agents/skills/ultracave/SKILL.md:5` + `:16` `:18` | same, plus `/caveman status` |
| 3 | `~/.agents/skills/megacave/SKILL.md:5` + `:16` `:18` | same, plus `/caveman status` |
| 4 | `~/.agents/skills/ponytail/SKILL.md:17` | "Active for the whole session until …" |
| 5 | `~/.agents/skills/ds-mode/SKILL.md:3` + `:9` | description "Always-on working style"; "Apply this on every task" |
| 6 | `~/.agents/skills/tiger-style/SKILL.md:27` `:29` `:184` | `## Persistence`, "ACTIVE EVERY RESPONSE", "persists until … session end" |
| 7 | `~/.agents/skills/i-have-adhd/SKILL.md:3` + `:15` `:17` `:19` | "stays on until stop adhd mode"; §Persistence "every response for the rest of the session" |

Excluded on evidence, not on trust:

- `caveman-help`, `ponytail-help`, `tiger-style-help`, `caveman-stats` — explicitly one-shot ("do NOT change mode, write flag files, or persist anything").
- `archify/SKILL.md:22` — `[archify explainer: always-on]` is a per-reply rule variant, not a session mode; it has no off switch and no competing claim.
- `ds-help/SKILL.md:14` — "Any coding session (always on) | ds-mode" is a description of ds-mode, not a second claim.

No eighth mode exists. `~/.pi/agent/skills` contains 34 symlinks + `paperclip`; no non-symlinked mode skill hides there.

## 2. Prior art looked up

- **OpenAI Model Spec, Chain of Command** (model-spec.openai.com, 2025-10-27; restated in the 2026-08-18 revision): "Instructions with higher authority override those with lower authority", and "A later message can override an earlier one at the same authority level" / an instruction is superseded by a later same-level instruction that "contradicts it, overrides it, or otherwise makes it irrelevant". → authority classes + last-wins inside a class.
- **Claude Code output styles** (code.claude.com/docs/en/output-styles): "Claude Code sends the active style's instructions with every request"; "When you switch styles mid-session, Claude uses the new style starting with your next message". → a style is additive to the base prompt but only one is active; selecting a style replaces the previous one rather than stacking.
- **Codex / AGENTS.md precedence** (learn.chatgpt.com AGENTS.md docs; agents.md FAQ, issue #53): Codex concatenates every file root-down and "Files closer to your current directory override earlier guidance because they appear later in the combined prompt". → stacked documents, ordered, later/more-specific wins, no runtime needed.

Contract taken: Model Spec authority classes for *what beats what* + Claude Code's "a new voice replaces the old voice" for the caveman family + Codex's "later wins" for same-class ties. No new meta-skill, no orchestrator, no hook.

## 3. Where the contract lives, and why it is inlined

Every mode file carries the identical four-line `## Precedence` block (same bytes in all seven; `md5sum` of the block is `a087f16c…` in each).

A single shared file plus a one-line pointer was the ticket's preferred option, but it cannot work under these constraints:

1. The only always-read files are `~/.agents/AGENTS.md` and `~/.agents/references/` — both off-limits for this ticket.
2. The remaining candidates for a shared home are (a) a new skill — the ticket forbids inventing a meta-skill — or (b) a non-skill file nobody reads, which a rule cannot rely on: a pointer fires only if a model chooses to go read it.
3. A third file would also break the worst case this ticket is about: ultracave loaded with ponytail and the canonical file never read.

So the ticket's fallback clause applies verbatim — "a three-line precedence block repeated identically is acceptable only if nothing else will be read". Nothing else will be read: when two modes stack, both mode files are already in context, and both copies are byte-identical.

The block answers the three required questions in the file itself:

- **Two style modes active** → both stay on, layered; work rules (ponytail, ds-mode, tiger-style) beat output rules (caveman, ultracave, megacave, i-have-adhd); same layer → last invoked wins; caveman family → last voice replaces, never stacks.
- **Style contradicts structural** → structural wins ("what to build outranks how it reads"), *after* the safety floor.
- **What the user types** → one `stop <mode>` per mode, or `normal mode` to drop all. Plus: "No mode stops because another started", which kills the silent-death failure directly.

## 4. Floors preserved

Never cut: none removed, none reordered, none weakened. `ultracave` §Floor, `megacave` §Floor, `ponytail` "Never cut: validation at trust boundaries…", `tiger-style` §"When NOT to Tiger Style" / boundaries, `caveman` §"When to break the rules" (7 cases), `i-have-adhd:127` "A rule fights the task… the task wins", `ds-mode` "Pause before irreversible actions" — all unchanged, and the new block ranks every one of them *above* the precedence rules it defines.

## 5. Verification — six stacked pairs

| Stacked pair | Wins | Rule applied | Why it is not silent death any more |
|---|---|---|---|
| ponytail + ultracave | ponytail's closing "what I skipped" line | work ≠ output → work wins | closer is now a duty, not ceremony; ultracave still owns every other sentence |
| caveman + tiger-style | tiger-style, on code | work rules beat voice | "Comments are sentences. Capital letter, full stop" survives; caveman compresses chat, not comments |
| ds-mode + i-have-adhd | ds-mode, on process | work rules beat output shaping | adhd shapes the reading, ds-mode decides the steps and the evidence rule |
| ponytail + tiger-style | last invoked, except floor items | same layer → last wins | both are work rules; floor items in either still survive |
| caveman + i-have-adhd | i-have-adhd on layout, caveman on words | same layer → last invoked wins on overlap | "lead with the next action" and "answer first" agree; the numbering loses only if caveman was invoked after |
| ultracave + megacave | last voice chosen | caveman family replaces, never stacks | one language register on screen at a time |

Switch test, all six: `stop ponytail`, `stop caveman`, `stop adhd mode`, `stop tiger-style`, `stop ds-mode`, and `normal mode` for a clean slate — dropping one mode never drops another.

## 6. Changes

Seven files, +5 lines each, nothing else touched. No git commit, no `~/.agents/AGENTS.md`, no `~/.agents/references/`, no `update-all.sh`.

```
caveman/SKILL.md       89 →  94   +5
ultracave/SKILL.md     63 →  68   +5
megacave/SKILL.md      65 →  70   +5
ponytail/SKILL.md      52 →  57   +5
ds-mode/SKILL.md       50 →  55   +5
tiger-style/SKILL.md  186 → 191   +5
i-have-adhd/SKILL.md  142 → 147   +5
```

## 7. Grep proof

```
$ grep -rn "## Precedence" caveman ultracave megacave ponytail ds-mode tiger-style i-have-adhd --include=SKILL.md
caveman/SKILL.md:19       ultracave/SKILL.md:20    megacave/SKILL.md:20
ponytail/SKILL.md:19      ds-mode/SKILL.md:10      tiger-style/SKILL.md:33
i-have-adhd/SKILL.md:21

$ grep -rln "## Precedence" ~/.agents/skills --include=SKILL.md
→ the same seven files, no others

$ grep -c "Persistence\|whole session\|ACTIVE EVERY RESPONSE\|always-on" … 
→ 16 claim sites, every one in a file that now also carries ## Precedence
```

Residual risk: `ds-mode` and `one-shot` helpers outside these seven could still assert persistence in future edits; only a repo-level check (`update-all.sh` or a test) can stop that, and both are out of scope here.
