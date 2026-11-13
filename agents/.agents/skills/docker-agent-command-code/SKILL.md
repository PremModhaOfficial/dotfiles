---
name: docker-agent-command-code
description: "Run the Command Code CLI (`cmd`) as a docker-agent harness. Use when: how to run command-code in docker-agent, wants an agent config with harness.type command-code, hits `unsupported harness.type \"command-code\"`."
argument-hint: "[--build] [config.yaml]"
---

# Run Command Code inside docker-agent

The `command-code` harness hands a whole docker-agent turn to the Command Code CLI
(`cmd`). The provider lives in `github.com/rumpl/harness` and the wiring in
`docker/docker-agent` — **both are merged upstream** (2026-10-13). There is no fork
and no `replace` to deal with; `main` carries the type.

## Step 0 — Prerequisites

- `cmd` installed and authenticated, on `PATH`.
- `go` 1.27+ and `git` (only if you build from source).

## Step 1 — Check whether your binary is wired

Not every installed binary has it yet: releases cut before 2026-10-13 predate the
wiring (v1.150.0, 2026-10-09, does not have it; `main` and later releases do).

```bash
bin="$(command -v docker-agent)"
if [ -n "$bin" ] && grep -qa 'command-code' "$bin"; then
  echo "WIRED     -> use it as-is"
else
  echo "NOT WIRED -> install from main (Step 2)"
fi
```

- **WIRED** → go straight to the config below.
- **NOT WIRED** → Step 2.

## Step 2 — Install a build that has it

```bash
# a) from source, straight from main
go install github.com/docker/docker-agent@main

# b) or clone and build
git clone --depth 1 https://github.com/docker/docker-agent.git /tmp/docker-agent-cc
cd /tmp/docker-agent-cc && go build -o bin/docker-agent .
```

Or run the bundled helper, which does (b) and self-checks:

```bash
bash scripts/build-docker-agent.sh /tmp/docker-agent-cc
```

Prefer a tagged release once one newer than v1.150.0 ships — then
`go install github.com/docker/docker-agent@latest` is enough and no main build is
needed.

## The agent config

```yaml
version: "16"          # the config version that carries command-code
agents:
  root:
    description: A Command Code agent
    model: deepseek/deepseek-v4.1-flash   # optional; omit to let cmd pick its default
    harness:
      type: command-code
      effort: high                        # optional: low | medium | high | xhigh | max
```

`effort` is accepted for `command-code` exactly as for `claude-code`. Only the
**latest** config version knows the type; a config pinned to `version: "9"…"15"` will
still reject it, so keep `version: "16"`.

## Run it

```bash
# one-shot, no TUI
docker-agent run --exec config.yaml

# expose the agent over A2A
docker-agent serve a2a config.yaml
```

With a from-source build, call the binary by path:
`/tmp/docker-agent-cc/bin/docker-agent run --exec config.yaml`.

## How the harness drives `cmd`

| need | `cmd` flag |
| --- | --- |
| non-interactive run | `-p` |
| machine-readable stream | `--output-format json` (newline-delimited JSON) |
| resume a session | `-r` |
| model / reasoning effort | `-m` / `--effort` |
| no permission prompts | `--yolo` |

Two behaviours to expect, not bugs:

- `--yolo` is always passed, the same choice `claude-code` makes with
  `--dangerously-skip-permissions`. The caller owns the tool boundary.
- A harness hands the whole turn to the CLI, so docker-agent's `--safety` and toolsets
  do **not** reach inside the `command-code` harness.

## Troubleshooting

| symptom | cause and fix |
| --- | --- |
| `unsupported harness.type "command-code"` | binary predates the wiring — install from main (Step 2) |
| config rejected: type not in enum | config pinned to an older `version:` — set `version: "16"` |
| `harness.effort can only be used with harness.type 'claude-code'` | pre-wiring binary — install from main (Step 2) |
| `cmd` exits immediately / auth errors | `cmd` not on `PATH` or not logged in — authenticate `cmd` first |

## History

The work landed as two PRs, both merged 2026-10-13:

- provider: https://github.com/rumpl/harness/pull/13 — merge commit `04282da1`
- wiring: https://github.com/docker/docker-agent/pull/4577 — merge commit `bfda0c37`

Older revisions of this skill described building a personal fork
(`PremModhaOfficial/docker-agent#add-commandcode-harness`) with a temporary `replace`
on `github.com/rumpl/harness`. That is obsolete — the fork branch and the replace are
gone, and `main` resolves `github.com/rumpl/harness` normally.
