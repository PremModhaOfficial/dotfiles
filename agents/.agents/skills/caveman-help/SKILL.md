---
name: caveman-help
description: >
  Quick-reference card for the three caveman skills and their commands.
  Trigger: /skill:caveman-help or "caveman help".
---

# Caveman Help

Display this reference card when invoked. One-shot — do NOT change mode, write flag files, or persist anything. Output in caveman style.

## Modes

| Mode | Trigger | What change |
|------|---------|-------------|
| **caveman** | `/skill:caveman` | The voice. Answer first, no fluff, every fact kept. Default. |
| **ultracave** | `/skill:ultracave` (alias `/skill:caveman ultra`) | Grammar stripped. Fragments, one word when enough, each fact once. |
| **megacave** | `/skill:megacave` (alias `/skill:caveman wenyan`) | Classical Chinese 文言文. Far fewer characters, technical terms verbatim. |

Mode stick until changed or session end.
`/skill:caveman status` reports current mode without changing it. Claude Code and the standalone OpenCode plugin read stored state; other hosts answer from the conversation and mark it `(not tracked by this host)`.

## Skills

| Skill | Trigger | What it do |
|-------|---------|-----------|
| **caveman-commit** | `/skill:caveman-commit` | Terse commit messages. Conventional Commits. ≤50 char subject. |
| **tiger-style-review** | `/skill:tiger-style-review` | One-line PR comments: `L42: assert: user null after find. Add guard.` Safety tags only. |
| **caveman-review** | `/skill:caveman-review` | Terse review of any diff: `L42: 🔴 bug: user can be null after .find(). Add guard before .email.` |
| **caveman-compress** | `/skill:caveman-compress <file>` | Compress .md files to caveman prose. 33.2% fewer tokens on the repo's five test files. |
| **caveman-help** | `/skill:caveman-help` | This card. |

## Deactivate

Say "stop caveman" or "normal mode". Resume anytime with `/skill:caveman`.

## Language

Keep user's language by default — reply in the language user writes, never switch regardless of example text or multilingual context elsewhere. Compress the style, not the language. Technical terms, code, commands, commit types, and exact error strings stay verbatim unless user ask for translation.

## Choosing the mode

No mode is stored and nothing reads a setting, so the mode is whichever skill is loaded: `/skill:caveman`, `/skill:ultracave` (alias `/skill:caveman ultra`) or `/skill:megacave` (alias `/skill:caveman wenyan`), or just say "talk like caveman". It holds for the session; "stop caveman" or "normal mode" ends it, and a new session starts in no mode.

Upstream does carry a `defaultMode` resolver — `CAVEMAN_DEFAULT_MODE`, then repo `.caveman/config.json`, then user `~/.config/caveman/config.json`, default `caveman` — in `src/hooks/caveman-config.js`. Only its Claude Code hook scripts and its OpenCode plugin read it, and neither is installed here: `~/.claude/settings.json` has no caveman hook, there is no OpenCode caveman plugin, and the installed `@caveman-ai/cli` bundle contains no reader. Exporting that variable or writing that file changes nothing on this host; say so rather than implying a default moved. `lite`, `full`, `ultra`, `wenyan*` are legacy aliases of the modes above.

## More

Full docs: https://github.com/JuliusBrussee/caveman
