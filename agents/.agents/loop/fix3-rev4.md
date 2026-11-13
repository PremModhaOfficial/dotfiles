# FIX-3 rev4 — skills-audit now audits the block pin

Status: done. Files touched: `~/dotfiles/jcode/skills-audit.sh` only (+16 lines, check `6b`).
`update-all.sh`, the overlays and every `SKILL.md` untouched. Nothing committed.

## What the check does

New `6b` sits right after check 6 (the `.overlay-applied` stat), so nothing was renumbered
and nothing reformatted. For every overlay script (`skills-overlay/*.sh`,
`skills-overlay/host/*.sh`) that actually contains a `## Precedence` block:

- `blockmd5()` slices the block out of the overlay's own canonical heredoc
  (`/^## Precedence$/` … `/^Clean switch:/`, plus the trailing blank line, so the digest is
  over `block + "\n\n"` — byte-for-byte the string the overlay's python hashes);
- the same awk runs on the installed `$SKILLS_DIR/$skill/SKILL.md` (falling back to
  `$HOST_SKILLS_DIR/$skill/SKILL.md` for host overlays), and a mismatch is one `bad` line;
- `bad` → `AUDIT-TOTAL` grows → exit 1.

The pin is not a third hardcoded constant (the rev3 proposal's `= 1233061062…` would have
duplicated the md5 a third time, as its own author noted). The overlay's heredoc is the pin;
the audit reads it, so the two cannot disagree. Verified: all five pinning overlays
(`caveman`, `ultracave`, `megacave`, `ponytail`, `tiger-style`) derive
`1233061062fa5cd25129d1ce8051be82`; `paperclip` (host, no block) is skipped by the
`grep -qx '## Precedence'` guard rather than compared against the empty-input md5.

## Exit codes before / nudge / after

The live tree today carries two findings that predate this change — `ponytail` and
`tiger-style` have no `.overlay-applied` (check 6), so the live run is exit 1 with or without
my check. Captured **before** the edit:

```
$ bash jcode/skills-audit.sh
overlay not applied: ponytail
overlay not applied: tiger-style
AUDIT-TOTAL: 2
BASELINE_EXIT=1
```

So the 0 → 1 → 0 was proved with the two missing markers supplied for the duration
(`touch` of the two marker files, `rm` at the end — verified absent again afterwards), and the
nudge done in place on the live tree, since the check derives its paths from `$HOME`:
backup `/tmp/c.bak`, `sed -i 's/all stay on: each keeps/all stay in: each keeps/'`
(one word, inside the Precedence block of `~/.agents/skills/caveman/SKILL.md`), restore, `cmp`.

```
== BEFORENUDGE ==            == NUDGED ==                          == AFTER ==
AUDIT-TOTAL: 0               overlay block drift: /home/prm/.agents/skills/caveman/SKILL.md:
EXIT_BEFORE=0                  block md5 3781134365fcdf775c8429767c8e4070 != pinned
                               1233061062fa5cd25129d1ce8051be82
                               (from /home/prm/dotfiles/skills-overlay/caveman.sh)
                             overlay not applied: ponytail          AUDIT-TOTAL: 0
                             overlay not applied: tiger-style       EXIT_AFTER=0
                             AUDIT-TOTAL: 1
                             EXIT_NUDGE=1
RESTORE_IDENTICAL            (cmp clean)  md5 2ee25762d821f8d35a99d7f913415154 — the same
digest read off the file before the nudge, so the restore is byte-identical.
```

Failure message, verbatim:

```
overlay block drift: /home/prm/.agents/skills/caveman/SKILL.md: block md5 3781134365fcdf775c8429767c8e4070 != pinned 1233061062fa5cd25129d1ce8051be82 (from /home/prm/dotfiles/skills-overlay/caveman.sh)
```

Live tree after all of it, markers back to their real state:

```
$ bash jcode/skills-audit.sh
overlay not applied: ponytail
overlay not applied: tiger-style
AUDIT-TOTAL: 2
EXIT_FINAL=1
```

Same two findings as the pre-edit baseline, none from the new check — the canonical tree
passes `6b`. `bash -n` clean (no shellcheck installed here).

## Limits — the honest part

1. **The live tree does not currently exit 0**, contrary to the ticket's verify line: the
   `ponytail` and `tiger-style` markers are missing (check 6, unrelated to this change and to
   the block, which is canonical). That is a real "overlay never ran / never re-applied"
   finding; the fix is `update-all.sh`'s overlay pass, run by that file's owner. I did not
   `touch` the markers to hide it.
2. `6b` catches a *drifted* block and a *missing* block, but not a marker that lies while the
   block is right — that pair is still check 6's problem, and update-all's `run_overlay`
   remains the only thing that heals it.
3. The awk slices header → first `Clean switch:` line, same rule the overlays use; a second
   `Clean switch:` earlier in the block would make both sides agree on the wrong slice. Same
   blind spot as the pin itself, so no new risk.
4. Nothing watches the *non*-Precedence parts of the wrapped SKILL.md files; overlays that
   patch other sections still have no audit. Out of scope here.
