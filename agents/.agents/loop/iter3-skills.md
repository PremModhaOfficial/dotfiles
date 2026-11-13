# Round 3 — skills as programs

Blind discovery. Lens: does a skill still work when obeyed, judged only by what a
command can disprove.

**Coverage.** All 162 `SKILL.md` files scanned mechanically (128 in `~/.agents/skills`,
34 symlinks in `~/.pi/agent/skills`) for: first-token command existence
(`command -v`), absolute and skill-relative path existence, subcommand existence
against each binary's own `--help`/`help`, skill cross-references, MCP tool names
against `~/.pi/agent/mcp.json`, and shipped scripts (syntax + execution + claimed
exit codes). ~55 skills were then opened or had their documented commands actually
run. 30 overlay scripts in `~/dotfiles/skills-overlay/` were executed twice each
against a `/tmp` copy of the skills tree.

**13 defects.** Nothing was edited.

---

## Family: activation (caveman / ponytail / tiger-style / ds / brag)

### 1. 26 skills are activated by a bare `/name` that pi never registers — `caveman-help/SKILL.md:5` and 25 others

Claim: `Trigger: /caveman-help or "caveman help".` `~/…/ponytail-help/SKILL.md:73-74`
says the only reliable level switch is `/ponytail lite`; `tiger-style-help/SKILL.md:73-74`
says `Pass the level as an argument — this is the only mechanism a plain skill
install reads: /tiger-style lite`.

Disproof:

```bash
rg -l '`/[a-z][a-z0-9-]*`' -g '*/SKILL.md' ~/.agents/skills ~/.pi/agent/skills | wc -l   # 26
rg -rn "registerCommand\('caveman|registerCommand\('ponytail|registerCommand\('tiger" ~/.pi/agent/extensions  # nothing
rg -n "registerCommand" ~/.pi/agent/extensions/*.ts | head    # only 'orca-model'
sed -n '45;53p' /home/prm/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent/docs/skills.md
#   → a skill is forced with /skill:name; /name alone is not a command
```

What an agent does wrong: tells the user "type `/tiger-style strict`" or
`/ponytail lite`; pi rejects the line as an unknown command, and the level never
changes. The correct form is `/skill:tiger-style`, which these cards never name.
`tiger-style-help` states the switch is "the only mechanism a plain skill install
reads" and then gives the one form pi cannot execute.

### 2. `caveman-help/SKILL.md:45,50` — the documented "highest priority" way to set the default mode is read by nothing

Claim: ``**Environment variable** (highest priority): export CAVEMAN_DEFAULT_MODE=ultracave``
and ``**Config file** (`~/.config/caveman/config.json`): { "defaultMode": "ultracave" }``,
with `Resolution: env var > repo config > user config > caveman`.

Disproof:

```bash
rg -a -l 'CAVEMAN_DEFAULT_MODE' /home/prm/.npm-global/lib/node_modules/@caveman-ai   # no files
test -e ~/.config/caveman/config.json && echo exists || echo MISSING                  # MISSING
ls ~/.caveman                                                                          # bin caveman.db mem reports — no config.json
rg -a -o '.{0,40}caveman/config\.json.{0,40}' .../@caveman-ai/cli/dist/index.js        # only ./.caveman/config.json (project)
```

What an agent does wrong: exports the variable or writes the JSON, then reports the
default mode changed. The installed CLI reads only a project `./.caveman/config.json`;
the env var exists only in the upstream repo and its tests. Compare
`tiger-style-help/SKILL.md:78-80`, which now carries the correct caveat ("read only
when the … hooks are installed") — the caveman card did not get it.

Same shape, weaker proof: `ponytail-help/SKILL.md:53,58` (`PONYTAIL_DEFAULT_MODE`,
`~/.config/ponytail/config.json`). `PONYTAIL_DEFAULT_MODE` appears only in the vendored
clone `~/.pi/agent/git/github.com/DietrichGebert/ponytail/` and its tests, in no
installed component; `~/.config/ponytail` does not exist.

### 3. `caveman-compress/SKILL.md:29` — the documented command only runs from inside the skill directory

Claim: `python3 -m scripts <absolute_filepath>` ("The compression scripts live in
`scripts/` (adjacent to this SKILL.md)").

Disproof:

```bash
cd /tmp && python3 -m scripts --help     # /usr/bin/python3: No module named scripts
cd ~/.agents/skills/caveman-compress && python3 -m scripts --help   # works
```

What an agent does wrong: runs the line from the user's project (the normal cwd),
gets `No module named scripts`, and either improvises a compression by hand — the
exact failure the skill's own "never improvise" rule at line 21 guards — or reports
the tool broken.

---

## Family: web and MCP tools

### 4. `web-browsing-cli/SKILL.md:37` — five of the 29 listed `oc` sites do not exist

Claim: `Sites: hn, reddit, gh, x, linkedin, ddg, bing, so, yahoo, yt, aws, gcp, learn,
wiki, py, mdn, node, ruby, go, rust, java, php, cpp, ts, npm, pip, cargo, gem, docker.`
followed by "`oc sites` lists every site".

Disproof:

```bash
oc npm search express     # oc: unknown command 'npm', run oc --help
for s in npm pip cargo gem docker; do oc $s search x; done   # all five: unknown command
oc sites | wc -l          # 24 sites; npm/pip/cargo/gem/docker are not among them
```

What an agent does wrong: reaches for `oc cargo doc serde` or `oc pip library json`
as the skill invites, gets a usage error instead of a page, and burns a turn per
guess. The skill even tells it "prefer a shortcut over a hand-built URL" — the
shortcut does not exist for those five registries.

### 5. `feature-compare/SKILL.md:18` — names an MCP tool in the wrong case and a `ToolSearch` tool pi does not have

Claim: `load only `mcp__DeepWiki__ask_wiki_question` via ToolSearch (`select:`)`.

Disproof:

```bash
jq -r '.mcpServers|keys[]' ~/.pi/agent/mcp.json    # deepwiki, superlogical
# the registered tool is mcp__deepwiki__ask_wiki_question (lowercase server key)
rg -n 'ToolSearch' /home/prm/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent/docs/*.md  # nothing
```

What an agent does wrong: searches for `mcp__DeepWiki__…` and a `ToolSearch` tool,
finds neither, and concludes DeepWiki is unavailable — falling back to weaker
sources for a skill whose whole method is source-order. (Round 2 found the same
class in `memory-code-lookup.md`; the fix did not reach this file.)

---

## Family: video / voice / desktop integrations

### 6. `brag/SKILL.md:114` — Step 3 hands off to four skills that are not loadable in pi

Claim: `**Read:** The Hyperframes skills — `hyperframes` (contract, references/format.md,
references/motion.md, references/look.md), `hyperframes-cli`, `hyperframes-registry`,
and `media-use` for audio.`

Disproof:

```bash
for s in hyperframes hyperframes-cli hyperframes-registry media-use; do
  test -d ~/.agents/skills/$s || test -d ~/.pi/agent/skills/$s || echo "not in pi: $s"; done
# all four absent from both pi skill dirs; they exist only under ~/.claude/skills/
sed -n '61p' …/pi-coding-agent/docs/skills.md   # pi discovers ~/.agents/skills and ~/.pi/agent/skills
```

What an agent does wrong: `brag` has no availability gate, so it proceeds to Step 3,
cannot load any of the four contracts, and either stops mid-workflow or invents the
composition rules that `hyperframes` (`references/look.md`) was supposed to supply —
while the gate at line 122 (`npx hyperframes check`) may then reject the output.

### 7. `superwhisper/SKILL.md:179-181` — the panel block depends on a binary that is not installed

Claim: ``omarchy-shell superwhisper open`` / ``omarchy-shell superwhisper page language`` /
``omarchy-shell superwhisper refresh``.

Disproof:

```bash
command -v omarchy-shell          # nothing (exit 1)
superwhisper page                 # Error: "Unknown command page; run superwhisper help for the list"
superwhisper settings             # works — the plain CLI path the same card documents
```

What an agent does wrong: asked to "open the Superwhisper panel and switch the
language", it runs `omarchy-shell` and gets `command not found`, then retries the
second line and gets a second error, instead of using `superwhisper settings` /
`general set` which do work here.

### 8. `ghostex-browser-use/SKILL.md:169` — "macOS notes verified on this machine" on an Arch Linux host

Claim: heading `## macOS notes verified on this machine`, whose body names
`/Applications/Google Chrome.app/…`, `/usr/bin/codesign` and `/usr/bin/xattr`.

Disproof:

```bash
. /etc/os-release; echo "$PRETTY_NAME"      # Arch Linux
uname -s                                     # Linux
command -v codesign xattr                    # nothing
ls /Applications                             # No such file or directory
```

What an agent does wrong: treats the section as machine-verified rather than
conditional, tries `codesign --verify --strict` or a `/Applications/...` path when
the browser launch misbehaves, and reports those failures as product bugs. The same
file's availability gate at line 7 is accurate; only this heading overclaims.

---

## Family: review / skill machinery

### 9. `~/dotfiles/skills-overlay/tiger-style-review.sh:36` — a patch that cannot find its anchor exits 0 and still marks the skill patched

Claim (script header, line 8): `Idempotent: a patch is skipped when its new text is
already present.` Claim (line 12): `Touches only $SKILL_DIR/SKILL.md, then
$SKILL_DIR/.overlay-applied.` The sibling `ponytail.sh` refuses with a non-zero exit
when its block has drifted.

Disproof:

```bash
cp -a ~/.agents/skills/tiger-style-review /tmp/t
SKILL_DIR=/tmp/t bash ~/dotfiles/skills-overlay/tiger-style-review.sh; echo "rc=$?"
#  OVERLAY-WARN: tiger-style-review: anchor not found: ✅ `L152: naming: to (ms? bytes?). ...
#  rc=0        ← and /tmp/t/.overlay-applied is written
```

The cause is order: patch 1 anchors `…L152…\n\n## Scoring`, patch 2 inserts a second
section before `## Scoring`, so patch 1's `new` text never matches again and its
`anchor not found` branch (`sys.exit(0)`) reports success forever.

What an agent (or `update-all.sh`) does wrong: `apply_overlays()` treats exit 0 as
applied, so a future upstream sync that drops the "Comment voice"/"Not this one"
sections is recorded as patched while the review card silently loses them. Every
`update-all` run also logs a warning that is now permanent noise.

### 10. `decision-ledger/SKILL.md:7`, `grill-me/SKILL.md:7`, `grill-with-docs/SKILL.md:7` — instruct a call to a tool pi does not have

Claim: `Call the Skill tool with "ds-ledger" and use Mode B.` / `Call the Skill tool
with "grilling".` / `Call the Skill tool twice, for "grilling" and "domain-modeling".`

Disproof:

```bash
rg -l 'registerTool' ~/.pi/agent/extensions/*.ts   # nothing — no tool registers a "Skill" tool
sed -n '45;53p' …/docs/skills.md                   # pi loads skills by reading SKILL.md, /skill:name
```

What an agent does wrong: the three cards carry `disable-model-invocation: true`, so
they load only when a human forces them; the model then has no `Skill` tool to call
and must guess that the intent is "read the other SKILL.md". On the path where it
does not guess, a `/skill:decision-ledger` turn ends with an apology instead of
`ds-ledger` Mode B. (`coordinator/SKILL.md:4` has the same problem in its
`allowed-tools: Bash, Write, Read, Task` line.)

---

## Family: peripheral packs (rust-skills, paperclip)

### 11. `rust-skills/SKILL.md:18` — three different Rust versions in one skill

Claim: `Current for Rust 1.96 (2024 edition)`.

Disproof:

```bash
rustc --version                                    # rustc 1.99.0 (b940084d7 2026-09-28)
cat ~/.agents/skills/rust-skills/checks/rust-toolchain.toml | rg channel   # channel = "1.95.0"
sed -n '3p' ~/.agents/skills/rust-skills/checks/check.sh                   # "-> Rust 1.95.0"
```

What an agent does wrong: writes or blesses 1.96-only idioms while the skill's own
gate compiles them under 1.95.0, so `bash checks/check.sh` fails on examples the
skill just taught — or the reverse, it avoids stable 1.96+ APIs believing the
toolchain is behind. The skill's validator (265 rules / 26 categories) is accurate
and passes: `bash checks/check.sh` → `OK: 265 rules valid`, `rc=0`.

### 12. `paperclip/SKILL.md:564` — points at a companion skill that is not installed

Claim: `**Hiring**: use the `paperclip-create-agent` skill for new agent creation workflows`.

Disproof:

```bash
ls -d ~/.agents/skills/paperclip-create-agent ~/.pi/agent/skills/paperclip-create-agent  # No such file or directory
```

What an agent does wrong: on a hiring/escalation task inside a heartbeat it looks for
a skill it cannot load, and either stalls until the heartbeat budget ends or invents
the agent-creation workflow the missing skill was meant to pin down (`Coder`, `QA`
templates). This is the only pi-side skill with no `~/.agents` twin, so nothing in
the updater will ever supply the missing companion.

---

## Checked and held up (so the next round does not re-run them)

- `bash ~/.agents/skills/rust-skills/checks/check.sh` → all gates pass, `rc=0`,
  265 rules / 26 categories / 823 examples / 124 baseline suspects.
- `bash ~/.agents/skills/flow/scripts/check.sh` → `OK`, `rc=0`; `rules.md` has 2
  formatted rows, cap 15.
- `hc run --bg --name <n> pi` then `hc ls` / `hc read` / `hc kill` → works from a
  plain hc terminal (`HERDR_ENV` unset); the delegation ladder in `flow` and
  `AGENTS.md` is sound.
- All 30 overlay scripts: `bash -n` clean, second run changes nothing. `cavecrew.sh`
  needs `CLONE`, which `update-all.sh:436` supplies.
- All 19 shipped `.py`/`.sh` files parse; `ds-watch-pr`, `ds-ledger`,
  `caveman-compress`, `wizard/template.sh` run and exit as documented.
- Every `$skill` cross-reference resolves except the EGM bundle; every skill-relative
  `scripts/`, `references/`, `schemas/`, `agents/` path exists (archify's schema
  table really does say `.json`).
- `cua-driver 0.35.4`, `bd version 1.3.4`, `paperclipai 2026.1106.0`, `skills 1.8.1`,
  `npx hyperframes` on npm, `/opt/ghostex` absent — all four availability gates
  (`ai-image-generation`, `ghostex-*`) match the machine.
- `herdr`, `workmux`, `bd`, `oc`, `git`, `gh`, `superwhisper` subcommands named in
  fences all resolve against their own `--help`.

## Overlap with round 2 (not re-counted above)

Round 2 already reported, and `iter3` confirms still true: `cavecrew` +
`coordinator` requiring a `Task`/`Explore` subagent tool
(`cavecrew/SKILL.md:9,67` — no installed extension calls `registerTool`);
`/flow` and `/skill:egm-*` not being pi commands; `memory-code-lookup.md`'s hidden
deepwiki tool. My discovery was blind, so these three surfaced independently;
they are listed here rather than re-reported as new.
