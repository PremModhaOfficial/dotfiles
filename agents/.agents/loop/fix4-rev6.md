# FIX-4 rev6 — the two rev5 defects

Everything in `fix4-rev5-review.md` except its §5 defect and its "proven" wording
passed and is unchanged. This round touches the pi inline, the two scripts, and
the wording. The shared file is byte-for-byte untouched.

| file | before | after |
|---|---|---|
| `~/.agents/AGENTS.md` | 4083 B | **4083 B** (cap 4096, 13 spare, 0 spent) |
| `~/.pi/agent/AGENTS.md` | 5540 B | **5630 B** (+90) |
| `~/.agents/loop/fix4-rev5-verify.py` | 7 checks | 9 checks |
| `~/.agents/loop/fix4-rev5-count.py` | 2 new rows | same 39 obligations, exit 0 |

## 1. Dead tool in the pi inline — fixed, and the class is now checked

`~/.pi/agent/mcp.json` exposes one server, `deepwiki` (repo Q&A via
`ask_wiki_question`; the other two tools are `hidden`). `superlogical` is
`enabled: false`; `donsetch` is registered in `~/.commandcode/mcp.json` only.
So pi had no denied-fetch fallback at all, and the rule named one anyway.

pi, `W2` (line 53):

```
before  - If built-in search or fetch is denied, use the `donsetch` MCP tools.
after   - If built-in search or fetch is denied, use a fallback MCP fetch server
          only when one is configured; pi has none (deepwiki is repo Q&A), so
          report the denial.
```

That is the "available only when configured" form, and it names what a pi session
can actually do: nothing but `W3` (never retry a denied built-in call) — report it.
The pi `References` index line loses the word too (`` `oc` and web-fetch forms``),
so `grep -c donsetch ~/.pi/agent/AGENTS.md` is **0**. The shared file keeps its
`donsetch` rule because cmd has that server; the shared file is harness-neutral and
a cmd session must not lose its fallback.

### Verify script: the FAKE list is scoped and a generic check added

Adding `donsetch` to the existing `FAKE` list would have failed the *shared* file,
which names it legitimately. Two additions instead:

- `PI_FAKE = ["donsetch"]`, checked against the pi file only.
- a generic check: every `` `name` MCP `` server named in the pi file must be a key
  in `~/.pi/agent/mcp.json`'s `mcpServers`. This is the part that makes the class
  non-repeatable — it catches any future dead MCP name, not just the known one.

## 2. Honest claim — classified, not proven

The counter enforces **coverage**, not classification: every bullet must be claimed
by a row and every proof substring must be present, so an added bullet exits 1 — but
re-classing a row moves the number with exit 0. The number is a hand-written label.

Wording now used everywhere the figure appears (`fix4-rev5.md` §1, the count
script's method note and output, this report):

> **39 classified as `obligation`, coverage-enforced.** Honest range **37-39**:
> N6, N7, C6 and O2 are condition-shaped and could be read as `descriptive`.

No machinery was added to decide a class. The count script prints the caveat next
to the number:

```
OBLIGATIONS: 39
CLASSIFIED, NOT PROVEN: hand-labelled class; coverage enforced, class not. Honest range 37-39 (N6, N7, C6, O2 are condition-shaped).
NOT COUNTED: definitions=3 syntax=4 index=8 descriptive=10 d12-copies=5
failed proofs / unclaimed bullets: 0
```

`index` 7->8 and `d12-copies` 4->5 because the two changed pi bullets are no longer
byte-identical to shared ones; they are now reworded copies with their own rows
(`W2p` copy, `I6p` index). Obligation rows are unchanged, so the number is still 39,
and every pi bullet is still claimed.

## 3. Byte budget

The shared file needed no change, so it stays at 4083/4096 (13 B spare). The pi file
has no cap and grew by 90 B; nothing was shaved from either file.

## Verification

| check | result |
|---|---|
| `grep -c donsetch ~/.pi/agent/AGENTS.md` | **0** |
| `/tmp` sandbox, clean baseline | verify **exit 0**, 0 failed checks |
| sandbox + reintroduced `` `donsetch` MCP `` bullet | **exit 1** — `no pi-nonexistent tool`, and `pi MCP servers named are configured`: `['donsetch']` |
| sandbox + novel `` `mystery` MCP `` bullet | **exit 1** — `pi MCP servers named are configured`: `['mystery']` |
| sandbox restored | **exit 0** |
| `fix4-rev5-count.py` (live, from `/tmp`) | **exit 0**, `OBLIGATIONS: 39`, `unclaimed=0` |
| caps | shared 4083/4096, pi 5630 (no cap) |

The `/tmp` sandbox is a copy of the tree under `HOME=/tmp/fx6/h` (the script resolves
through `Path.home()`), taken from `fix4-rev5-sets/after` plus the live pi file.
Reproduce:

```bash
mkdir -p /tmp/fx6/h/.pi/agent /tmp/fx6/h/.commandcode
cp -a ~/.agents/loop/fix4-rev5-sets/after/. /tmp/fx6/h/.agents/
mkdir -p /tmp/fx6/h/.agents/references /tmp/fx6/h/.agents/loop
cp -a ~/.agents/loop/fix4-rev5-sets/after/refs/. /tmp/fx6/h/.agents/references/
cp ~/.agents/loop/fix4-rev5-dup.py ~/.agents/loop/fix4-rev5-verify.py /tmp/fx6/h/.agents/loop/
rm -f /tmp/fx6/h/.agents/pi-AGENTS.md
cp ~/.pi/agent/{AGENTS.md,mcp.json} /tmp/fx6/h/.pi/agent/
cp ~/.commandcode/{AGENTS.md,settings.json} /tmp/fx6/h/.commandcode/
mkdir -p /tmp/fx6/h/.pi/agent/extensions
touch /tmp/fx6/h/.pi/agent/extensions/herdr-interactive-only.ts
cd /tmp && HOME=/tmp/fx6/h python3 /tmp/fx6/h/.agents/loop/fix4-rev5-verify.py   # exit 0
echo '- If built-in search or fetch is denied, use the `donsetch` MCP tools.' >> /tmp/fx6/h/.pi/agent/AGENTS.md
cd /tmp && HOME=/tmp/fx6/h python3 /tmp/fx6/h/.agents/loop/fix4-rev5-verify.py   # exit 1
```

## Known, not fixed here (outside this ticket's files)

1. **`memory-clarify.md` drifted at 12:41, after the rev5 review**, to 1371 B, which
   now restates the shared bullets nearly verbatim. The live verify therefore exits
   **1** on check 6 (`memory-clarify.md 46.9% at 0.65`). That reference file is not
   this ticket's; the sandbox above, which pins the rev5 copy, is clean at 0/0.
2. **`~/.agents/references/memory-web-access.md` still names `mcp__donsetch__*`**
   as the denied-fetch fallback with no harness qualifier, and the pi index line still
   points at it. pi readers who follow that pointer still see a name pi cannot use.
   Same defect class as §1, one level out; it needs a reference-file edit, which this
   ticket does not own. `PI_FAKE` is scoped to the pi file, so the verify script will
   not report it.
3. The rev5 §1 census nit (rule 2 describes one copy mechanism where there are two)
   is untouched: not one of the two defects.
