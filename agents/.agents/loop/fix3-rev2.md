# FIX-3 rev2 — durability, coherence, floors, eighth mode

Block md5 (header through the blank line after the last line): **`e76252e7fab6303cfaffab5ca9e85422`**
(rev1 was `a087f16c3057e3b30a7e2f63312bcaaf`; rev2 is one wording, longer, same 8 carriers.)

## 1. Durability — the kill, closed

`update-all.sh:306` syncs with `cp -R`, then `apply_overlays()` (`:440`) re-runs
`~/dotfiles/skills-overlay/<skill>.sh` in the installed dir. Upstream has `## Precedence`
in 0 of 5 files. Five overlays now re-apply the block:

| Skill | Overlay | Change |
|---|---|---|
| ponytail | `skills-overlay/ponytail.sh` | **new** |
| tiger-style | `skills-overlay/tiger-style.sh` | **new** |
| caveman | `skills-overlay/caveman.sh` | extended (was README links only) |
| ultracave | `skills-overlay/ultracave.sh` | extended |
| megacave | `skills-overlay/megacave.sh` | extended |

Format is the existing literal-patch one (`caveman-help.sh`, `caveman-review.sh`): an
`old`/`new` heredoc pair, one replacement, skipped when the new text is already present.
Each anchor is a line upstream actually ships:

- ponytail — the `Active for the whole session…` line
- tiger-style — `## The Protocol`
- caveman — the `Every response, whole session…` line (the block must sit above the
  `/caveman ultra` alias paragraph, so a heading anchor would land it in the wrong place)
- ultracave, megacave — the `Every response, whole session…` line

Each overlay ends with a self-check: the block slice's md5 must equal
`e76252e7fab6303cfaffab5ca9e85422`, else `OVERLAY-WARN: … Precedence block drifted`.
That is what catches a copy that goes stale relative to the other seven.

### Proof (the earlier overlay ticket's method)

1. copy the upstream dir to `/tmp/ovtest/<skill>`
2. run the overlay with `SKILL_DIR` set, as `run_overlay()` does
3. diff against the installed dir

```
ponytail     SKILL.md same      (diff: only /tmp's .overlay-applied, expected)
tiger-style  SKILL.md same      (same)
caveman      identical (whole dir, README included)
ultracave    identical
megacave     identical
```

Second run on the patched copy prints `skip  already applied` for all five: idempotent.
Simulated wipe (fresh upstream copied over the patched copy, block absent = `d41d8cd9`):

```
ponytail     wiped=d41d8cd9 restored=e76252e7fab6303cfaffab5ca9e85422
tiger-style  wiped=d41d8cd9 restored=e76252e7fab6303cfaffab5ca9e85422
caveman      wiped=d41d8cd9 restored=e76252e7fab6303cfaffab5ca9e85422
ultracave    wiped=d41d8cd9 restored=e76252e7fab6303cfaffab5ca9e85422
megacave     wiped=d41d8cd9 restored=e76252e7fab6303cfaffab5ca9e85422
```

`update-all.sh --dry-run` does not execute overlays (it logs and skips, `:443`), so the
/tmp run above is the real proof, as it was for the earlier overlay ticket.

Not covered, deliberately: `ds-mode` is outside `sync_skills()`, so its live risk is a
lock-driven reinstall (`.skill-lock.json` → `aicodeking/deepseek-stack`), not
`update-all`. `ds-mode` is untracked in dotfiles and `i-have-adhd` is `M`; the loop's
commit fixes both. If that second path ever fires, the same overlay shape with anchor
`Apply this on every task. It keeps the loop tight and the claims honest.` closes it.

## 2. Coherence — one rule, no contradiction

rev1 said "the last voice chosen **replaces** the earlier one" and "**No mode stops**
because another started". Now:

> Replacement happens inside a layer, never across it: … the one invoked last wins, …
> A mode in one layer never stops because a mode in another layer started: the earlier
> mode keeps its layer, its floor, and every rule the winner is silent on.

Replacement is scoped to a layer; stop-by-another is scoped to across layers. No case is
ruled both ways, and the losing rule's own guarantees survive by the last clause.

## 3. Floors — every mode named

The floor sentence no longer protects only a literal "never cut" list. It names each
mode's floor, including the four that had no literal list:

- ponytail / ultracave / megacave — their `Never cut` lists
- caveman — verbatim payload, kept negations
- tiger-style — two-assertions-per-function minimum, fixed loop bounds
- ds-mode — pause before an irreversible action
- i-have-adhd — "never omit relevant items", "safety wins over brevity"
- archify — validation before delivery

The concrete conflict is ruled in the block, not left to the safety clause:

> Where ds-mode's "delete before you add" meets a tiger-style assertion minimum or loop
> bound, **tiger-style wins**: delete something else, or say why the deletion is elsewhere.

Winner named: tiger-style. ds-mode still wins the rest of the same-layer collision (it is
the smaller-diff rule); only the assertion minimum and loop bounds are lifted out of it.

## 4. Eighth declarer — archify

`archify/SKILL.md:22` stays always-on, and archify now carries the same block (byte-for-byte,
before `## Choose the artifact`), plus the block states the one line that settles what it is:

> archify's always-on line is a rule line, not a mode: no activation and no `stop` switch —
> delete that line from the host's rules file to turn it off.

and the artifact ruling:

> Where an always-on archify page meets a mode that forbids unrequested artifacts
> (ponytail, caveman), that mode wins and the page is offered, not made.

So: not a mode in the mode list's sense (no activation, no layer of its own, off switch is
deleting the line), and its collision with caveman/ponytail has a named winner.

## 5. Placement and md5s

| Skill | Header line | Block md5 |
|---|---|---|
| caveman | 19 | e76252e7… |
| ultracave | 20 | e76252e7… |
| megacave | 20 | e76252e7… |
| ponytail | 19 | e76252e7… |
| tiger-style | 33 | e76252e7… |
| ds-mode | 10 | e76252e7… |
| i-have-adhd | 21 | e76252e7… |
| archify | 18 | e76252e7… |

Verified one `## Precedence` per file (no duplicates from the patch).
The five overlays carry the identical text and the pinned md5; `ponytail.sh` and
`tiger-style.sh` are tracked-new, the caveman-family three are edits.

## 6. Pair table — 8 stacked pairs

| Pair (invoked in this order) | Layer verdict | Resulting rule |
|---|---|---|
| ponytail + ultracave | work > output | ponytail sets scope and deletion; ultracave styles prose. ultracave's `Never cut` list still binds — floor, not loser |
| tiger-style + caveman | work > output | assertions and bounds govern code; caveman governs prose and keeps its payload/negation floor |
| ds-mode + i-have-adhd | work > output | ds-mode's smallest-diff and short report win; ADHD shapes layout. i-have-adhd's "never omit relevant items" still binds as a floor |
| megacave + caveman | same layer, same family | megacave replaces caveman; voices never stack. One rule, no second reading |
| megacave + i-have-adhd | same output layer, two families | megacave wins the layer; i-have-adhd keeps its floor and every rule megacave is silent on |
| tiger-style + ds-mode | same work layer, ds-mode last | last-wins gives ds-mode, **except** the assertion minimum and loop bounds: tiger-style wins those by the named ruling |
| ponytail + archify always-on | work > output | no unrequested artifact: page offered, not made |
| caveman + archify always-on | output vs standing rule line | archify is not a mode and cannot displace caveman: page offered, not made |

## 7. Persistence claims — all carry the block

grep for `whole session|rest of the session|always-on|every response|persists until`
returns hits in all 8 files; each has exactly one `## Precedence` header. No file states a
persistence or always-on claim without the block beside it.

## Verify with

```bash
cd ~/.agents/skills
for f in caveman ultracave megacave ponytail tiger-style ds-mode i-have-adhd archify; do
  awk '/^## Precedence$/{f=1} f&&/^Clean switch:/{print;print "";exit} f' $f/SKILL.md | md5sum
done   # eight times e76252e7fab6303cfaffab5ca9e85422
```

```bash
# overlay ≡ installed, from a clean upstream copy
for s in ponytail tiger-style caveman ultracave megacave; do
  cp -R ~/.jcode/updater-src/.../<skill> /tmp/ov/$s
  ( cd /tmp/ov/$s && SKILL_DIR=/tmp/ov/$s bash ~/dotfiles/skills-overlay/$s.sh )
  cmp ~/.agents/skills/$s/SKILL.md /tmp/ov/$s/SKILL.md
done
```

## Known limits

- The block lives in 8 skills plus 5 overlays (13 copies, 2 distinct texts: prose and
  heredoc). Drift is caught by the pinned md5 in each overlay and by the 8-way md5 check
  above, not prevented at write time.
- Anchors are upstream lines. A reword fails soft (`OVERLAY-WARN: anchor not found`) and
  the block is lost until the anchor is updated; skills-audit surfaces the warn.
- `ds-mode`'s lock-driven reinstall path stays unguarded (see §1).
