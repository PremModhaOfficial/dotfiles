# FIX-3 rev2 — antagonist review (falsify)

VERDICT: byte-identity and the overlay restore path are true; the claim fails on drift
behaviour (an edited block makes the overlay insert a *second* Precedence block and the pin
then passes silently), on two floors the block does not name although the files call them
"the floor", on the caveman-family stop switch, and on archify's "no activation". Not
ship-blocking for the 8-way md5, blocking for §Known-limits ("skills-audit surfaces the
warn") and for §3 ("All four previously unlisted floors are named").

## 1. md5 across 8 — PASS, no duplicate headers

| File | `## Precedence` headers | header line | block md5 |
|---|---|---|---|
| caveman | 1 | 19 | e76252e7fab6303cfaffab5ca9e85422 |
| ultracave | 1 | 20 | e76252e7… |
| megacave | 1 | 20 | e76252e7… |
| ponytail | 1 | 19 | e76252e7… |
| tiger-style | 1 | 33 | e76252e7… |
| ds-mode | 1 | 10 | e76252e7… |
| i-have-adhd | 1 | 21 | e76252e7… |
| archify | 1 | 18 | e76252e7… |

Placements match the claim's table exactly. No rev1 residue: `grep a087f16c` → 0,
`grep 'No mode stops'` → 0. All 5 overlays' heredoc blocks also md5 `e76252e7…`, byte-equal
to the installed slice (`cmp` on caveman's). `.pi/agent/skills` and `.commandcode/skills`
hold symlinks, not copies, so there is no stale third tree.

Caveat to §1's confidence: nothing checks *how many* `## Precedence` headers a file has, and
the claim's own verify one-liner (`awk … exit` on first `Clean switch:`) cannot see a second
one. §4 shows how one appears.

## 2. Overlay proof re-run end to end — PASS

From `~/.jcode/updater-src` (upstream has 0 `## Precedence`), copied to `/tmp/rv3/<skill>`:

```
ponytail/tiger-style/caveman/ultracave/megacave  apply ok → cmp vs installed: IDENTICAL
second run                                       skip  already applied (all five)
wipe (fresh upstream over patched dir)           wiped=d41d8cd9 restored=e76252e7 (all five)
```

Claim's proof reproduces. Evidence left in `/tmp/rv3`.

## 3. One pair still ruled two ways — FAIL

**(a) megacave + caveman, quoted verbatim from the block:**

> "Stacked modes both stay on, each in its own layer; nothing is silently dead."

vs

> "in the caveman family the last voice chosen replaces the earlier one; voices never stack."

Line 1 is unqualified. Line 4 puts two modes in one layer and kills one of them — dead, not
stacked. Only reading that saves it is inventing the scope "both stay on *across* layers",
which the text does not say. rev2 scoped the no-stop sentence and left this one.

Second-order defect on the same pair: the floor clause is scoped to "an explicit floor in any
**active** mode", and line 4 preserves "its floor" only "a mode in one layer never stops
because a mode in another layer started". So the replaced caveman's floor is preserved
across layers and not within one. Which is it for the family? Silent.

**(b) ds-mode last vs tiger-style** — resolved, but by specificity, not by wording:

> "Two conflicts are settled here rather than left to that clause."

"that clause" points backwards at work-beats-output, yet the clause that would otherwise rule
ds-mode/tiger-style is the *next* paragraph's "the one invoked last wins". The exception is
correct; its stated target is wrong. A reader who applies "settled … rather than left to that
clause" literally still has line 4's unconditional last-wins for the same pair. I would not
fail the claim on this alone — it is the clearest thing in the block.

**(c) caveman + archify** — the ruling rests on a premise caveman does not contain:

> "Where an always-on archify page meets a mode that forbids unrequested artifacts
> (ponytail, caveman), that mode wins"

ponytail does forbid them (`ponytail:34,42` "nobody asked for"). caveman does **not**: grep
for artifact/page output rules in `caveman/SKILL.md` finds only "Whole file only if the user
asks" (`:65`) — that is the opposite direction (don't paste files). So caveman is named as
holding a rule it never states, and with caveman the actual conflict (terseness vs an
appended page, both output layer) is not decided by the specific ruling.

**(d) archify vs everyone but ponytail/caveman** — undefined, because it has no invocation:

Line 1 classifies it inside a group: "output rules (caveman, ultracave, megacave,
i-have-adhd, archify)"; line 5 says it "is a rule line, not a mode". A layer member with no
invocation cannot be ranked by "the one invoked last wins". Witness pairs with no named
winner: archify + i-have-adhd, archify `proactive` + ultracave/megacave (see §5).

## 4. Does the pin fail loudly on an edited block? — FAIL, silently

Test: copy installed ponytail, change one word inside the block
(`nothing is silently dead` → `nothing dies silently`), run `ponytail.sh`:

```
apply ok: Active for the whole session …        ← no warning
Precedence headers after: 2                     ← canonical one inserted above the stale one
stale sentence still present: 1
overlay exit: 0, .overlay-applied touched
```

Why: `patch()` tests `if new in p` then `if old not in p`. The mutated block is neither, but
the *anchor line* is still intact, so the patch re-inserts the whole block. The pin then
slices from the first `## Precedence` to the first `Clean switch:` — the freshly inserted
canonical copy — so `got == EXPECT` and no warn is emitted. Net: a drifted block is not
repaired, not flagged, and now has a second contradicting copy under it.

Second path, anchor reworded upstream with block absent (`ponytail.sh`, anchor edited):

```
OVERLAY-WARN: ponytail: anchor not found: …
OVERLAY-WARN: ponytail: Precedence block drifted: d41d8cd9 != e76252e7…
exit=0
```

The warn exists, but: exit 0 → `run_overlay()` logs `OK:  overlay ponytail` and
`checklist_add done`; `touch "$MARK"` runs unconditionally → `.overlay-applied` exists.
`skills-audit.sh` check 6 (`:100-110`) only tests that the marker exists — it never reads the
log and has no `OVERLAY-WARN` or `Precedence` string in it (`grep` → 0 hits). So the claim's
"skills-audit surfaces the warn" is false: nothing consumes it. Drift is catchable only by
the human running the 8-way md5 check by hand, which is blind to duplicates (§1).

## 5. archify as "rule line, not a mode" — half true

- "off by deleting the line" **matches** archify: `:144` "deleting the line turns it off".
  PASS.
- "no activation" **contradicts** archify: the line is *added* by a consent-gated flow
  (`:144`, "要开启吗？ … add `[archify explainer: proactive] …` to the global rules file"),
  and there are three settings that change behaviour. Adding a line is activation in the only
  sense the file uses.
- "not a mode" **collides with the file's own vocabulary**: `:29` "In every mode a page needs
  a conclusion …", "never offer a mode", `:28` "the one-line mode offer". archify names
  `proactive`/`always-on`/`on-demand` as modes; the block, in the same file, 6 lines above,
  says the always-on line is not one. Two definitions of "mode" in one document, neither
  labelled.
- Coverage gap: the block's ruling names only the always-on setting. `proactive` also makes
  pages unasked (`:29`) and has no rule line; against ultracave/megacave (same output group,
  no named winner) it is undecided.

## 6. Persistence declarations the block does not cover

```
ultracave:17, megacave:19  "Every response, whole session, until "stop caveman" or "normal mode"."
block:  Clean switch lists "stop caveman" as dropping one mode — caveman.
```

After `/caveman ultra` the active voice is ultracave, not caveman. ultracave's own text says
"stop caveman" ends it; the block says that phrase drops caveman, which is not the active
mode, and neither `stop ultracave` nor `stop megacave` is in the list. One input, two readings.

```
archify:29    three settings (proactive / always-on / on-demand) — block rules one
tiger-style:191 "Level persists until changed or session end" — block's switch list has no session-end clause
ds-mode:3     "Always-on working style" — body has no stop phrase at all; "stop ds-mode" exists only in the block
```

Floor naming (§3 claim "All four previously unlisted floors are named") — falsified in the
strict sense, two files declare a floor the block does not name:

```
caveman:61        "ASD-STE100 is the floor: 20 words max, active voice …"
                  block names caveman's floor as "verbatim payload and kept negations" only
tiger-style:182   "Never slow-path safety for developer convenience."
                  block names tiger-style's floor as "assertions … loop bounds" only
```

The floor sentence reads "an explicit floor in any active mode survives every conflict
below — <list>". With an em-dash enumeration, unlisted but self-declared floors have two
readings: protected by the general clause, or not protected because the list defines it.

## What survives

1. §1 byte-identity and §2 restore path: verified, keep.
2. Scope line 1 to across-layer stacking, or delete "nothing is silently dead".
3. State that the floor list is imperative, or add ASD-STE100 and tiger-style's safety
   mandate to it.
4. Add `stop ultracave` / `stop megacave` (or say "stop caveman" ends the whole family).
5. Name `proactive` alongside `always-on`, and pick one meaning of "mode".
6. Overlay `patch()`: after a successful insert, check the header count is 1, and warn when
   the block is present-but-not-equal instead of inserting a second copy. Without that, the
   pin cannot catch the case it exists for.
7. Drop the "skills-audit surfaces the warn" claim, or teach check 6 to read the log.
