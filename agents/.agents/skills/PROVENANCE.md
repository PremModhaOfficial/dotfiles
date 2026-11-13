# Skill provenance

Source of truth for where each installed skill came from, who to
update it from, and when it was last reviewed. `README.md` in this directory is
**generated** by `~/.jcode/bin/update-all.sh` (`write_manifest`) and must not be
hand-edited; this file is the record it is measured against.

Reviewed 2026-11-13, and every row re-checked that day. The ticket that created
this file counted 126 installed skills; the tree held 128 by the end of it
(caveman-review and decision-ledger landed during the work), so all 128 are
recorded here. The 126 the ticket named are all present, once each.

## Classes

| Class | Count | Evidence used |
|---|---|---|
| upstream (named repo or install path) | 108 | see the Evidence column |
| local, hand-written (ours) | 20 | git log in `~/dotfiles`, or absence of any source note after the dig below |
| unknown | 0 | - |

Commands behind each class (run from `~/.agents/skills`):

- install ledger of the skill installer (68 of the 126):
  `python3 -c "import json;d=json.load(open('/home/prm/.agents/.skill-lock.json'))['skills'];print(len(d))"`
  Each entry carries `source`, `sourceUrl`, `skillPath`, `installedAt`.
- updater ledger, written by `stamp_source` at sync time (34 skills):
  `cat ~/.jcode/state/upstream-sources`
- symlink installs by vendor apps (2):
  `find . -maxdepth 1 -type l -exec readlink {} \;`
- repo named in the skill text:
  `grep -ohiE 'https?://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' */SKILL.md | sort -u`
- tool that ships its own skills, proved by the binary carrying the text:
  `strings $(command -v workmux) | grep -c 'Rebase the current branch with smart conflict'`
- npm package carrying the same text:
  `diff web-browsing-cli/SKILL.md ~/.npm-global/lib/node_modules/@only-cli/oc/skills/web-browsing-cli/SKILL.md`
- licence stated in frontmatter or a LICENSE file:
  `grep -l 'license:' */SKILL.md; find */ -maxdepth 1 -iname 'LICENSE*'`
- local: `git -C ~/dotfiles log --diff-filter=A --oneline -- agents/.agents/skills/<name>`

## The dig for `unknown`

Every skill that failed all of the checks above got one dig: git add-commit in
`~/dotfiles`, a source note inside the skill dir, a licence/NOTICE file, the
`update-all.sh` manifest, the host dirs that symlink skills, and the binaries
of the tools the skill documents. Nine were promoted to a real source:

| Skill(s) | Promoted to | Found by |
|---|---|---|
| rust-skills | leonardomso/rust-skills | `LICENSE` + `README.md` inside the skill dir name the repo |
| i-have-adhd | ayghri/i-have-adhd | `~/.pi/agent/settings.json` `packages[]` records it as a git source |
| workmux, coordinator, merge, rebase, worktree | raine/workmux 0.1.263 | the workmux binary at `~/.local/bin/workmux` carries their exact text |
| web-browsing-cli | only-cli/oc (@only-cli/oc 0.5.8) | the npm package ships the same SKILL.md; our copy swaps `npx` calls for `oc` |
| rex | Rex CLI installer | in-skill note `Installed by "rex skill setup"`, and `/usr/bin/rex` contains it |

Nothing survived as `unknown`. The counts add up as 68 installer-ledger + 35
updater-ledger - 6 in both = 97, + 9 from the dig above + 2 vendor symlinks =
108 upstream; then 20 ours, of which 12 carry a git add-commit in `~/dotfiles`
and 8 carry no commit but a decision record or an in-skill provenance trail
(see the Evidence column).

## README status

`README.md` is generated, so it keeps what the generator produces. It is wrong
in one direction only: `write_manifest` probes just the five clones under
`~/.jcode/updater-src` (plus babysit) and never reads
`~/.agents/.skill-lock.json`, so every installer-sourced skill prints as
`bundled/manual`. That is 73 rows here with a real upstream, of the 93 README
still labels that way. Where README does name a repo, it agrees with this file:
35 rows, 0 disagreements
(`grep '^| ' README.md | grep -v 'bundled/manual'`).

The 73 are exactly the rows whose Evidence is `skill-lock.json...` or `pi
settings.json...`, plus these 10: workmux, coordinator, merge, rebase, worktree,
web-browsing-cli, rex, rust-skills, cua-driver, superwhisper. Fixing README means teaching
`write_manifest` to read the installer ledger; that is a one-block change to
`~/dotfiles/jcode/update-all.sh`, outside this ticket.

Deletion candidates (no source, no evidence of use) are in
`~/.agents/loop/fix5-report.md`. Nothing was deleted.

## Table

| Skill | Source | Licence | Evidence | Reviewed | What it does for us |
|---|---|---|---|---|---|
| ai-image-generation | 101-skills/superpowers | — | skill-lock.json (installed 2026-10-15) | 2026-11-13 | Generate AI images with GPT-Image-2, FLUX, Gemini, Grok, Seedream and 50+ models via inference.sh: text-to-image, i… |
| archify | tt-a1i/archify | Apache-2.0 | skill-lock.json (installed 2026-10-21) | 2026-11-13 | Create validated architecture, workflow, sequence, data-flow, ERD, class, tree and timeline diagrams as standalone… |
| ask-matt | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Ask which skill or flow fits your situation. |
| axi | kunchenguid/axi | — | skill-lock.json (installed 2026-11-08) | 2026-11-13 | > Agent eXperience Interface (AXI) — ergonomic standards for building CLI tools that agents use via shell execution. |
| babysit | a5c-ai/babysitter | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | Execute via @babysitter. |
| brag | latent-spaces/brag | — | skill-lock.json (installed 2026-11-12) | 2026-11-13 | Turn the current project website into a short, polished, shareable launch video using Hyperframes. |
| cavecrew | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > When to delegate to `cavecrew-investigator` (locate code), `cavecrew-builder` (1-2 file edit) or `cavecrew-review… |
| caveman | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Terse caveman voice: answer first, fluff gone, every technical fact kept. |
| caveman-commit | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Write a Conventional Commits message compressed to intent only. |
| caveman-compress | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Compress a memory file such as CLAUDE.md or a todo list into caveman format to save input tokens, keeping a reada… |
| caveman-discover | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Find and label every LLM workflow in the repository so Caveman Cloud groups spend by workflow instead of one bucket. |
| caveman-evidence-review | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Read-only review of Caveman Cloud evidence: cost, Cave Score, workflows, traces, latency, errors, routing, savings. |
| caveman-explore | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | Read-only repository explorer for cold-start orientation, broad cross-file localization, or when a direct search fa… |
| caveman-help | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Quick-reference card for the three caveman skills and their commands. |
| caveman-learn | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | Act on a Caveman learn report - review the ranked token sinks, apply cost-lowering fixes with per-edit consent, and… |
| caveman-manage | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Inspect Caveman Cloud's experiment lifecycle and block unsafe execution. |
| caveman-optimize | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Turn a Caveman optimization observation into an operator-chosen candidate with a paired baseline evaluation. |
| caveman-review | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Compressed code review - one line per finding with location, problem and fix. |
| caveman-setup | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Wire a repository through the Caveman Cloud gateway so every LLM request is measured, with no behavior change. |
| caveman-stats | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Show recorded output and cache-read token usage and mode attribution for the current Claude Code session, or loca… |
| chief-of-staff | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Pursue a long-running goal in a single session by co-ordinating subagents. |
| code-review | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Review changes since a commit, branch, tag or merge-base on two axes: Standards (does the code follow this repo's d… |
| codebase-design | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Shared vocabulary for designing deep modules. |
| coordinator | raine/workmux (shipped inside the workmux CLI) | — | text embedded in workmux 0.1.263 binary | 2026-11-13 | Orchestrate multiple worktree agents. |
| cua-driver | cua.ai / cua-driver app (vendor install, symlink) | — | symlink into ~/.cua-driver/skills (app installer) | 2026-11-13 | Drive a native GUI app (macOS, Windows, Linux) via the cua-driver CLI (default) or MCP server; snapshot its accessi… |
| decision-ledger | local, hand-written | — | no source note; added to dotfiles in a75c837 | 2026-11-13 | Audit a component's decision points; see ds-ledger Mode B. |
| diagnosing-bugs | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Diagnosis loop for hard bugs and performance regressions. |
| docker-agent-command-code | local, hand-written | — | no source note; absent from the docker-agent upstream tree | 2026-11-13 | Run the Command Code CLI (`cmd`) as a docker-agent harness — the wiring is upstream, so use your docker-agent build… |
| domain-modeling | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Build and sharpen a project's domain model. |
| driving-t3-previews | local, hand-written | — | no source note; added to dotfiles in 0c6469d | 2026-11-13 | Drive T3 Code's shared browser preview. |
| ds-adopt | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Takes over an existing PR, branch or agent thread and finishes its original goal while keeping credit for the first… |
| ds-best-of-n | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Run N independent attempts at the same task in parallel, pick the strongest as the base, and graft the best parts o… |
| ds-blast-radius | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Find what a change could break outside its own diff, then prove the key safety fact by running real code. |
| ds-blueprint | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Design the types, function signatures and module layout first, agree on that shape, then implement against it. |
| ds-catchup | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Give the user a short plain-language catch-up on what changed since their last message, followed by every decision… |
| ds-context-reset | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Keep a PROGRESS.md for long tasks and move to a fresh session or subagent that reads only it when context gets long… |
| ds-design | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Builds a frontend with a clear visual direction instead of the generic AI look. |
| ds-design-audit | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Reviews an existing UI with scores based on evidence, then fixes the highest-impact problems. |
| ds-explain | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Explain how a piece of code works, why it is built that way, and what that means, in plain language a person can fo… |
| ds-help | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Pick the right deepseek-stack skill for a task and explain how the pack fits together. |
| ds-jury | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Gets independent reviews of a change from two or three different models or providers and loops on fixes until they… |
| ds-ledger | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Keep a one-row-per-decision ledger for long or unattended runs, or audit the decision points of a setup, config, de… |
| ds-lessons | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Find mistakes agents keep repeating in this repo and turn each into structure that blocks it, preferring types over… |
| ds-mode | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Always-on working style for DeepSeek agents: restate the task, read before editing, small verified steps, evidence… |
| ds-plan-loop | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Write a numbered plan with an acceptance check for each step, critique it once in a fresh pass, revise it, then exe… |
| ds-pr | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Files a short, clear pull request for the current branch: stage the leftover work, push, and write the body a revie… |
| ds-pr-comments | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Formats and posts GitHub comments written by an agent on the user's behalf, with clear attribution and no leaked se… |
| ds-principles | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Compact engineering principles for design, debugging, verification, and delegation, each with a trigger. |
| ds-ready | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Runs the full ds-ship workflow but stops with the pull request ready for a human to merge, and never merges. |
| ds-review-loop | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Runs an author and a fresh-context reviewer in a loop on the current change until both agree it is correct, for at… |
| ds-revive | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Brings an old PR up to date by checking if its idea still fits the current code, then rebasing, reworking or recomm… |
| ds-sharpen | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Restate the user's goal, make the task deeper rather than bigger, rewrite the prompt, and optionally attack the pla… |
| ds-ship | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Takes a change all the way from code to a merged pull request without supervision: build it, prove it, review it, f… |
| ds-swarm | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Fan out N parallel workers on slices of a job or on a race, collect every result, and return one evidence-backed re… |
| ds-tdd | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Fix a bug by first writing a focused test that fails for the right reason, then making the smallest change that mak… |
| ds-unslop | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Remove AI writing tells from prose and code comments, then rewrite in plain, specific English. |
| ds-unstick | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Break out of a repeating failure: name the assumption behind all the failed fixes, test it directly, list three oth… |
| ds-verify-loop | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Run edit, real check, read the actual error, fix the root cause, rerun, until the check passes or the cap is hit. |
| ds-watch-pr | aicodeking/deepseek-stack | — | skill-lock.json (installed 2026-11-03) | 2026-11-13 | Watches a pull request through CI and review, fixes real findings and stops when it is ready, merged or blocked. |
| feature-compare | local, hand-written | — | no source note; added to dotfiles in b93f234 | 2026-11-13 | Build a feature-parity table across two or more products of any kind, from DeepWiki for open-source repos and offic… |
| find-skills | vercel-labs/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Helps users discover and install agent skills when they ask questions like how do I do X, find a skill for X, is th… |
| flow | local, hand-written | — | no source note; routes only skills installed here | 2026-11-13 | Order of operations for real repository work on this machine: locate, plan, build, review, ship, each phase naming… |
| ghostex-agents | local, hand-written | — | no source note; in-skill decision record + our overlay | 2026-11-13 | Launch, message, wait on and close Claude, Codex or other agents in Ghostex sessions, and read or search another se… |
| ghostex-browser-use | local, hand-written | — | no source note; in-skill decision record + our overlay | 2026-11-13 | >- Use this skill when an agent needs to inspect or automate web content in Chrome, Chromium, Edge, or a supported… |
| ghostex-cli | local, hand-written | — | no source note; in-skill decision record + our overlay | 2026-11-13 | Use for anything involving Ghostex or the `ghostex`/`gx` CLI: projects, workspaces, panes, sessions, agent orchestr… |
| ghostex-computer-use | local, hand-written | — | no source note; added to dotfiles in d63f4de | 2026-11-13 | >- Use only when the user names Ghostex or its Trycua/cua-driver wrapper. |
| ghostex-help | local, hand-written | — | no source note; in-skill decision record + our overlay | 2026-11-13 | Answer how Ghostex works: what a feature, view, button or setting does, how to do something in it, or change the ap… |
| ghostex-manage-beads | local, hand-written | — | no source note; in-skill decision record + our overlay | 2026-11-13 | Work a Ghostex project board bead or card by id through the `bd` CLI: create, update, comment, review, close, link… |
| ghostex-visuals | local, hand-written | — | no source note; in-skill decision record + our overlay | 2026-11-13 | Show charts, stat tiles, tables and text layouts inline in the Ghostex chat, ask questions as a form, and publish s… |
| grill-me | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | A relentless interview to sharpen a plan or design. |
| grill-with-docs | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go. |
| grilling | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Grill the user relentlessly about a plan, decision, or idea. |
| handoff | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Compact the current conversation into a handoff document for another agent to pick up. |
| herdr | herdrdev/herdr | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | Control Herdr, a terminal multiplexer for coding agents. |
| i-have-adhd | ayghri/i-have-adhd | MIT | pi settings.json packages[] names the git source | 2026-11-13 | 'Shape output for a reader with ADHD: lead with the next action, number multi-step work, restate state across turns… |
| implement | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Implement a piece of work based on a spec or set of tickets. |
| implement-spec | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Implement the result of /to-spec and /to-tickets in code. |
| improve-codebase-architecture | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one… |
| intent-interview | local, hand-written | — | no source note; added to dotfiles in 047247c | 2026-11-13 | Extract the real outcome from a vague ask before any work. |
| investigate-first | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | Diagnose ambiguous failures before editing. |
| lean-build | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | Build feature work with high overbuilding risk. |
| learned | local, hand-written | — | no source note; added to dotfiles in 13364ea | 2026-11-13 | The dag/stagehand PR-pipeline playbook. |
| linking-t3-prs | local, hand-written | — | no source note; added to dotfiles in 0c6469d | 2026-11-13 | Link and watch pull requests from T3 Code. |
| loop-me | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Grill me about specs for the workflows I want to build, within this workspace. |
| making-skills | local, hand-written | — | no source note; added to dotfiles in 0c6469d | 2026-11-13 | Write, review, and shrink agent skills (SKILL.md). |
| megacave | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Caveman in Classical Chinese: 文言文 register, far fewer characters, technical terms verbatim. |
| merge | raine/workmux (shipped inside the workmux CLI) | — | text embedded in workmux 0.1.263 binary | 2026-11-13 | Commit, rebase, and merge the current branch. |
| migration | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | Implement reversible compatibility-safe transitions. |
| openhilclimb | local, hand-written | — | no source note; written from our own ~/project/OpenHillClimb | 2026-11-13 | Eval-driven hill climbing for AI agents. |
| ponytail | DietrichGebert/ponytail | MIT | skill-lock.json + upstream-sources ledger | 2026-11-13 | > Lazy senior dev mode: the smallest change that fully solves the task, and a reply a busy human understands in one… |
| ponytail-audit | DietrichGebert/ponytail | — | skill-lock.json + upstream-sources ledger | 2026-11-13 | > Quality audit of a whole repo: bugs, security holes, what breaks under real load, risky code without tests, slow… |
| ponytail-debt | DietrichGebert/ponytail | — | skill-lock.json + upstream-sources ledger | 2026-11-13 | > List every `shortcut:` comment (and older `ponytail:` ones) as a debt ledger. |
| ponytail-gain | DietrichGebert/ponytail | — | skill-lock.json + upstream-sources ledger | 2026-11-13 | > Show ponytail's measured savings (code, cost, speed) from the benchmark. |
| ponytail-help | DietrichGebert/ponytail | — | skill-lock.json + upstream-sources ledger | 2026-11-13 | > Quick reference for ponytail levels, skills and commands. |
| ponytail-review | DietrichGebert/ponytail | — | skill-lock.json + upstream-sources ledger | 2026-11-13 | > Quality review of a change: is the logic right, is it safe, does it hold under real load, is risky code tested, i… |
| poster-design-generation | eachlabs/skills | — | skill-lock.json (installed 2026-10-15) | 2026-11-13 | Generate professional poster designs using each::sense AI. |
| prem-search | local, hand-written | — | no source note | 2026-11-13 | Research that recons first. |
| prototype | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Build a throwaway prototype to answer a design question. |
| rebase | raine/workmux (shipped inside the workmux CLI) | — | text embedded in workmux 0.1.263 binary | 2026-11-13 | Rebase the current branch with smart conflict resolution. |
| research | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. |
| rex | Rex CLI installer (`rex skill setup` stub) | — | SKILL.md says `rex skill setup`; rex binary carries the text | 2026-11-13 | Use the rex CLI to manage Rex sessions, open tabs, arrange panes, run commands, inspect terminal output, and contro… |
| rust-skills | leonardomso/rust-skills | MIT | LICENSE + README name the repo; author field | 2026-11-13 | > Comprehensive Rust coding guidelines with 265 rules across 26 categories. |
| safe-refactor | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | Restructure code while preserving behavior. |
| setup-matt-pocock-skills | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Configure this repo for the engineering skills: set up its issue tracker, triage label vocabulary, and domain doc l… |
| superwhisper | Superwhisper app bundle (vendor install, symlink) | — | symlink into the Superwhisper app bundle | 2026-11-13 | > Configure and troubleshoot Superwhisper dictation on Linux through its CLI. |
| surgical-patch | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | Fix bugs and small behavior changes at the narrowest responsible layer. |
| t3-code | local, hand-written | — | no source note | 2026-11-13 | Operate T3 Code threads from inside an agent. |
| tdd | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Test-driven development. |
| teach | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Teach the user a new skill or concept, within this workspace. |
| tiger-style | PremModhaOfficial/tiger-style | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Safety-first coding mode inspired by TigerBeetle's Tiger Style. |
| tiger-style-audit | PremModhaOfficial/tiger-style | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Whole-repo audit for Tiger Style safety. |
| tiger-style-commit | PremModhaOfficial/tiger-style | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Commit message generator that follows Tiger Style's documentation rules: say why, not just what; be descriptive… |
| tiger-style-help | PremModhaOfficial/tiger-style | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Quick-reference card for all tiger-style modes, skills, and commands. |
| tiger-style-review | PremModhaOfficial/tiger-style | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Code review focused exclusively on Tiger Style violations: missing assertions, unbounded loops and queues, unhand… |
| to-questionnaire | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Turn a decision you can't fully answer into a questionnaire for someone else to fill in. |
| to-spec | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Turn the current conversation into a spec and publish it to the project issue tracker: no interview, just synthesis… |
| to-tickets | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking ed… |
| triage | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Move issues and external PRs through a state machine of triage roles, categorise, verify, grill if needed, and writ… |
| ultracave | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | > Caveman at maximum compression: fragments, one word when one word is enough, each fact once. |
| v2-event-loop-orchestration | local, hand-written | — | no source note; v1->v2 lineage in loop/fix1-report.md | 2026-11-13 | Coordinate subagents as an event loop with versioned task state, fresh-context workers, human decision routing, and… |
| verify-and-stop | JuliusBrussee/caveman | — | upstream-sources ledger (update-all stamp) | 2026-11-13 | Prove existing work meets acceptance conditions without expanding scope. |
| wait-what | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Stop. |
| wayfinder | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Plan a huge chunk of work (more than one agent session can hold) as a shared map of decision tickets on your issue… |
| web-browsing-cli | only-cli/oc (npm @only-cli/oc 0.5.8, locally edited) | — | matches @only-cli/oc 0.5.8 (npm); oc calls edited in | 2026-11-13 | Token-efficient web browsing and web content extraction for AI agents. |
| wizard | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Generate an interactive bash wizard that walks a human through steps only they can perform. |
| workmux | raine/workmux (shipped inside the workmux CLI) | — | text embedded in workmux 0.1.263 binary | 2026-11-13 | Reference for the workmux CLI that manages git worktrees and tmux windows as isolated development environments. |
| worktree | raine/workmux (shipped inside the workmux CLI) | — | text embedded in workmux 0.1.263 binary | 2026-11-13 | Launch one or more tasks in new git worktrees using workmux. |
| writing-for-agents | mattpocock/skills | — | skill-lock.json (installed 2026-10-13) | 2026-11-13 | Writing documents for agents. |
