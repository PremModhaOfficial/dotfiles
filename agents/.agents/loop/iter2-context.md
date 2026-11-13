# Iteration 2 — context economy (blind discovery)

Lens: what a fresh agent loads before it has read anything, and what that costs.
No edits made. All numbers recomputed on this machine, 2026-11-13.

Ground truth for "loaded unconditionally" is the system message pi stores in each
session (`message.sections`), not my estimate of what should load. Reuse this:

```bash
python3 -c "
import json,glob,os
f=sorted(glob.glob('/home/prm/.pi/agent/sessions/--home-prm--/*.jsonl'),key=os.path.getmtime)[-1]
s=[json.loads(l)['message']['sections'] for l in open(f) if json.loads(l).get('type')=='message' and json.loads(l)['message'].get('role')=='system'][0]
for k,v in s.items(): print(f'{k:16}{len(v.encode()):7}')
print('TOTAL',sum(len(v.encode()) for v in s.values()))"
```

Current output, and the split this report works from:

```
preamble            126     0.2%
tools              1025     1.9%
rules               677     1.2%
docs               1263     2.3%
project_context    8779    16.0%
skills            40191    73.1%
cwd                  22     0.0%
ponytail           2884     5.2%
TOTAL             54967           (≈13.7k tokens at 4.0 B/token)
```

Method for every byte figure below: that dump, `len(section.encode())`.
Token figures are B/4.0 — same rank order whatever divisor you use, so only
ratios are load-bearing.

---

## 1. The skills catalogue is 73% of everything the agent loads

**`~/.pi/agent/settings.json` (skill roots) → system section `skills`; entries at
`~/.agents/skills/*/SKILL.md` and `~/.pi/agent/skills/*/SKILL.md`**

98 skill entries are serialised into every request before the user says anything:
name, full description, absolute location — 40,191 B of a 54,967 B prompt. It is a
lookup table, and it is the single largest thing a fresh agent pays for.

```bash
python3 -c "
import json,glob,os,re
f=sorted(glob.glob('/home/prm/.pi/agent/sessions/--home-prm--/*.jsonl'),key=os.path.getmtime)[-1]
s=[json.loads(l)['message']['sections'] for l in open(f) if json.loads(l).get('type')=='message' and json.loads(l)['message'].get('role')=='system'][0]
sk=s['skills']; n=re.findall(r'<skill>',sk)
print(len(n),'entries',len(sk.encode()),'B',round(100*len(sk.encode())/sum(len(v.encode()) for v in s.values()),1),'% of prompt')"
```
→ `98 entries 40191 B 73.1 % of prompt`

Number: **40,191 B, 73.1%, 410 B/entry.** Threshold I judge against: a retrieval
index should not exceed 25% of the pre-read prompt. Structural — the list can be
regenerated on demand from `skills/README.md` (already 5,779 B for 130 rows).

## 2. More than half the catalogue is prose in the description field

Same block. Description text is 24,599 B of the 40,191 B; 66 of 98 descriptions are
longer than 200 B, top entries 686 B (`tiger-style`), 571 B (`tiger-style-review`),
527 B (`superwhisper`), 482 B (`tiger-style-audit`), 431 B (`cua-driver`). Selection
needs a trigger phrase, not a paragraph.

```bash
python3 -c "
import json,glob,os,re
f=sorted(glob.glob('/home/prm/.pi/agent/sessions/--home-prm--/*.jsonl'),key=os.path.getmtime)[-1]
s=[json.loads(l)['message']['sections'] for l in open(f) if json.loads(l).get('type')=='message' and json.loads(l)['message'].get('role')=='system'][0]
sk=s['skills'];d=[x.strip() for x in re.findall(r'<description>(.*?)</description>',sk,re.S)]
t=sum(len(x.encode()) for x in d)
print('desc',t,'over200',sum(1 for x in d if len(x.encode())>200),'saved if capped at 200',sum(max(0,len(x.encode())-200) for x in d))"
```
→ `desc 24599 over200 66 saved if capped at 200 6204`

Number: **24,599 B = 61.2% of the block = 44.8% of the whole prompt; a 200-B cap
removes 6,204 B (11.3% of prompt).** Threshold: 200 B per description, one trigger
line plus one scope line. Structural.

## 3. Four packs own 54% of the catalogue

Same block. `ds-*` 29 entries / 11,312 B, `caveman*` 13 / 4,619 B, `tiger-style*`
5 / 3,197 B, `ponytail*` 6 / 2,715 B: 53 of 98 entries, 21,843 B. They are
alternative modes on the same task surface; a session uses at most one per pack.

```bash
python3 -c "
import json,glob,os,re
f=sorted(glob.glob('/home/prm/.pi/agent/sessions/--home-prm--/*.jsonl'),key=os.path.getmtime)[-1]
s=[json.loads(l)['message']['sections'] for l in open(f) if json.loads(l).get('type')=='message' and json.loads(l)['message'].get('role')=='system'][0]
ch=re.findall(r'<skill>.*?</skill>',s['skills'],re.S)
for p in ('ds-','caveman','tiger-style','ponytail'):
    sel=[c for c in ch if re.search(r'<name>(.*?)</name>',c).group(1).startswith(p)]
    print(p,len(sel),sum(len(c.encode()) for c in sel))"
```
→ `ds- 29 11312 / caveman 13 4619 / tiger-style 5 3197 / ponytail 6 2715`

Number: **53/98 entries (54.1%), 21,843 B (54.3% of the block, 39.7% of prompt).**
Threshold: one entry per mode family, variants discovered inside the skill.
Structural, with a real tradeoff — each variant currently self-selects from its
description, so collapsing them costs some routing accuracy on first pick.

## 4. A 3 KB ownership map is loaded as if it were a rule

**`~/AGENTS.md:6-22` (`Who owns what`, 953 B) and `:39-52` (`App-managed — do not edit`, 648 B)**

`/home/prm/AGENTS.md` is loaded unconditionally as context (it is the second
`project_instructions` file, 3,029 B, 5.5% of the prompt). 1,601 B of it — 53% — is
directory ownership and do-not-edit lists: facts you look up once, not constraints
that must fire on every turn.

```bash
python3 -c "
import re;t=open('/home/prm/AGENTS.md').read()
for s in re.split(r'\n(?=## )',t): print(len(s.encode()), s.split(chr(10))[0][:40])"
```
→ `264 / 953 Who owns what / 349 / 358 / 648 App-managed — do not edit / 452`

Number: **1,601 B of 3,029 B (52.9%) is lookup, 2.9% of the prompt.** Threshold:
<25% of a per-request file may be reference material. Structural — it belongs in
`references/memory-harness-home.md` (389 B today, already pointed at from
`.pi/agent/AGENTS.md`).

## 5. The pi rules file is a hand-maintained fork of the canonical one

**`~/.pi/agent/AGENTS.md:1-5` (declares itself the authorised copy) vs `~/.agents/AGENTS.md:1`**

8 canonical lines are rewritten for pi and 22 pi-only lines added; nothing generates
it — `~/.jcode/bin/update-all.sh` never mentions `AGENTS.md` (grep: 0 hits). Two of
the rewrites change the instruction, not the wording: subagents (`harness's own
subagent tool` → `pi has no in-process subagent tool`) and web access (`use the
donsetch MCP tools` → `pi ... has none ... report the denial`). An edit to the
canonical rule is silently a half-edit.

```bash
diff ~/.agents/AGENTS.md ~/.pi/agent/AGENTS.md | grep -c '^[<>]'; grep -c 'AGENTS.md' ~/.jcode/bin/update-all.sh
```
→ `38` then `0`

Number: **38 diff lines (8 removed / 30 added), 0 generator references.** Threshold:
0 lines of a loaded rules file may differ by hand from its stated source. Structural.

## 6. The active-mode block is 2.9 KB of prompt for a formatting preference

**`~/.pi/agent/settings.json` packages (`git:github.com/DietrichGebert/ponytail`) → system section `ponytail`**

2,884 B (5.2%) of every request carries the full ponytail rule set. It is on by
default, so every session pays for it even when the task is a one-line answer.

```bash
python3 -c "
import json,glob,os
f=sorted(glob.glob('/home/prm/.pi/agent/sessions/--home-prm--/*.jsonl'),key=os.path.getmtime)[-1]
s=[json.loads(l)['message']['sections'] for l in open(f) if json.loads(l).get('type')=='message' and json.loads(l)['message'].get('role')=='system'][0]
print(len(s['ponytail'].encode()))"
```
→ `2884`

Number: **2,884 B, 5.2% of prompt, 7.2% of everything loaded outside the skills
block.** Threshold: a persistent mode should cost <1% or be opt-in. Tradeoff — the
mode only works if it is always present, so the fix is a shorter always-on form,
not deletion.

## 7. The harness docs index is charged to every request but read once in a while

**system section `docs`** (written by pi itself from `docs/` under the pi package)

1,263 B listing eight documentation paths, used only when someone asks about pi
itself. Same for `tools` (1,025 B, 1.9%) and `rules` (677 B, 1.2%).

```bash
python3 -c "
import json,glob,os
f=sorted(glob.glob('/home/prm/.pi/agent/sessions/--home-prm--/*.jsonl'),key=os.path.getmtime)[-1]
s=[json.loads(l)['message']['sections'] for l in open(f) if json.loads(l).get('type')=='message' and json.loads(l)['message'].get('role')=='system'][0]
print({k:len(s[k].encode()) for k in ('docs','tools','rules','preamble')})"
```
→ `{'docs': 1263, 'tools': 1025, 'rules': 677, 'preamble': 126}`

Number: **3,091 B, 5.6% of prompt** for harness self-description. Tradeoff — not
editable here (it comes from the installed pi build), and the docs list is what
stops an agent guessing at pi APIs. Report only.

## 8. 353 B per request describes commands this harness cannot invoke

**`~/.pi/agent/AGENTS.md:74-79` (`## EGM (Elephant & Goldfish Model)`)**

Names `/skill:egm-*` and a bundle root. `egm` appears 0 times in the 98-entry skills
block, so those commands have no model-visible surface; the bundle exists
(`~/.pi/agent/git/github.com/google/elephant-goldfish-model/skills`, 7 dirs) but is
not in the catalogue.

```bash
grep -c egm /dev/stdin <<<"$(python3 -c "
import json,glob,os
f=sorted(glob.glob('/home/prm/.pi/agent/sessions/--home-prm--/*.jsonl'),key=os.path.getmtime)[-1]
print([json.loads(l)['message']['sections'] for l in open(f) if json.loads(l).get('type')=='message' and json.loads(l)['message'].get('role')=='system'][0]['skills'])")"
```
→ `0`

Number: **353 B, 0.64% of prompt, 6.4% of the pi rules file — 0 catalogue hits.**
Threshold: a rules section must map to at least one invocable entry. Structural
(delete the 6 lines, or register the bundle as skills).

## 9. A quarter of the documented skills cannot be selected by the model

**`~/.agents/skills/README.md:6` (header `| Skill | Source | Source commit |`)**

32 of 128 installed `SKILL.md` files carry `disable-model-invocation: true` and are
absent from the catalogue; the README that `/home/prm/AGENTS.md:27` tells agents to
read lists all 130 rows identically, with no column saying which are slash-only. An
agent reading the documented inventory will plan around 32 skills it cannot call.

```bash
grep -l 'disable-model-invocation: true' ~/.agents/skills/*/SKILL.md | wc -l; grep -c '^|' ~/.agents/skills/README.md
```
→ `32` then `130`

Number: **32/128 = 25% invisible; README has 3 columns, none of them invocability.**
Threshold: 0 undocumented visibility gaps. Structural (one column, or one list).

## 10. 752 KB of skill tree for a runtime that is not installed

**`~/.agents/skills/ghostex-*/SKILL.md` (7 dirs)**

Every ghostex body opens with "**Availability gate:** inert on this host ... the
Ghostex runtime at `/opt/ghostex` ... is missing". `/opt/ghostex` does not exist. The
skills are also model-invoked-off, so they cost 0 prompt bytes and exist only as
disk, maintenance and a trap for a reader who finds them by name.

```bash
du -sb ~/.agents/skills/ghostex-* | awk '{s+=$1}END{print s, "bytes"}'; ls /opt/ghostex 2>&1
```
→ `752580 bytes` then `ls: cannot access '/opt/ghostex': No such file or directory`

Number: **752,580 B, 2.0% of the 37.3 MB skills tree, 0 prompt bytes.** Threshold:
0 skills for a runtime that is absent. Structural.

## 11. The loop's own scratch space is 99% backup tarballs, inside the dotfiles repo

**`~/.agents/loop/fix{1,1-rev2,2}-backup-skills.tar.gz`**

61,237,149 B across 90 files, 91 of them tracked by git in
`dotfiles/agents/.agents/loop`; three pre-fix tarballs are 60,721,184 B of that. The
directory grows every iteration (58 entries added this round) and nothing loads it.

```bash
du -sb ~/.agents/loop | cut -f1; git -C ~/dotfiles ls-files agents/.agents/loop | wc -l; du -cb ~/.agents/loop/*backup-skills.tar.gz | tail -1
```
→ `61237149` / `91` / `60721184`

Number: **99.2% of the loop dir is 3 tarballs; 91 tracked files.** Threshold: a
report directory under 1 MB. Structural (gitignore the tarballs; the reports are 516 KB).

## 12. Two files nothing reads

**`~/.agents/free.yaml:1` (833 B) and `~/.agents/skills/PROVENANCE.md:1` (29,828 B)**

`free.yaml` is a docker-agent agent definition; grep over `~/.agents`,
`dotfiles/skills-overlay` and `~/.jcode/bin` finds 0 references. `PROVENANCE.md` sits
in the regenerated skills tree with 0 references from any loaded or pointing file —
the README is the documented index, not this.

```bash
grep -rl 'free.yaml' ~/.agents ~/dotfiles/skills-overlay ~/.jcode/bin | wc -l; grep -rl 'PROVENANCE.md' ~/.agents ~/dotfiles/skills-overlay ~/.jcode/bin | wc -l
```
→ `0` then `0`

Number: **30,661 B, 2 references total, 0 per-request bytes.** Threshold: 0
unreferenced files at the two roots an agent reads first. Structural.

---

## Checked and clean (so the next iteration does not re-litigate)

- `~/.agents/references/` — 7 files, 4,393 B, all pointed at from a loaded file,
  0 verbatim lines duplicated in `AGENTS.md`. Correctly on-demand.
- `.commandcode/skills` — 200 entries, 83 symlinks: matches `~/AGENTS.md:19`. The
  "83" is not stale.
- "126 `SKILL.md` files" (`~/AGENTS.md:27`) is accurate for real dirs
  (`find -maxdepth 2` → 126); 128 counting the 2 symlinked skill dirs
  (`cua-driver`, `superwhisper`).
- `.pi/agent/skills` — 34 entries, 34 symlinks into `.agents/skills`; 21 of them are
  the loaded copy of a skill whose real path is `.agents/skills`. No duplicate names
  reach the catalogue, so no duplicate prompt bytes.
- Skill descriptions do not restate their own bodies: 0 verbatim sentence matches
  across 98 skills (first-60-char test). Description length is the problem (#2), not
  duplication.
