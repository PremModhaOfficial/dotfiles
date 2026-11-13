# FIX-2 rev3 — four defects, each closed with a grep

Files touched: `ds-lessons/SKILL.md`, `ds-pr/SKILL.md`, `ds-ledger/SKILL.md`,
`tiger-style-review/SKILL.md`. `caveman-review/` untouched. Nothing outside those five
owned dirs. No commit.

Base for "original": `loop/fix1-backup-skills.tar.gz` extracted to `/tmp/rev3chk`.

---

## 1. ds-lessons — retro's fourth loss, the global-scope trigger: RESTORED

Appended to the `Steering files` scan bullet in retro's own words (retro split this across
two bullets, `Global AGENTS.md` and `No-ops`; `ds-lessons` merged them, so the trigger goes
on the merged one).

```
$ grep -n 'particularly large' ds-lessons/SKILL.md
17:   - **Steering files**: instructions in `AGENTS.md`/`CLAUDE.md` that belong in standards or a check instead, and instructions that change nothing. Trigger: the AGENTS.md file is particularly large — in the repo OR the user's global scope.

$ grep -n 'global scope' ds-lessons/SKILL.md
17: (same line)
```

Wording is retro's (`particularly large`, `in the repo OR the user's global scope`); the
`_Use when_` italics were dropped because no other trigger in `ds-lessons` is italicised.

## 2. ds-pr — eight worked examples and the phase-6 parentheticals: RESTORED

**(a) The eight examples** are back under `**Summary.**`, one fenced block under each of the
seven bullets, text copied from `pr/SKILL.md` (`on(save)`, `submitForm`, `<SessionPage>`,
`src/`, the Mermaid sequence, the four `diff` shapes, the `expandSkill` TS block). Not an
appendix — they sit inside the bullet they illustrate, and the existing placement sentence
still closes the section.

```
$ grep -n 'on(save)\|submitForm\|SessionPage\|show-me.ts\|sequenceDiagram\|expandSkill' ds-pr/SKILL.md
56:on(save)
66:submitForm
76:<SessionPage> (apps/example/src/routes/session.tsx)
91:- a Mermaid `sequenceDiagram`, for component interaction, control flow or data flow:
94:sequenceDiagram
108: <SessionPage>
121:+│   └── show-me.ts       # expands the slash command
132: submitForm
135:+    expandSkillMention
145: on(save)
156:function expandSkill(command: string): string {
```

Fence count is even (22), so the file still parses.

**(b) The phase-6 parentheticals.** Note the ticket's attribution: `open-pr/SKILL.md` has no
phase 6 and no such parenthetical; the deleted text is `decision-ledger/SKILL.md:33`, phase
6 of the audit. So it is restored in **both** places it is looked for, each self-contained:

```
$ grep -n 'not enabled at boot' ds-pr/SKILL.md ds-ledger/SKILL.md
ds-pr/SKILL.md:166:**Merge Danger.** … Blast radius is the scope of the impact — layout shift, broken consumers, mobile responsiveness. Pre-mortem the merge before you write it: "it breaks in a week; top 3 reasons?" (update overwrites config, not enabled at boot, no recovery path).
ds-ledger/SKILL.md:43:6. **Pre-mortem and skeptic pass.** "It breaks in a week; top 3 reasons?" (update overwrites config, not enabled at boot, no recovery path) → add rows or tests. …
```

`ds-ledger:43` is the original line with its worked example back (the ticket's file list
includes `ds-ledger`, and this is the loss rev1 §1a item 4 named). `ds-pr:166` is the
ticket's ask, placed where a reader writes `<optional: potential ramifications of merge>`.
Flagging the cost: the same three example reasons now live in two skills. They are examples,
not a contract, and the two jobs differ (audit pre-mortem vs PR body field), but if a later
review objects to duplication, `ds-pr:166` is the copy to drop.

## 3. tiger-style-review:107 — the deferral line: KEPT THE COPY, THE LINE STOPS POINTING

**Decision: it keeps the copy and the pointer now separates by job instead of delegating
comment voice** — because this is the file where the four prefixes are applied to Tiger
tags, and both `tiger-style-review` and `caveman-review` are upstream-owned
(`update-all.sh:355-359` and `:331-335`), so a pointer never had a stable owner to carry the
contract; deleting the copy would just move the same drift into the other upstream file.

```
$ grep -n 'caveman-review' tiger-style-review/SKILL.md
107:`caveman-review` is the standalone terse review: same one-line shape, the four
```

Full text now: "`caveman-review` is the standalone terse review: same one-line shape, the
four severity prefixes, no Tiger Style tag taxonomy. It owns comment voice with no safety
pass; `## Comment voice` above is that same contract applied to these tags, which is why
this file carries it rather than deferring. Use this one whenever the ask involves
invariants." No sentence routes comment voice away any more.

## 4. Truthfulness — what the current text now carries, and what it does not

Restored into `tiger-style-review`'s own copy, so the "Comment voice" section is complete
again rather than a paraphrase:

```
$ grep -n 'perhaps' tiger-style-review/SKILL.md
67:"this is just a suggestion but..." (use `nit:` instead), hedging ("perhaps",
$ grep -n 'not found in the database' tiger-style-review/SKILL.md
75:user is not found in the database. You might want to add a null check here."
```

So the hedge example words (rev2 dropped all three, they survived only in `caveman-review`)
and example 1's truncated clause are back.

Still **not** verbatim, and I am not claiming otherwise:

- **Prefix glosses**: reworded, meaning identical (`will cause an incident` vs
  `will cause incident`; `micro-optimisation. The author can ignore it` vs
  `micro-optim. Author can ignore`; `a genuine question` vs `genuine question`;
  `🟡 risk:` is already exact). No meaning is missing, so nothing to restore — the wording
  simply differs from the original file.
- **`ds-ledger:34` Lite** reads `no security or data impact` where the original read
  `no security/data impact`. Same meaning; left alone deliberately, so this is a rewrite.
- **`ds-ledger:3` description**: still broader than the original. The restore is the
  reviewer's sentence (`Use on such a task, even when the user never asks, and when they
  report something missed.`) anchored to `multi-phase or autonomous work`, so it fires on
  any multi-phase run and the original `real consequences` qualifier is still absent. I did
  **not** restore that: it changes when the skill auto-fires, which is outside these four
  defects. Report it as still out, do not call it restored.

The rev2 report is untouched, per the ticket; it should be read against this section.

## Verification

```
$ bash ~/.agents/skills/flow/scripts/check.sh
OK: flow rules and skill references valid
exit=0

$ ls -d ~/.agents/skills/*/ | wc -l
128                       # 126 real dirs + 2 external symlinks, unchanged
$ find ~/.agents/skills -name SKILL.md | wc -l
126
```

One grep per restored item is pasted above: §1 (2 hits), §2a (11 hits), §2b (2 files),
§3 (1 hit, resolved), §4 (2 hits).
