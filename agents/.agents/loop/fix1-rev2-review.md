# FIX-1 rev2 — antagonist review

**Verdict: the claim stands on state (126 = 95 visible + 31 hidden, every flag pre-ticket,
no description over 1024, longest 606), but one stated risk is false and one verification
step is circular. Nothing in the skill tree needs reverting or re-editing.**

Re-derived from three snapshots, not from the report:

```bash
mkdir -p /tmp/fix1-before /tmp/fix1-rev1
tar xzf ~/.agents/loop/fix1-backup-skills.tar.gz      -C /tmp/fix1-before   # pre-ticket
tar xzf ~/.agents/loop/fix1-rev2-backup-skills.tar.gz -C /tmp/fix1-rev1     # rev1 tree
python3 ~/.agents/loop/fix1-count.py
bash ~/dotfiles/jcode/skills-audit.sh
```

---

## 1. Byte-exact revert — holds, one circular check

Flags, computed over all three trees:

| set | count |
| --- | --- |
| flagged pre-ticket / rev1 / now | 34 / 85 / 31 |
| rev1 hidden → visible now (rev1's added flags) | 54 |
| visible in rev1 → hidden now (new flags) | **0** |
| flagged pre-ticket, still installed | 31 — set-identical to now |

So **no installed skill differs in visible/hidden state from the backup.** The only
pre-ticket flags that are gone belong to skills deleted by other tickets:
`claude-handoff`, `open-pr`, `retro`.

Frontmatter is byte-identical to the backup for 113 of 126. The 13 that differ are exactly
`ai-image-generation archify code-review ds-context-reset ds-ledger ds-lessons ds-pr
feature-compare ghostex-agents ghostex-cli ghostex-help ghostex-manage-beads
ghostex-visuals` — the 10 kept rewrites plus three files (`ds-ledger`, `ds-lessons`,
`ds-pr`) another ticket touched. No hidden/visible surprise hides in that list.

**Defect in the evidence, not the state:** both tarballs store `cua-driver` and
`superwhisper` as symlinks (`tar tvzf …` shows link entries; extracting gives
`/tmp/fix1-before/cua-driver -> /home/prm/.cua-driver/skills/cua-driver`). Reading
`/tmp/fix1-before/cua-driver/SKILL.md` therefore reads the *live* app file after the
revert — the comparison is the file against itself. The revert is real, but the proof is
`~/.agents/loop/fix1-symlink-originals/` (saved 11:55): both are byte-identical to the
installed text (431 / 527 chars), and `fix1-report.md:67-69` records rev1 writing 234 / 277
chars. The reproduce block should point at the originals for those two, or it verifies
nothing.

## 2. Counts — holds

126 directories, 126 `SKILL.md`, README 126 rows plus header, 95 + 31 = 126. **No skill is
neither counted nor deleted.** `event-loop-orchestration` has no reference outside its own
survivor and no README row (`README.md:125` is `v2-event-loop-orchestration`).

Scope caveat, not a falsification: `~/.pi/agent/skills/paperclip` is a 127th installed,
visible skill that lives outside the ticket's tree and outside the README, so pi's actual
model-visible catalog is 96, not 95. The claim's arithmetic describes `~/.agents/skills`.

## 3. The 10 kept rewrites — 5 of them cannot route at all

`disable-model-invocation: true` removes a skill from the prompt
(`dist/core/skills.js:279`), so a rewritten description on a hidden skill is never read by
the model. Five of the ten are hidden for pre-ticket reasons: `ghostex-agents`,
`ghostex-cli`, `ghostex-help`, `ghostex-manage-beads`, `ghostex-visuals`. Their rewrites
change only the `/skill:` picker text. Routing only changes on these five:

| skill | phrase a human says | still routes? |
| --- | --- | --- |
| `ai-image-generation` | "make me a stable-diffusion / midjourney / dall-e image" | **weakened.** 20 triggers deleted (brand names, `text2img`, `gpt image`). Generic "AI image" survives; brand-phrased asks now compete with the visible `poster-design-generation`, whose description also claims "AI … generation". |
| `archify` | "draw this as a Mermaid diagram", "explain it as a page" | **mostly.** 做成一页 kept, "diagram" kept; `Mermaid` input, lifecycle/waterfall, themes/export and the proactive `[archify explainer: …]` opt-in are gone, so a rule that opts in no longer matches anything. |
| `code-review` | "review my PR since main" | **yes.** Lost "review since X" and "parallel sub-agents"; "review a branch, PR or WIP change" covers the ask. |
| `ds-context-reset` | "it forgot what we decided", "context is getting full" | **partly.** "context gets long" survives; "forgets earlier facts", "re-tries old fixes", "past about half full" are gone — the behavioural triggers, not the noun, are what a user actually types. |
| `feature-compare` | "compare X and Y", "does X have what Y has" | **yes.** "two or more products" recovers the N-product case; "who supports what" kept. |

**The two product-name restorations are confirmed and are the only ones left:**
`cua-driver`'s "…recall recent **Cua** activity" and `superwhisper`'s "…**push to talk**,
voice typing" are in the installed text and in `fix1-symlink-originals/`. Note the worker
understates the flip side: rev1 also stripped named triggers from the four `cp -R` rewrites
("tiger mode", "zero technical debt", "/tiger-style", "review the last commit", "code
review") and all of those are back too. Among text that is still edited, no product-name
loss remains.

## 4. Sync instability — **falsified for ultracave and megacave**

`fix1-rev2.md:230-232` says a re-sync drops their flags and makes both visible. It does not:

- `update-all.sh:331-336` copies every `$UPDATER_SRC/caveman/skills/*` dir with
  `cp -R` (`sync_dir`, `update-all.sh:299-308`).
- Upstream carries the flag: `updater-src/caveman/skills/ultracave/SKILL.md:7` and
  `…/megacave/SKILL.md:7` both have `disable-model-invocation: true`.
- Installed files are byte-identical to upstream (`diff` → IDENTICAL), so a re-sync
  re-installs the flag.

**Hidden is also the correct answer**: both descriptions say "Invoke only with
/ultracave|/megacave" and megacave's README says "Invoke: `/megacave` in Claude Code" —
manual-only is precisely the intent. It survives a re-sync with no overlay.

The 6 reverted survive too, for the same reason in each case:

| skill | next sync | durable? |
| --- | --- | --- |
| `tiger-style`, `-audit`, `-review`, `ponytail-review` | `cp -R` from `updater-src`; frontmatter now == upstream for all four (whole file identical for two; the other two differ only in body sections "Comment voice" / "Not this one" that this ticket did not write) | yes, frontmatter stable |
| `cua-driver` | `~/.cua-driver` is versioned app data; vendor text == installed text | yes, until the vendor changes its own text |
| `superwhisper` | `superwhisper-update.timer` runs every ~6h and repoints `app/current`; vendor text == installed text | yes, same reason |

So the sentence "the only durable answer is a post-sync overlay" is false here: no overlay
is needed for any of these eight. If a rewrite *were* wanted later, the mechanism already
exists and runs after every sync — `~/dotfiles/skills-overlay/<skill>.sh`, applied by
`apply_overlays()` (`update-all.sh:440-456`), markers checked at `skills-audit.sh:105-115`;
host-dir skills use `skills-overlay/host/`.

On the premise: `bash ~/dotfiles/jcode/skills-audit.sh` exits 1 with **two** issues, both
stale overlay *files* (`overlay not applied: caveman-review`, `overlay not applied:
claude-handoff`) whose skills other tickets deleted. The overlay path is not broken; those
two scripts should be deleted. They are the only reason a new overlay would look costly.

## 5. Dead pointers — all pre-ticket, unchanged by rev2

| named skill | named by | what breaks in practice | one-line fix |
| --- | --- | --- | --- |
| `ultracave`, `megacave` | `caveman/SKILL.md:19` (visible) tells the model to "follow the `ultracave` or `megacave` skill"; `caveman-help/SKILL.md:17-18` | `/caveman ultra` loads `caveman`, which points at a skill absent from the prompt and gives no path, so the model improvises from the 3-line summary — ultracave's Floor and persistence rules never load | in `caveman/SKILL.md:19`, replace the bare names with the path: "read `~/.agents/skills/ultracave/SKILL.md` (or `…/megacave/SKILL.md`) and follow it" |
| `setup-matt-pocock-skills` | 8 files, e.g. `code-review/SKILL.md:13`, `wayfinder/SKILL.md:25`, `to-tickets/SKILL.md:11` | they tell the *user* to run `/setup-matt-pocock-skills`; pi's form is `/skill:name` (`docs/skills.md:45,53`) and the skill is hidden, so the instruction dead-ends: tracker config never happens, and every downstream skill keeps asking for a tracker | `sed -i 's|/setup-matt-pocock-skills|/skill:setup-matt-pocock-skills|g'` on those 8 files |
| `ghostex-browser-use` | `driving-t3-previews/SKILL.md:3` (visible): general browser automation "belongs to ghostex-browser-use or cua-driver" | the named skill is hidden and its Ghostex half is dead on this host (`/opt/ghostex` absent, per its own overlay), so the model is sent to something it cannot load; `cua-driver` in the same sentence is the only working path | drop "ghostex-browser-use or" from that description line |

`cavecrew` names `ultracave` only as a voice ("answer in ultracave voice"), not as a
pointer to load — no fix needed there. `ghostex-cli`/`ghostex-computer-use` name
`$ghostex-browser-use`, but both are hidden, so the text surfaces only after an explicit
`/skill:` load.

---

## What I could not falsify

- Every hidden flag predates the ticket; rev1's 54 additions are gone; zero new flags.
- 95 + 31 = 126 on disk, README 126 rows, deletion clean.
- All 126 frontmatters parse with `yaml.safe_load`, name == directory, description ≤ 1024
  chars, longest 606 (`tiger-style`, restored upstream text).
- The 10 kept rewrites are on skills no `sync_dir` copies, so a `cp -R` sync cannot touch
  them. Residual, outside this ticket: `~/.agents/.skill-lock.json` still pins `archify`,
  `ai-image-generation`, `code-review`, `ds-context-reset` to their source repos, so a
  manual `skills update` (nothing on this host runs it — no timer, no cron) would revert
  those four.

## Residual risk the user must know

- The `tarball` reproduce path cannot verify the two symlinked skills; use
  `fix1-symlink-originals/`.
- `tiger-style-review` and `ponytail-review` carry local body sections ("Comment voice",
  "Not this one") that upstream does not have, so the next `cp -R` deletes them. Pre-ticket
  and not this ticket's doing, but "a sync can no longer undo a rewrite" is true only of
  the frontmatter.
- pi's visible catalog is 96, not 95, because `paperclip` lives only in
  `~/.pi/agent/skills`.
- `skills-audit.sh` stays red until `caveman-review.sh` and `claude-handoff.sh` are removed
  from `~/dotfiles/skills-overlay/`.
