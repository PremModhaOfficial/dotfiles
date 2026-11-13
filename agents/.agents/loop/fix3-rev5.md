# FIX-3 rev5 — overlay idempotency in the applied direction

Status: done. Live tree green, `skills-audit` exit 0, second run is a content no-op.

## What was actually wrong

The ticket's cause (overlay refuses a second block, so no marker is ever written)
describes the symptom, not the code path I found. Two defects, one shared by all
five Precedence overlays:

1. **The blocker.** The two overlays were authored after the installed SKILL.md
   already carried the block, and were never run against the live tree, so
   `~/.agents/skills/{ponytail,tiger-style}/.overlay-applied` did not exist and
   audit check 6 reported them unapplied. Nothing about the overlay refused; the
   marker was simply never created.
2. **The latent trap behind it.** `ensure_block()` decided "already applied" by
   byte-comparing the installed block (`cur == block`), while `skills-audit`
   check 6b pins the same block by md5. Two definitions of "applied": a block that
   can pass the audit pin and still be refused as drift is exactly how an overlay
   can stay red forever. That is the direction the ticket asked to fix.

## Change (identical in all five files, 3 lines)

`~/dotfiles/skills-overlay/{caveman,ponytail,tiger-style,ultracave,megacave}.sh`,
inside `ensure_block()`:

```diff
     cur = "\n".join(lines[i:tail[0] + 1])
-    if cur == block:
-        print("skip  already applied: block md5 " + want)
-        sys.exit(0)
     got = hashlib.md5((cur + "\n\n").encode()).hexdigest()
+    # Compare the pinned md5, not the bytes: an already-applied block must never
+    # exit non-zero, or the marker is never written and the audit stays red.
+    if got == want:
+        print("already applied: block md5 " + want)
+        sys.exit(0)
```

The rule now matches check 6b by construction, so the two can never disagree:

- block present, md5 == pin → `already applied: block md5 <want>`, exit 0, marker written (by the shared tail: non-zero is the only path that skips `touch`).
- block present, md5 != pin → `Precedence block drifted: <got> != <want>`, exit 2, marker untouched, no second block inserted.
- no block, anchor present → insert, verify exactly one block, exit 0.
- no block, no anchor → `anchor not found ...`, exit 3.

Scope: the other two of the seven (caveman-help, caveman-review) use a separate
forward-only `patch()` that already skips an applied replacement with exit 0, and
they have no Precedence block, so they were left alone. `skills-audit.sh`,
`update-all.sh`, the SKILL.md files, and the pinned text were not touched.

## Marker path convention

`$SKILL_DIR/.overlay-applied`, i.e. `~/.agents/skills/<skill>/.overlay-applied`
(host overlays: `~/.pi/agent/skills/<skill>/.overlay-applied`). Written only after
a zero exit, `touch`ed — empty file, presence is the whole signal; check 6 stats
it, check 6b separately pins the block md5.

## Audit before / after

Before (all seven markers removed, so the before state is the real "never run"
state; the ticket's original before was the same exit 1 with 2 findings):

```
overlay not applied: caveman
overlay not applied: caveman-help
overlay not applied: caveman-review
overlay not applied: megacave
overlay not applied: ponytail
overlay not applied: tiger-style
overlay not applied: ultracave
AUDIT-TOTAL: 7
AUDIT_EXIT_BEFORE=1
```

After the seven runs:

```
AUDIT-TOTAL: 0
AUDIT_EXIT_AFTER=0
```

## Seven overlays, one run each, live tree

| overlay | exit | message |
|---|---|---|
| caveman | 0 | `already applied: block md5 1233061062fa5cd25129d1ce8051be82` |
| caveman-help | 0 | `skip  already applied: <first line of the patched table row>` |
| caveman-review | 0 | `skip  already applied: <first line of the patched note>` |
| megacave | 0 | `already applied: block md5 1233061062fa5cd25129d1ce8051be82` |
| ponytail | 0 | `already applied: block md5 1233061062fa5cd25129d1ce8051be82` |
| tiger-style | 0 | `already applied: block md5 1233061062fa5cd25129d1ce8051be82` |
| ultracave | 0 | `already applied: block md5 1233061062fa5cd25129d1ce8051be82` |

Each also printed `overlay done: /home/prm/.agents/skills/<skill>` and left
`marker=yes`.

## No-op proof (second run)

Second run of the same seven, all exit 0, then comparing before/after state:
every `SKILL.md` and `README.md` md5 identical, no diff lines for content; the
only lines that move are the markers' mtimes, refreshed by `touch` on an empty
file (the audit only stats it, so this is expected, not drift).

## Refusal paths still refuse (temp copies, live tree untouched)

- drifted block (`Safety floor first:` → `second`): exit 2, `Precedence block drifted: dc44e95... != 1233061...`, blocks=1, marker absent.
- block stripped, anchor present (the fresh-sync path): exit 0, `apply ok`, one block, marker written.
- block and anchor both stripped: exit 3, `anchor not found and no Precedence block present`, marker absent.
