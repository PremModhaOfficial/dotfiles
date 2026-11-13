# FIX-7b rev 1 — skills-overlay stale cleanup + 3 upstream-synced overlays

Date: 2026-11-13. Scope: `~/dotfiles/skills-overlay/*.sh`, lock via its generator.

## 1. Audit before

```
$ bash ~/dotfiles/jcode/skills-audit.sh
overlay not applied: claude-handoff
AUDIT-TOTAL: 1
EXIT=1
```

Exact failure mode (`skills-audit.sh` step 6): every `skills-overlay/<s>.sh`
requires `~/.agents/skills/<s>/.overlay-applied`. `claude-handoff`'s installed
skill dir was deleted, so the marker cannot exist and the overlay can never run:
`apply_overlays()` only logs `OVERLAY-WARN: no installed skill claude-handoff`
and moves on. The file was dead weight — its patch anchors on `claude --bg ...`
text no installed copy has.

Only **one** overlay complaint exists, not two. The other stale entries the
audit is silent about are lock rows: `claude-handoff`, `pr`, `retro` were in
`~/.agents/.skill-lock.json` with no installed directory (see §4).

## 2. Stale overlay fixed

Deleted `skills-overlay/claude-handoff.sh` (`git rm` + `rm`). No tombstone
format exists in the overlay contract, and a tombstone would still fail audit
step 6, so deletion is the fix.

## 3. Three upstream-synced overlays (re-sync keeps our edits)

Both files kept their existing README `../../` → upstream-URL fix and gained a
`SKILL.md` patch in the same literal-replacement format the other SKILL.md
overlays use (`OVERLAY-WARN` on a missing anchor, skip when the new text is
already present, `.overlay-applied` touched last):

| Overlay | Fix carried |
|---|---|
| `caveman-review.sh` | adds `## Not this one` at EOF (vs `tiger-style-review`) |
| `caveman-help.sh` | skill table: replace the one caveman-review row with the tiger-style-review + caveman-review rows |
| `tiger-style-review.sh` (new) | adds `## Comment voice`, `## Not this one`, two `## Boundaries` sentences |

### Proof (re-sync simulation, /tmp)

For each skill: copy the upstream source dir (what a sync copies), run the
overlay with `SKILL_DIR` set, diff against the installed copy:

```
caveman-review      apply ok -> IDENTICAL to installed
caveman-help        apply ok -> IDENTICAL to installed
tiger-style-review  3x apply ok -> IDENTICAL to installed
```

Idempotency on the live copies: each patch printed `skip  already applied`,
`diff -r` showed **unchanged**. `update-all.sh --skills-only --dry-run` accepts
the tree (it prints only `DRY:` lines; it does not execute overlays, so the /tmp
run above is the actual proof).

Markers: `~/.agents/skills/{caveman-review,caveman-help,tiger-style-review}/.overlay-applied`
exist. No `SKILL.md` body was edited by hand.

## 4. Lock

Path is `~/.agents/.skill-lock.json` (the ticket's `~/.agents/skills/...` is
wrong; `~/.skill-lock.json` is a symlink to the same file).

Named command, run from `~` and from `~/.agents`:

```
$ bunx skills@1.7.0 remove claude-handoff
No matching skills found for: claude-handoff
EXIT=0
```

No network failure (package resolved and cached). It is a **no-op for stale
rows**: the CLI matches installed skill directories, not lock rows, so a skill
whose dir is already gone cannot be removed. The lock was byte-identical
afterwards; nothing was hand-edited.

Global scope is the fix, and it is the same generator:

```
$ bunx skills@1.7.0 remove -g claude-handoff pr retro
Successfully removed 3 skill(s)
```

Result: lock `version 3`, **68 skills**, no lock row without an installed dir.

## 5. Audit after

```
$ bash ~/dotfiles/jcode/skills-audit.sh
AUDIT-TOTAL: 0
EXIT=0
```

Remaining complaints: none. Nothing left that belongs to another owner. The
only residual friction is upstream CLI behaviour (default project scope reports
"no matching skills" for lock-only rows instead of pruning them); the global
form works, so no follow-up ticket is needed here.
