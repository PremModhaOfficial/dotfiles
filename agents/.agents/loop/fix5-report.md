# FIX-5 — skill provenance

Ticket: 126 skills, README's source column put 96 of them in `bundled/manual`.
Deliverables: `~/.agents/skills/PROVENANCE.md` (new) and this report.

Files written: `~/.agents/skills/PROVENANCE.md`, `~/.agents/loop/fix5-report.md`.
Not written: any SKILL.md, `update-all.sh`, `README.md`, any AGENTS.md. No skill
deleted.

## 0. Count note

The ticket says 126. The tree held 126 when this started (124 dirs + 2 vendor
symlinks) and 128 when it finished: `caveman-review` and `decision-ledger`
appeared at 12:17 while this ticket was running (another session; README was
regenerated then too, and now lists 128). All 126 ticketed skills are present,
once each; the two newcomers are classified as well so PROVENANCE.md matches
disk. Numbers below are given for both.

## 1. Class table

| Class | Ticketed 126 | Whole tree (128) |
|---|---|---|
| upstream, repo or install path named | 107 | 108 |
| local, hand-written (ours) | 19 | 20 |
| unknown after dig | 0 | 0 |
| **total** | **126** | **128** |

Per upstream source (whole tree, sums to 108):

| Source | n |
|---|---|
| aicodeking/deepseek-stack | 29 |
| mattpocock/skills | 27 |
| JuliusBrussee/caveman | 22 |
| DietrichGebert/ponytail | 6 |
| raine/workmux | 5 |
| PremModhaOfficial/tiger-style | 5 |
| herdrdev/herdr | 1 |
| a5c-ai/babysitter | 1 |
| 101-skills/superpowers | 1 |
| tt-a1i/archify | 1 |
| kunchenguid/axi | 1 |
| latent-spaces/brag | 1 |
| vercel-labs/skills | 1 |
| eachlabs/skills | 1 |
| leonardomso/rust-skills | 1 |
| only-cli/oc | 1 |
| ayghri/i-have-adhd | 1 |
| Rex CLI install | 1 |
| cua-driver app | 1 |
| Superwhisper app | 1 |

### Command per class

```bash
cd ~/.agents/skills

# installer ledger — 68 installed skills, each with sourceUrl + installedAt
python3 -c "import json;d=json.load(open('/home/prm/.agents/.skill-lock.json'))['skills'];print(len(d))"

# updater ledger — 35 installed, stamped at sync time by update-all.sh:stamp_source
cat ~/.jcode/state/upstream-sources

# vendor app symlinks — 2
find . -maxdepth 1 -type l -exec readlink {} \;

# repo named in the skill text
grep -ohiE 'https?://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' */SKILL.md | sort -u

# a tool that ships its own skills — the installed binary carries the text
strings "$(command -v workmux)" | grep -c 'Rebase the current branch with smart conflict'

# npm package carrying the same SKILL.md
diff web-browsing-cli/SKILL.md \
  ~/.npm-global/lib/node_modules/@only-cli/oc/skills/web-browsing-cli/SKILL.md

# licence stated inside the skill itself (4 skills)
grep -l '^license:' */SKILL.md; find */ -maxdepth 1 -iname 'LICENSE*'

# ours, with an add-commit
git -C ~/dotfiles log --diff-filter=A --oneline -- agents/.agents/skills/<name>
```

The 20 `local, hand-written`: flow, learned, docker-agent-command-code,
driving-t3-previews, linking-t3-prs, t3-code, making-skills, feature-compare,
intent-interview, openhilclimb, prem-search, v2-event-loop-orchestration,
decision-ledger, and the seven `ghostex-*`.

Why the ghostex seven are ours: no source note anywhere, no vendored copy on the
host (the Ghostex runtime at `/opt/ghostex` is absent), our own overlay scripts
patch them for this host, and `ghostex-computer-use` carries an authored
decision record (`# CDXC:AgentSkills 2026-09-13 DECISION: User: ...`).

## 2. Unknown after the dig

**0 survived.** Nine were promoted to a real source, each with a check another
person can repeat:

| Skill(s) | Promoted to | Found by |
|---|---|---|
| rust-skills | leonardomso/rust-skills | `LICENSE` (MIT, Leonardo Maldonado) and `README.md` inside the skill dir name the repo |
| workmux, coordinator, merge, rebase, worktree | raine/workmux 0.1.263 | `strings ~/.local/bin/workmux` carries their exact text (the CLI embeds them); `strings … \| grep -oE 'github.com/[A-Za-z0-9_.-]+/workmux'` names the repo |
| web-browsing-cli | only-cli/oc (@only-cli/oc 0.5.8, MIT) | the npm package ships the same SKILL.md; our copy replaces `npx --yes @only-cli/oc@0.5.8` with `oc` |
| rex | Rex CLI installer | SKILL.md says `Installed by "rex skill setup"`; `/usr/bin/rex` contains that string 7× |
| i-have-adhd | ayghri/i-have-adhd | `~/.pi/agent/settings.json` `packages[]` records the git source |

`openhilclimb` stayed local but its evidence improved: it is written from our own
`~/project/OpenHillClimb` (same name, shared `HILL_CLIMBING_RESEARCH.md`).

## 3. Deletion candidates — proposed, nothing deleted

Rule: no upstream AND zero routing/allocation evidence. Checked per name:
`~/.agents/AGENTS.md`, `~/.pi/agent/AGENTS.md`, `~/.commandcode/AGENTS.md`,
`~/AGENTS.md`, `~/dotfiles/AGENTS.md`, `~/.agents/references/*.md`,
`~/.jcode/config.toml`, `~/.bash_history`, every other skill's markdown,
`~/dotfiles/skills-overlay/*.sh`, and the host skill dirs
(`~/.pi/agent/skills`, `~/.claude/skills`, `~/.codex/skills`).

Session transcripts are **not** usable as evidence: the skill index is injected
into every transcript, so every skill name matches. Audit reports (`loop/fix1*`,
`fix4*`, `fix8*`, and `PROVENANCE.md` itself) are excluded for the same reason.
Both exclusions were applied when computing the table below.

| Skill | Would be named by (checked, empty) | Host links |
|---|---|---|
| feature-compare | `skills/flow/SKILL.md` phase table, `skills/ds-help/SKILL.md` | none |
| intent-interview | ambiguity gate in `~/.agents/AGENTS.md` + `~/.pi/agent/AGENTS.md`, `flow/SKILL.md` "Ambiguity gate" | none |
| openhilclimb | `flow/SKILL.md`, `~/.agents/AGENTS.md` | none |
| prem-search | `skills/research/SKILL.md` (no back-pointer), `flow/SKILL.md` | none |
| v2-event-loop-orchestration | `~/.agents/references/memory-subagents.md`, `flow/SKILL.md` | none |
| decision-ledger | `skills/ds-ledger/SKILL.md` (it says "see ds-ledger Mode B"; no back-pointer), `flow/SKILL.md` | none |
| docker-agent-command-code | `flow/SKILL.md`, `~/.agents/AGENTS.md` | `.claude`, `.codex` |
| making-skills | `skills/writing-for-agents/SKILL.md` (no back-pointer), `flow/SKILL.md` | `.pi`, `.claude` |
| t3-code | `flow/SKILL.md`, `~/.agents/AGENTS.md` | `.pi`, `.claude` |

Top 6 have no evidence of use at all (`decision-ledger` landed mid-ticket and is
probably in-flight work — check before deleting it). The last 3 are symlinked
into host dirs, so someone installed them deliberately; flagged because nothing
routes work to them.

Everything else has a real upstream or a local trail: `flow` and `learned` are
named in `~/.agents/AGENTS.md` and `references/memory-flow.md`, the seven
`ghostex-*` are named by our overlays and by each other, the three T3 skills
cross-reference each other.

## 4. README is generated — verdict

`README.md` is written by `write_manifest()` in `~/dotfiles/jcode/update-all.sh`
(its own first line says so), so hand-editing it would be undone by the next
`update-all.sh` run. **PROVENANCE.md is the source of truth; README keeps what
the generator produces.** This ticket did not write README.md.

README is wrong in one direction only. `write_manifest` probes five clones under
`~/.jcode/updater-src` plus babysit, and never reads `.agents/.skill-lock.json`,
so every installer-sourced skill prints as `bundled/manual`:

- 35 README rows name a repo. All 35 agree with PROVENANCE.md — 0 disagreements.
- 93 rows say `bundled/manual`. 73 of them have a real upstream here: 62 from the
  installer ledger, 1 from `pi settings.json` (i-have-adhd), and 10 the
  updater-ledger dig found — workmux, coordinator, merge, rebase, worktree,
  web-browsing-cli, rex, rust-skills, cua-driver, superwhisper. The other 20 are
  ours, so `bundled/manual` is not wrong for them, only mute.

Proposed follow-up, outside this ticket's files: have `write_manifest` consult
`~/.agents/.skill-lock.json` (and the per-skill source in PROVENANCE.md) before
falling back to `bundled/manual`. Until then, README's `bundled/manual` means
"the updater does not track it", not "nobody owns it".

## 5. Verification

```bash
cd ~/.agents/skills
python3 - <<'PY'
import os
disk=set(d for d in os.listdir('.') if os.path.isdir(d))
rows=[[c.strip() for c in l.strip().strip('|').split('|')] for l in open('PROVENANCE.md')]
rows=[r for r in rows if len(r)==6 and r[0] in disk]
print(len(rows), len({r[0] for r in rows}), set(disk)^{r[0] for r in rows})
PY
# -> 128 128 set()
```

- no blank cell in any row, all six columns filled
- classes sum: 108 upstream + 20 local + 0 unknown = 128; the ticketed 126 are
  107 + 19 + 0 = 126
- licence stated for 4 (archify Apache-2.0, i-have-adhd MIT, ponytail MIT,
  rust-skills MIT); the other 124 state none inside the skill, so the column is `—`
- reviewed date 2026-11-13 on every row
- README vs PROVENANCE.md: 0 contradictory rows; 73 rows where README is silent
  and PROVENANCE.md is not, declared in §4 instead of silently conflicting
- `bash ~/dotfiles/jcode/skills-audit.sh` → `AUDIT-TOTAL: 0` (manifest-drift check
  compares skill dirs to README rows; PROVENANCE.md is a file, so it is inert)
