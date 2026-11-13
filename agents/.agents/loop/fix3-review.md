# FIX-3 rev1 — antagonist review (falsify)

VERDICT: block is byte-clean and the layer model holds for the pairs that differ; the claim is falsified on durability (5 of 7 lose the block on the next `update-all`), on coherence ("replaces" is stopping, so the block contradicts itself), and on floor protection (only 3 of 7 carry a literal "never cut" list; the rest are unprotected).

## 1. Block integrity — PASS

Byte-identical 5-line slice (header, blank, two paragraphs, blank) at the header line in all 7. `md5 = a087f16c3057e3b30a7e2f63312bcaaf` for every file, matching the claim's `a087f16c`.

| File | Header line | Block md5 |
|---|---|---|
| i-have-adhd | 21 | a087f16c… |
| caveman | 19 | a087f16c… |
| ponytail | 19 | a087f16c… |
| tiger-style | 33 | a087f16c… |
| ds-mode | 10 | a087f16c… |
| megacave | 20 | a087f16c… |
| ultracave | 20 | a087f16c… |

+5/−0 confirmed by diff on the one tracked file (`i-have-adhd`). One placement drift, not a rewording: in `caveman` the `/caveman status` paragraph sits inside the section, so at a glance the Precedence section also owns status text; elsewhere the section ends at the blank line.

## 2. Durability — FAIL (the kill)

`~/.jcode/bin/update-all.sh` syncs by `cp -R "$src/." "$dst/"` (overwrites `SKILL.md`), then re-runs overlays. Upstream clones contain `## Precedence` in **0** of 5 files. So:

| File | Synced by update-all | Overlay script | Fate of the block |
|---|---|---|---|
| ponytail | yes (`:319`) | none | **wiped** on next sync |
| tiger-style | yes (`:356`) | none (`-help`/`-review` only) | **wiped** |
| caveman | yes | `caveman.sh` (README links only) | **wiped** |
| ultracave | yes | `ultracave.sh` (README links only) | **wiped** |
| megacave | yes | `megacave.sh` (README links only) | **wiped** |
| ds-mode | no (absent from sync list and from `updater-src/`) | none | survives update-all; **untracked** in dotfiles (`??`), and `.skill-lock.json` names `aicodeking/deepseek-stack` as its source, so a lock-driven reinstall is an unguarded second path |
| i-have-adhd | no | none | survives; block is an uncommitted `M` in dotfiles |

Overlay required for: ponytail, tiger-style, caveman, ultracave, megacave (5). The mechanism exists (commit `7118765` re-applies overlays after sync); the caveman-family overlays are the obvious host and currently do not touch `SKILL.md`, so an idempotent `grep -q '^## Precedence' || insert` is missing exactly where it is cheapest. As written the contract silently keeps 2 of 7 members.

## 3. Six stacked pairs

| Pair | Layer verdict | Resulting rule | Ambiguity |
|---|---|---|---|
| ponytail + ultracave | work > output | ponytail sets scope and deletion; ultracave styles prose; ultracave `Never cut` (`:27`) survives via the floor sentence | none: floors and layers agree |
| tiger-style + caveman | work > output | assertions/bounds govern code, caveman governs prose; tiger-style's own Boundaries line already says this | redundant local precedence (`tiger-style:188`) now duplicates the block; two texts to keep in sync |
| ds-mode + i-have-adhd | work > output | ds-mode's smallest-diff and short-report win where they conflict; ADHD shapes layout | "Never omit relevant items… This rule shapes presentation only" (`i-have-adhd:112`) is a self-declared constraint in a losing layer; block does not say whether a losing rule with its own guarantee survives |
| megacave + caveman | same family | last voice only; the earlier one is gone | "the last voice chosen **replaces** the earlier one" vs "**No mode stops** because another started" — same block, opposite rulings |
| megacave + i-have-adhd | both output layer | two readings: (a) they stack ("Stacked modes both stay on, each in its own layer"), (b) last invoked wins and the other drops ("Same layer, two modes: the one invoked last wins") | yes — quoted above |
| ponytail + i-have-adhd | work > output | ponytail's scope/reply shape wins conflicts; ADHD still shapes the remainder | "what to build outranks how it reads" is a conflict test, but "Stacked modes both stay on" implies the loser still applies where the winner is silent; block never says which |
| tiger-style + ds-mode | same layer, last wins | winner's non-floor rules suppress loser's | no ambiguity — which is the problem (see §4) |

## 4. Floors — FAIL for the modes without a literal list

Literal "never cut" lists: `ponytail:49`, `ultracave:27`, `megacave:27`. Absent: `caveman` (has "Payload verbatim" `:61`, "ASD-STE100 is the floor" `:59`, "A dropped negation costs more" `:31`), `tiger-style` (assertions `:69`, bounded loops `:87`), `ds-mode` (irreversible action pause `:27`), `i-have-adhd` (`:112`, "Safety wins over brevity" `:129`).

Because the block protects only "a 'never cut' list", tiger-style's safety mandate is not a floor. `tiger-style + ds-mode` with ds-mode invoked last: ds-mode's "Delete before you add… Do not add layers, options, or helpers that nothing needs yet" beats "a minimum of two assertions per function" (`tiger-style:69`) and "All loops must have a fixed upper bound" (`:87`). The contract's own safety clause cannot rescue it. Same shape for `megacave + caveman`: megacave's `Never cut or translate` negation list is protected only while megacave is *active*, and "replaces" makes it inactive — so family replacement deletes a literal floor list by design.

## 5. Coherence — FAIL

Two sentences of one block rule the same case: "Same layer, two modes: the one invoked last wins. In the caveman family the last voice chosen **replaces** the earlier one; voices never stack." then "**No mode stops because another started.**" If a start can replace (family) or win over (same layer) a running mode, a mode does stop because another started. Only cross-layer starts are covered by the last sentence, and it is unqualified. The working reading has to be invented: "no *cross-layer* mode stops because another started."

## 6. Eighth persistence declarer — found

`archify/SKILL.md:22` declares a persistent, always-on behavior mode: "`[archify explainer: always-on]`: every reply that reaches a conclusion also gets a compact page…", persisted as a line in the global rules file, off by deleting the line (`:137`). It has no `## Precedence` block and no stop phrase in the mode vocabulary, and it collides head-on with caveman/ponytail terseness and "no unrequested artifacts". `caveman-help`/`ponytail-help`/`tiger-style-help` also say "sticks until changed or session end" but declare themselves one-shot and are cards, not modes — not candidates.

## What would make the claim true

1. Extend `caveman.sh`, `ultracave.sh`, `megacave.sh` and add `ponytail.sh` + `tiger-style.sh` with an idempotent block insert; commit `ds-mode` (untracked) and `i-have-adhd` (`M`).
2. Replace "No mode stops because another started" with "no mode stops because another mode *of a different layer* started".
3. Widen the floor sentence from "a 'never cut' list" to "a never-cut list or an unconditional safety mandate", or tag the four unlabeled floors.
4. Add `archify`'s always-on line to the mode list as an output rule, or state that tool-level rule lines are out of scope.
