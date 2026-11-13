# FIX-3 rev3 — silent drift, the megacave contradiction, two floors, stop phrases, archify

Status: all five fixed and re-proved. Files touched: the 8 mode `SKILL.md` (block reword +
persistence line) and the 5 overlays that carry the block. `AGENTS.md`, `update-all.sh`,
`skills-audit.sh` untouched; nothing committed.

New canonical block md5: **1233061062fa5cd25129d1ce8051be82** (was `e76252e7…`).
Proof harness left in `/tmp/fix3r3/` (`verify.sh`, `verify.out`).

## 1. Silent drift — fixed in every overlay (worst defect)

`patch()` is gone. Each overlay now runs `ensure_block()`, which counts headers first and
refuses to write when the answer is not "exactly zero, or exactly one canonical copy":

| State found | rev2 behaviour | rev3 behaviour |
|---|---|---|
| no block, anchor present | insert, exit 0 | insert, verify header count == 1, exit 0 |
| one canonical block | skip, exit 0 | skip, exit 0 |
| one drifted block | **insert a second copy, no warning, exit 0** | `OVERLAY-WARN … drifted: <got> != <want>; refusing to insert a second copy`, exit **2** |
| two or more blocks | insert another | `… N Precedence blocks already present, expected 1; refusing to insert another`, exit **2** |
| anchor reworded, no block | `anchor not found` warn, **exit 0** | `anchor not found and no Precedence block present: …`, exit **3** |
| no SKILL.md / bad cwd / no mktemp | warn, exit 0 | warn, exit **3** |

`.overlay-applied` is touched only on exit 0, so a failed run cannot satisfy skills-audit.

The pin is no longer a literal: each overlay derives `want` from its own heredoc
(`blockof()` slices header → `Clean switch:`), so the block and its md5 cannot disagree.

### Drift test — both runs pasted

Same input both arms: pristine upstream `ponytail` copy, overlay applied, one word nudged in
the block, overlay re-run.

Before (rev2 overlay, kept verbatim in `/tmp/fix3r3/before-ponytail.sh`):

```
### BEFORE: nudge one word in the block, re-run
apply ok: Active for the whole session until the user says "stop ponytail" or "n
overlay done: /tmp/fix3r3/before/ponytail
re-run exit=0
headers=2 stale-copy=1 marker=present
```

→ no warning of any kind, two contradicting blocks, exit 0, marker written.

After (rev3 overlay):

```
### AFTER: nudge one word in the block, re-run
OVERLAY-WARN: ponytail: Precedence block drifted: 81e60bf21c901e632a34ed43dbdedcfa != 1233061062fa5cd25129d1ce8051be82; refusing to insert a second copy
OVERLAY-WARN: ponytail: not patched (exit 2); .overlay-applied NOT touched
re-run exit=2
headers=1 stale-copy=1 marker=absent
```

→ reason printed, non-zero, no second block, no marker.

Missing anchor (upstream line reworded, block absent): `exit=3 headers=0 marker=absent`.
Duplicate already present: `exit=2 headers-after=2` (refuses, changes nothing).

### Does a caller read that exit code? update-all yes, skills-audit no

**`update-all.sh` reads it.** `run_overlay()` (lines 417-438) wraps the script in
`if ( cd …; bash "$f" )`, and the else branch does `log "OVERLAY-WARN: $skill exited
non-zero"` + `checklist_add fail "overlay $skill (non-zero exit)"`. Line 843 then runs
`if grep -q '^fail' "$CHECKLIST_TMP"; then rc=1; fi`. Proved by extracting `run_overlay()`
verbatim into a harness and driving it against a drifted skill dir:

```
[log] OVERLAY-WARN: ponytail exited non-zero
run_overlay returned 0
--- checklist rows:
fail	overlay ponytail (non-zero exit)
update-all would exit: 1
```

So `update-all` logs the warn **and** exits 1 instead of "OK: overlay ponytail". (The
`CHECKLIST_TMP` merge also survives `--parallel`: each job's tsv is `cat`ed back into it.)

**`skills-audit.sh` does not read it, at all.** It has 0 occurrences of `OVERLAY-WARN` and 0
of `non-zero`. Check 6 (`:101-113`) only stats `.overlay-applied`. Driven verbatim against a
tree where the marker exists and the block md5 is `81e60bf2…` (drifted): no finding.

```
drifted block md5 in that dir: 81e60bf21c901e632a34ed43dbdedcfa (canonical 1233061062…)
check 6 finished, findings above (none = pass)
```

The rev2 claim "skills-audit surfaces the warn" stays false. One-line fix for its owner
(`skills-audit.sh`, after `:108`):

```bash
[ "$(awk '/^## Precedence$/{f=1} f&&/^Clean switch:/{print;print "";exit} f' "$SKILLS_DIR/$s/SKILL.md" 2>/dev/null | md5sum | cut -d' ' -f1)" = 1233061062fa5cd25129d1ce8051be82 ] || bad "overlay block drift: $s"
```

Trade-off: that duplicates the md5 into a third place. Better would be one shared constant
read by both, which is a bigger change than a line and not mine to make.

Also stale: the overlay contract comment at `update-all.sh:415` still says "exit 0 with an
`OVERLAY-WARN` line when it cannot patch". It should read "exit non-zero … (run_overlay
records a checklist fail)". Behaviour is already handled; only the comment is wrong.

## 2. Contradiction — one sentence per layer

Old line 1 ("Stacked modes both stay on … nothing is silently dead") and old line 4
("voices never stack") both governed megacave+caveman. Replaced by exactly one sentence each:

> Across layers, stacked modes all stay on: each keeps its own layer, and starting a mode in
> one layer never removes a mode in another.

> Within one layer only one voice is on at a time: a second mode in the same layer replaces
> the first, and in the caveman family the last voice chosen replaces the earlier one —
> voices never stack. The replaced mode's floor still holds, because floors cross layers.

megacave+caveman is one layer (output, one family) → line 2 only: later voice replaces. No
second reading. The floor question the reviewer raised is answered in the same breath: the
replaced mode's floor holds. Line 1's "nothing is silently dead" is deleted, not scoped.

## 3. Floors — both named, and the list is closed

> … and this list is the whole of it — … caveman's ASD-STE100 floor (20 words max, active
> voice, kept negations) and verbatim payload; tiger-style's two-assertions-per-function
> minimum, fixed loop bounds, and "never slow-path safety for developer convenience"; …

`caveman:61` "ASD-STE100 is the floor" and `tiger-style:182` "Never slow-path safety for
developer convenience" are now both in the block, and "this list is the whole of it" removes
the enumeration-vs-general-clause ambiguity the review found.

## 4. Stop phrases — one per voice

- `ultracave:17`: `until "stop ultracave" or "normal mode"` (was `"stop caveman"`).
- `megacave:19`: `until "stop megacave" or "normal mode"` (was `"stop caveman"`).
- `caveman:17` unchanged: `"stop caveman"` is caveman's alone.
- Block: `Clean switch: "stop ponytail", "stop caveman", "stop ultracave", "stop megacave",
  "stop adhd mode", "stop tiger-style", "stop ds-mode" each drop one mode; "normal mode"
  drops all of them.`

## 5. archify — description matches the file

"No activation" and "not a mode" are both gone (they contradicted `:144`, the consent flow
that adds the line, and `:29`, which calls `proactive`/`always-on`/`on-demand` modes):

> archify's `proactive` and `always-on` are rule lines in the host's rules file, switched on
> by its consent flow and off by deleting the line; `on-demand` is the default, its line
> only stopping the offer from recurring.

That is `:144` verbatim in effect (consent → add line → delete to turn off; `on-demand`
offered so the question stops), and it no longer asserts a mode-ness the file disputes.
The old ruling's false premise also went: the block no longer claims caveman bans
unrequested artifacts, it states the rule directly —

> Where an archify page would be made unasked (`proactive` or `always-on`) under ponytail,
> caveman, ultracave or megacave, the page is offered, not made, because an unrequested
> page is output nobody asked for.

## 6. md5 across 8 — identical, one header each

```
caveman      headers=1 block=1233061062fa5cd25129d1ce8051be82
ultracave    headers=1 block=1233061062fa5cd25129d1ce8051be82
megacave     headers=1 block=1233061062fa5cd25129d1ce8051be82
ponytail     headers=1 block=1233061062fa5cd25129d1ce8051be82
tiger-style  headers=1 block=1233061062fa5cd25129d1ce8051be82
ds-mode      headers=1 block=1233061062fa5cd25129d1ce8051be82
i-have-adhd  headers=1 block=1233061062fa5cd25129d1ce8051be82
archify      headers=1 block=1233061062fa5cd25129d1ce8051be82
```

Overlay ≡ installed, proved without an upstream copy: strip the block from each installed
file, run its overlay, `cmp` —

```
ponytail     exit=0 headers-after=1 round-trip=IDENTICAL
tiger-style  exit=0 headers-after=1 round-trip=IDENTICAL
caveman      exit=0 headers-after=1 round-trip=IDENTICAL
ultracave    exit=0 headers-after=1 round-trip=IDENTICAL
megacave     exit=0 headers-after=1 round-trip=IDENTICAL
```

Second run on all five: `skip  already applied: block md5 1233061062…`.

Side fix found while proving this: the 8 installed files did not end with a newline (rev2's
splice dropped it). They do now; the block md5 is unaffected.

## 7. Pair table (updated)

| Pair (invoked in this order) | Layer verdict | Rule now |
|---|---|---|
| ponytail + ultracave | work > output | ponytail sets scope and deletion; ultracave styles prose; ultracave's "never cut" still binds as a floor |
| tiger-style + caveman | work > output | tiger governs code, caveman governs prose; both floors named |
| ds-mode + i-have-adhd | work > output | ds-mode's diff and report rules win; ADHD shapes layout; its "never omit relevant items" binds |
| megacave + caveman | **same** layer, one family | within-layer sentence only: last voice replaces, voices never stack, replaced floor still holds |
| megacave + i-have-adhd | same output layer, two families | within-layer: megacave wins the layer; i-have-adhd keeps its floor and every rule megacave is silent on |
| tiger-style + ds-mode | same work layer | last-wins would give ds-mode; the named ruling gives tiger-style the assertion minimum and loop bounds |
| ponytail + archify `proactive`/`always-on` | work vs rule line | page offered, not made (archify named in the ruling) |
| caveman/ultracave/megacave + archify `proactive`/`always-on` | output vs rule line | page offered, not made — no longer rests on a ban caveman never states |
| anything + archify `on-demand` | default | no line, no unasked page |

## 8. Known limits

- `ds-mode`, `i-have-adhd`, `archify` have no overlay (no upstream source that resyncs them),
  so nothing re-asserts their block after an edit. Their md5 is checked by the 8-way loop,
  not by a script.
- `skills-audit.sh` still cannot see block drift (see §1) — the caller fix is proposed, not
  applied.
- A drifted block is refused, not repaired: someone has to read the warn and edit. That is
  deliberate; the alternative is the second-copy fork this rev exists to kill.
- Test harness in `/tmp/fix3r3/` is throwaway.

## Verify with

```bash
for s in caveman ultracave megacave ponytail tiger-style ds-mode i-have-adhd archify; do
  awk '/^## Precedence$/{f=1} f&&/^Clean switch:/{print;print "";exit} f' \
    ~/.agents/skills/$s/SKILL.md | md5sum
done   # eight times 1233061062fa5cd25129d1ce8051be82
bash /tmp/fix3r3/verify.sh   # every case above, before and after
```
