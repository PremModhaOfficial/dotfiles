# FIX-4 review (revision 1) — antagonist pass

**VERDICT: REFUTED (narrowly).** The consolidation direction is real and the byte counts check out, but the claim's own closing clause — "nothing was dropped" — is false: at least 6 imperatives/facts present in the originals are absent from every current file, and 2 more were weakened in translation. Duplication: no verbatim sentence duplicate found by my own method (independent agreement with the worker). Pointer: load-bearing and, for pi, unenforced — pi has no `@`-import, so the shared file is read only if the model volunteers.

Scope note: the 4096-byte criterion was dropped per the human's policy change. `~/.agents/AGENTS.md` (4092 bytes, 54 lines) is not judged for size.
Provenance caveat: `diff` proves the current files differ from `/tmp/fix4/orig-*.md` when the originals are taken as given — but no backup in `~/.commandcode/` is 8130 bytes (`AGENTS.md.bak.*` are 1769/1933/3047/3329/3470/3499), `~/.pi/agent/` holds no backup, and `git -C ~/.agents log -- AGENTS.md` is empty. So the *claimed prior state* is unverifiable except from the worker's own dump; my loss findings inherit that dependency.

## 1. Bytes and structure (verified)

| file | bytes | lines | claim |
|---|---|---|---|
| `~/.agents/AGENTS.md` | 4092 | 54 | 4092 ✓ |
| `~/.commandcode/AGENTS.md` | 2589 | 27 | 2589 ✓ |
| `~/.pi/agent/AGENTS.md` | 532 | 6 | 532 ✓ |

`~/.commandcode/AGENTS.md:27` = `@~/.agents/AGENTS.md`, last non-empty line, file ends `...AGENTS.md\n` — pointer position claim holds.

## 2. Lost (each quoted from the original, with where it is now absent)

1. **EGM skill sources path — LOST.** `orig-pi.md:7`: "EGM skills are the `/skill:egm-*` commands; their sources are in `<bundle root>/skills/`." Replacement `~/.pi/agent/AGENTS.md:5` names only `agents/`, `resources/`, `docs/`; the `skills/` subtree of the bundle is named nowhere in any of the three files.
2. **Reporting channel for spawned agents — WEAKENED to a bare instruction.** `orig-pi.md:16`: "Every spawned agent's task text must tell it to report back: send progress, findings and questions to this session with the intercom tool (or `hc send <parent>`)." Now `~/.agents/AGENTS.md:41`: "make its task text require progress reports back". The mandatory channel (intercom / `hc send <parent>`) is gone; "must tell it … with the intercom tool" became "require … back".
3. **Verification commands — LOST.** `orig-pi.md:17`: "Check on it rather than assuming: `hc ls`, `hc read <name> --lines 80`, and the agent's own session log." Now `~/.agents/AGENTS.md:41` keeps only "check with `hc ls` rather than assuming." `hc read <name> --lines 80` and "the agent's own session log" appear in no current file.
4. **`shell_output` window arguments — LOST.** `orig-cmd.md:23`: "peek with `shell_output` (`from_offset` + `max_chars`)". Now `~/.agents/AGENTS.md:24`: "Peek instead (cmd: `shell_output`)". The paging arguments are gone; on a long-running build the reader is told to peek but not how to peek past the tail.
5. **Exact donsetch tool IDs — LOST, and now ambiguous.** `orig-cmd.md:89-90`: "`mcp__donsetch__web_search`, `mcp__donsetch__web_fetch`, `mcp__donsetch__web_crawl` — and do not retry a denied built-in call." Now `~/.agents/AGENTS.md:50`: "use the `donsetch` MCP tools (`web_search`, `web_fetch`, `web_crawl`)". The namespaced IDs that resolved the ambiguity between native and MCP tools are dropped, in the very sentence whose subject is that built-in and MCP tools are confusable.
6. **`cmd -p` and "DAG workers" — LOST as named cases.** `orig-cmd.md:7`: "( `cmd -p`, builds, tests, watchers, servers )" → `~/.agents/AGENTS.md:20` "(builds, tests, watchers, servers, headless agents)". `orig-cmd.md:8`: "Subagents, DAG workers, background runs" → `~/.agents/AGENTS.md:21` "an agent or long job". Category coverage is intact; the named instances a reader pattern-matches on are not.
7. **flow's purpose clause — LOST.** `orig-agents.md:28`: "It names one default skill per phase, delegates every exit check to that skill, and **holds the rules learned from earlier sessions**." Now `~/.agents/AGENTS.md:54` drops the third clause. A reader no longer learns that `flow` carries prior-session rules — a reason to invoke it rather than skip it.
8. **"Always" and "smallest possible" — weakened.** `orig-agents.md:20` "**Always** prefer `~/.agents`" → `~/.agents/AGENTS.md:13` "Prefer `~/.agents`". `orig-agents.md:24` "add the smallest **possible** pointer" → `~/.agents/AGENTS.md:16` "add the smallest pointer". Neither is fatal; both soften a HARD RULE's own wording while labelling it one.

Not lost, worth stating so the verdict is not overclaimed: the whole "never block" block, the graft/deepwiki lookup rules, subagent scoping, codemode batching and `oc` web rules all survive with their imperatives ("Never block on an agent or long job", "never a timer loop", "never re-run a failed task at the same scope"), and the `shell_command` name did survive locally at `~/.commandcode/AGENTS.md:23`.

## 3. Duplication (my own method)

Sentence-split all three files (≥25 chars: SHARED 34, CMD 19, PI 4 sentences), token-set Jaccard over every cross-file pair. Highest pair 0.19, no pair ≥0.30; **zero verbatim sentences appearing in two files.** I reached this independently of `/tmp/fix4/dup.txt` (which reports the same result at a 40-char threshold) and confirm it.

Two non-verbatim overlaps the sentence metric cannot see, and which I do flag:

- **Herdr one-shot prohibition lives in two files, at different scope.** `~/.agents/AGENTS.md:41`: "Herdr: no one-shot spawns (`pi -p`, `claude -p`, `codex exec`)" and `~/.pi/agent/AGENTS.md:6`: "one-shot `pi -p` launches are blocked by `~/.pi/agent/extensions/herdr-interactive-only.ts`". Same rule, twice; and the pi copy narrows the ban to `pi -p`, so a pi-only reader concludes `claude -p` and `codex exec` are permitted. That is a paraphrase duplicate that also contradicts.
- **The "shared" file now contains a harness-named rule.** The Herdr bullet at `~/.agents/AGENTS.md:41` names `pi`/`claude`/`codex`/`hc` and was migrated out of `orig-pi.md:14-15`. It sits under a file whose stated job is tool-neutral rules; the claim's "all tool-neutral rules live once" is therefore either loose (the file holds non-neutral rules too) or false (this rule is neutral only because it names three harnesses).

The HARD RULE pair themselves are not duplicated: "clarify until ambiguity <= 3" and "harness-agnostic home" exist only in `~/.agents/AGENTS.md:3-17`.

## 4. Pointer: load-bearing, and not mechanically followed

- **pi has no import mechanism.** `docs/configuration.md` (Context files) and `dist/core/resource-loader.js:175-209` (`loadProjectContextFiles`) load exactly `AGENTS.override.md`, `AGENTS.md`, `CLAUDE.md` — from `<agent-dir>` plus the cwd and its ancestors. There is no `@path` expansion anywhere in the loader. `@~/.agents/AGENTS.md` in `~/.commandcode/AGENTS.md:27` is therefore **not** valid pi syntax; it is prose with an `@` in front.
- **`~/.agents/AGENTS.md` is not in pi's discovery chain.** With cwd `/home/prm`, pi loads `/home/prm/.pi/agent/AGENTS.md` and would load `/home/prm/AGENTS.md` (does not exist) — `~/.agents/` is a child directory, never visited. Empirically: this session's injected context contains `~/.pi/agent/AGENTS.md` and nothing from `~/.agents/AGENTS.md`; I had to `read` it.
- **So the pointer is the only route, and it is unenforced.** "read it before acting" at `~/.pi/agent/AGENTS.md:3` is a request, not a mechanism. Every rule in section 2 and every surviving shared rule reaches pi only if the model chooses to open the file first — and nothing in the reduced pi file makes that fail loudly. The reduction 1320 → 532 is therefore *not* a content-neutral move for pi; it moves the rules from guaranteed-in-context to opt-in.
- **By contrast the cmd pointer does work.** `command-code/dist/bundled/command-code-knowledge/reference/memory.md:83-96`: "Any `@path` reference inside a memory file is replaced with that file's contents", recursive to 5 levels, `~/` expands. So cmd auto-inlines the shared rules; pi does not. The two files use the same `@` idiom with opposite effect — a reader fixing one will break the other.
- Rule text that a pi-only reader sees but cannot act on: `~/.pi/agent/AGENTS.md:6` reports that `pi -p` is "blocked" — a fact — while the imperative "no one-shot spawns" exists only in the shared file. Present fact, absent rule.

## Lost, in one block

> "EGM skills are the `/skill:egm-*` commands; their sources are in `<bundle root>/skills/`." (`orig-pi.md:7`)
> "send progress, findings and questions to this session with the intercom tool (or `hc send <parent>`)" (`orig-pi.md:16`)
> "`hc read <name> --lines 80`, and the agent's own session log" (`orig-pi.md:17`)
> "peek with `shell_output` (`from_offset` + `max_chars`)" (`orig-cmd.md:23`)
> "`mcp__donsetch__web_search`, `mcp__donsetch__web_fetch`, `mcp__donsetch__web_crawl`" (`orig-cmd.md:89-90`)
> "Always prefer `~/.agents`" (`orig-agents.md:20`) → "Prefer `~/.agents`"
> "add the smallest possible pointer" (`orig-agents.md:24`) → "add the smallest pointer"
> "and holds the rules learned from earlier sessions" (`orig-agents.md:28`)

## Duplicated, in one block

> `~/.agents/AGENTS.md:41` "no one-shot spawns (`pi -p`, `claude -p`, `codex exec`)" vs `~/.pi/agent/AGENTS.md:6` "one-shot `pi -p` launches are blocked by `~/.pi/agent/extensions/herdr-interactive-only.ts`" — same prohibition, two files, narrower in the local copy.

---

Ponytail note: I did not audit whether the 2589-byte cmd file still matches the live plugin (the Herdr paths and `wake-lab/` evidence), and did not test whether cmd actually inlines the `@` pointer at runtime — only that its bundled docs say it does.
