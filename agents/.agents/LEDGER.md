# Loop ledger — antipattern fixes

Router (me) never fixes. Workers fix. Antagonist reviewers verify blind.
Pattern emulated: DeepSeek superagent router/worker split (no DeepSeek Harness).

## Router decisions (revision 1, 2026-11-13)

- D1 Emulate the pattern only. No external harness. (user)
- D2 Pair = worker + antagonist reviewer. Reviewer never sees worker reasoning. (user)
- D3 Loop is the only writer of this file. Workers return deltas.
- D4 Concurrency: NO CAP on running workers (human, rev2). One slot still reserved so the human
  is never queued behind work. Router rule that replaces the cap: never spawn a worker onto files
  another worker owns (D6 does the real work here).
- D5 Deletion: exact duplicates only, survivor named in the report, never a skill that
  flow/SKILL.md or ds-help/SKILL.md references. Unique content is proposed, not deleted.
- D6 File ownership is disjoint per ticket. A worker touching another ticket's file is a REFUTED delta.
- D7 Every fix cites a source (spec, vendor doc, paper, issue). No source, ticket BLOCKED.
- D8 Loop-owned ticket: FIX-7 (track learning in dotfiles) is a commit the loop makes at the
  end of the iteration, because both builders write files in the same repo.
- D9 Reviewer verdict is CONFIRMED / REFUTED / UNVERIFIABLE with file:line. Anything but
  CONFIRMED leaves the ticket open. "Looks fine" is not a verdict.
- D10 SUPERSEDED by D13. I read "no cap" as a byte cap and kept the lift; the human meant the agent
  cap. The byte cap was mine and it is restored, but staged so it cannot delete rules again.
- D13 ~/.agents/AGENTS.md is capped at 4096 bytes AND holds every rule. The cap is met by moving
  verbose material (examples, command forms, rationale) into ~/.agents/references/*.md with one
  index line each, never by dropping an imperative. If the imperatives alone exceed 4096, the worker
  reports the required size instead of cutting a rule.
- D14 A cap is only legitimate when it is a cap on the always-loaded file, not on what the system
  knows. That distinction is what rev1 missed and rev3 must not.
- D12 Duplication is allowed in exactly one case: a harness that cannot import, like ~/.pi/agent/AGENTS.md
  (pi has no @ syntax). There the harness-critical rules are repeated inline and the file says why.
  Everywhere else duplication stays a defect.
- D11 FIX-4 rev2 (restore full text, no cap) runs in PARALLEL with r4's verdict; the reviewer was
  told to review what is on disk and to name the revision it saw, so a moved file is stated, not
  silently mis-scored.

## Scope order

| # | Antipattern | Stage |
|---|---|---|
| FIX-1 | description tax 4965 words / 133 skills; over-budget drops all descriptions | DONE (rev2 accepted, 2 report corrections) |
| FIX-4 | memory split-brain: 8130 B in commandcode file, 1673 B shared | review running (r4) → rev2 restore queued |
| FIX-7 | learning untracked in dotfiles | queued (loop-owned, D8) |
| FIX-2 | duplicate skill families (7 review, 11 memory, 3 PR) | queued — overlaps FIX-1 |
| FIX-3 | always-on modes stack and contradict (6 self-declared) | queued |
| FIX-6 | ambiguity threshold duplicated in 2 files | queued |
| FIX-8 | text-keyed guard, false positives | queued |
| FIX-5 | provenance: 96/133 skills bundled/manual, no owner | queued |
| FIX-9 | no project context at default cwd | queued |

## Iteration 1

w1 = FIX-1 (description diet). Owns: `~/.agents/skills/*/SKILL.md` frontmatter and duplicate dirs.
w2 = FIX-4 (memory merge). Owns: `~/.agents/AGENTS.md`, `~/.commandcode/AGENTS.md`, `~/.pi/agent/AGENTS.md`.

Acceptance checks
- FIX-1: description word count <= 1500; every skill referenced by flow and ds-help still exists;
  `bash ~/.agents/skills/flow/scripts/check.sh` exit 0; each deletion has a named survivor.
- FIX-4: each heading of the commandcode file moved or kept with a one-line reason; shared file
  <= 4 KB; no rule sentence present verbatim in two files (grep proof); commandcode file ends
  with a pointer line.

## Delta log

- FIX-4 rev4 REFUTED on its own numbers (reviewer r4c): 63 imperatives is ~45 unique (49
  obligations plus 14 non-imperatives, several double counted); duplication is 8.4% at a 0.65
  cutoff, not 2.3%, and 37.7% once the pi file's verbatim copy is counted; one reference was
  deleted at a stricter bar than a file that was kept; the pi file names shell_output, agent and
  pubsub_fire, which pi does not have; relative paths at AGENTS.md:61-67 break under cmd's import;
  delegation rules are pi-only although cmd also uses hc. Rev5 (w16-memfix5) fixes all six.
- MEASUREMENT RULE for the rest of the loop: a number is quoted with its method and threshold in
  the same sentence. No bare percentages. A reviewer may not accept a figure whose method cannot
  be rerun.
- Note for FIX-8: this session still holds the pre-rev3 guard, and it blocked a heredoc command
  whose text merely mentioned spawns and an agent binary. Same false-positive class as the bug the
  ticket is fixing; recorded while it is still reproducible.

- FIX-1 DONE, rev2 accepted by r1b. 126 = 95 visible + 31 hidden, zero new flags, 113/126 frontmatters
  byte-identical to the backup, 13 explained, longest description 606 chars, deletion clean.
  TWO CORRECTIONS to the worker's own report, recorded here instead of rewriting its file:
  (a) rev2.md:230-232 claims ultracave/megacave lose their hidden flag on a re-sync. False: upstream
      carries the same flag and cp -R re-installs it, so hidden survives. No overlay needed.
  (b) the cua-driver/superwhisper byte-check was circular (both tarballs store symlinks, so it read
      the live post-revert file). Real proof is fix1-symlink-originals, 431/527 chars identical.
  Consequence: the "sync instability" risk I escalated earlier was overstated. The real durability
  rule is D15 (never delete an upstream-synced skill), not an overlay.
- Open after FIX-1: 4 dead pointers (ultracave/megacave, setup-matt-pocock-skills, ghostex-browser-use)
  plus 2 stale overlay files for deleted skills. Held until w13-mergefix lands, to avoid touching the
  same trees twice.

- rev1 w2-merge (FIX-2) PARTLY REFUTED: 5 content losses (pr credits, decision-ledger Lite depth +
  phase 9 + description + evals, retro two rules, open-pr two lines, caveman-review examples) and
  /decision-ledger is a dead name. Rev2 (w13-mergefix) restores them, adds a 6-line alias.
- D15 NEW RULE: never delete an upstream-synced skill; the next sync restores it and the deletion is
  churn. Merge local skills only, or leave both and cross-reference. caveman-review is restored.

- rev1 w1-diet (FIX-1) REFUTED: hiding was 88% of the cut and pi has no catalog cap, so the trade
  bought nothing; 19 hidden skills are named by files the model reads. Rev2 (w9-unhide) reverts it.
- rev2 w3-restore (FIX-4 rev3): index/bytes/content confirmed, accounting REFUTED - 61% of reference
  tokens duplicate the inline file, and pi loads only 5 of 9 topics. Rev4 (w11-memfix) fires.
- rev2 w8-guard (FIX-8 rev1) REFUTED in the real pipeline: bash-guard rewrites to `bash -c`, the
  guard analyses once and never splits, so chained spawns pass. Rev2 (w10-compose) fires with a
  composed test required, because isolated tests hid this bug once.
- Lesson for the loop: isolated unit tests are not evidence for an extension that runs behind another
  extension. Every hook ticket must prove behaviour in the real handler order.

- rev1 delta w8-guard (FIX-8): DONE by worker. Guard rewritten to tokenize and take the executed
  binary instead of matching text. 16/16 cases, 20/20 probes, tsc strict clean, verified
  independently by the router (`node /tmp/fix8/guard.test.mjs` -> 16/16). Admitted bypasses:
  script files, heredoc piped to a shell, $(...) in double quotes, vars/alias/eval, docker run,
  joined flags. Reviewer r8-antagonist spawned to attack the permissive direction.
  NOTE: the running pi session still holds the OLD guard in memory; the fix takes effect on restart.
- rev1 delta w1-diet (FIX-1): catalog 3937 -> 1458 words, 99 -> 41 visible skills, 1 deletion,
  57 newly hidden. Reviewer r1-antagonist attacking the hiding decision; FIX-2 (w2-merge) is the
  real lever and is running.

- rev1: w1-diet (FIX-1) and w2-memory (FIX-4) launched, disjoint ownership per D6.
  Cleanup done: three finished panes killed and removed (t42, t43, t44); `hc rm <name>` does not
  accept a name, it needs the address (`hc kill t42` then `hc rm t42`). Note for FIX-8.
  Reserved human slot held: no third worker until one reports.
- rev1 delta w2-memory (FIX-4): DONE by worker. shared 1673->4092 B, cmd 8130->2589 B, pi 1320->532 B;
  6 sections moved, 2 kept local with reasons, 0 dropped, duplication grep 0. Caveats: 4096 cap forced
  prose compression; `graft` not on PATH so unverified; EGM bundle-root rule stayed pi-only.
  Reviewer r4-antagonist spawned DIFFERENT: it may run in parallel with w1-diet (read-only, no file edits).
- rev1 cleanup: w2-memory pane killed and removed (t46); t48 is the kept shell, not a worker.
