# FIX-8 rev2 — composed pipeline, not just the classifier

File: `~/.pi/agent/extensions/herdr-interactive-only.ts` (only file changed; `bash-guard.ts` untouched).
Test: `~/.agents/loop/fix8/fix8.test.mjs` — one command, both suites:

```
node ~/.agents/loop/fix8/fix8.test.mjs
```

## What rev2 changes

All three review findings, in one file:

1. **F1 (fatal) — segment loop extracted as `scan(tokens, depth, found)`**, exactly as proposed.
   `scan` is now called from `classify` (top level) *and* from the `bash -c` recursion, so the
   payload bash-guard produces is split on `;`/`&&`/`||`/`|`/newline at every depth, not handed to
   `analyze` once. `classify` is three lines: `scan(tokenize(stripHeredocs(command)), 0, found)`.
2. **F2 — subcommand finder no longer returns a flag value**: new `firstPositional(args)` skips
   flags that take a value (`-m/--model`, `-c/--config`, `-C/--cd`, `-i/--image`, `--sandbox`,
   `--agent`, `--log-level`, `--provider`). `codex -m gpt-5-codex exec`, `codex --model gpt-5 exec`,
   `opencode --model sonnet run` now classify as one-shots. Booleans before the subcommand
   (`codex --full-auto exec`) still work, because only known value flags swallow the next token.
3. **F3 — value flags are per wrapper**, because the same letter differs: `sudo -E` is a boolean,
   `xargs -E` takes a string. Long flags stay in the shared `VALUE_FLAGS`; short ones moved to
   `SHORT_VALUE_FLAGS` keyed by wrapper (`sudo`, `doas`, `env`, `xargs`, `timeout`, `nice`,
   `stdbuf`), and `skipFlags(tokens, from, wrapper)` consults that. `sudo -E pi -p x` now blocks.

Unchanged: the block reason text, the report-back warning (and its `"warning"` level), and every
false-positive rule (`grep`, `echo`, `node -e`, `hc send`, heredoc bodies) — all covered below.

## Diff (rev1 → rev2)

```diff
--- rev1 (herdr-interactive-only.ts)
+++ rev2 (herdr-interactive-only.ts)
@@ -25,12 +25,28 @@
 // Flags that swallow the next token as their value, so the value is not mistaken
 // for the invoked binary (`sudo -u bot pi`, `xargs -n 1 pi`, `--name flow-test pi`).
+// Long flags mean the same thing for every wrapper; short ones do not (`sudo -E`
+// is a boolean, `xargs -E` takes a string), so those are listed per wrapper.
 const VALUE_FLAGS = new Set([
-  "-u", "-g", "-s", "-k", "-n", "-I", "-P", "-L", "-E", "-a", "-d", "-e",
   "--user", "--group", "--signal", "--kill-after", "--max-args", "--replace",
   "--max-procs", "--delimiter", "--arg-file", "--name", "--cwd", "--dir",
   "--label", "--workspace", "--tab", "--shell", "--env", "--timeout",
 ]);
+const SHORT_VALUE_FLAGS: Record<string, Set<string>> = {
+  sudo: new Set(["-u", "-g", "-p", "-C", "-h", "-r", "-t", "-T"]),
+  doas: new Set(["-u", "-C"]),
+  env: new Set(["-u", "-C", "-S"]),
+  xargs: new Set(["-n", "-I", "-P", "-L", "-a", "-d", "-E", "-s"]),
+  timeout: new Set(["-s", "-k"]),
+  nice: new Set(["-n"]),
+  stdbuf: new Set(["-i", "-o", "-e"]),
+};
+// Agent flags that swallow a value, so it is not read as the subcommand
+// (`codex -m gpt-5 exec`, `opencode --model sonnet run`).
+const AGENT_VALUE_FLAGS = new Set([
+  "-m", "--model", "-c", "--config", "-C", "--cd", "-i", "--image", "--sandbox",
+  "--agent", "--log-level", "--provider",
+]);
@@ -108,20 +124,33 @@
+// The subcommand, not the value of a flag that happens to precede it.
+function firstPositional(args: string[]): string | undefined {
+  for (let i = 0; i < args.length; i++) {
+    if (!args[i].startsWith("-")) return args[i];
+    if (!args[i].includes("=") && AGENT_VALUE_FLAGS.has(args[i])) i++;
+  }
+}
+
 function isOneShot(agent: AgentName, args: string[]): boolean {
-  const subcommand = args.find((arg) => !arg.startsWith("-"));
+  const subcommand = firstPositional(args);
@@ -133,20 +151,28 @@
+function takesValue(wrapper: string, flag: string): boolean {
+  if (flag.startsWith("--")) return VALUE_FLAGS.has(flag);
+  return SHORT_VALUE_FLAGS[wrapper]?.has(flag) ?? false;
+}
+
 // Index just past the wrapper's own flags (`sudo -u bot`, `xargs -n 1`).
-function skipFlags(tokens: string[], from: number): number {
+function skipFlags(tokens: string[], from: number, wrapper: string): number {
   let i = from;
   while (i < tokens.length && tokens[i].startsWith("-")) {
     const flag = tokens[i++];
-    if (flag.length <= 2 && VALUE_FLAGS.has(flag) && i < tokens.length) i++;
+    if (!flag.includes("=") && takesValue(wrapper, flag) && i < tokens.length) i++;
   }
   return i;
 }
@@ -138,7 +167,7 @@
-    i = skipFlags(tokens, i + 1);
+    i = skipFlags(tokens, i + 1, base(token));
@@ -148,7 +177,7 @@
     if (cIndex > -1 && args[cIndex + 1] !== undefined) {
-      analyze(tokenize(stripHeredocs(args[cIndex + 1])), depth + 1, found);
+      scan(tokenize(stripHeredocs(args[cIndex + 1])), depth + 1, found);
     }
@@ -159,12 +188,12 @@
-    const subcommand = tokens[skipFlags(tokens, i + 1)];
+    const subcommand = tokens[skipFlags(tokens, i + 1, exe)];
     if (subcommand === undefined || !SPAWN_SUBCOMMANDS.has(subcommand)) return;
-    for (let k = skipFlags(tokens, i + 2); k < tokens.length; k++) {
+    for (let k = skipFlags(tokens, i + 2, exe); k < tokens.length; k++) {
       const token = tokens[k];
       if (token.startsWith("-")) {
-        if (!token.includes("=") && VALUE_FLAGS.has(token)) k++; // flag value
+        if (!token.includes("=") && takesValue(exe, token)) k++; // flag value
@@ -175,16 +204,24 @@
-/** Every agent spawn the command actually executes. */
-export function classify(command: string): Spawn[] {
-  const found: Spawn[] = [];
+// Run every `;`-separated segment through analyze. Recursing into `bash -c` bodies
+// goes through here too: a wrapped payload is a full command line, and in the real
+// pipeline bash-guard.ts has already wrapped every command in `bash -c` before this
+// hook sees it.
+function scan(tokens: string[], depth: number, found: Spawn[]): void {
   let segment: string[] = [];
-  for (const token of [...tokenize(stripHeredocs(command)), ";"]) {
+  for (const token of [...tokens, ";"]) {
     if (token === ";") {
-      analyze(segment, 0, found);
+      analyze(segment, depth, found);
       segment = [];
     } else segment.push(token);
   }
+}
+
+/** Every agent spawn the command actually executes. */
+export function classify(command: string): Spawn[] {
+  const found: Spawn[] = [];
+  scan(tokenize(stripHeredocs(command)), 0, found);
   return found;
 }
```

`tsc --strict -p` on the file: clean. Loads under jiti the way pi loads it: one `tool_call` handler,
`classify` exported.

## How the composed suite is faithful

- Extensions are discovered with `readdirSync` over `~/.pi/agent/extensions` (unsorted, mirroring
  `loader.js:647`), then loaded in that order — the test prints the order it found, and fails if
  `bash-guard.ts` is not first. Run output below: `bash-guard.ts -> herdr-interactive-only.ts`.
- Both handlers receive **one** event object, in handler order, and the loop stops on `block` —
  `runner.js:965-980`.
- Every composed row prints `rewrit=true`, meaning the command my hook received differs from the
  command as typed. That is the assertion that the test is really composed, not simulated: a
  non-composed run would hash the raw command twice.
- Example: `cd /repo && pi -p 'summarize the diff'` reaches the guard as
  `exec 0</dev/null\nexec timeout -s TERM -k 5 600 setsid bash -c 'cd /repo && pi -p '\''summarize the diff'\'''`
  and still blocks.

## Full output

```
$ node ~/.agents/loop/fix8/fix8.test.mjs
=== isolated: classify() on the command as typed ===
want   got   ok    spawns                       command
block  block true  pi (one-shot)                hc run --bg --name flow-test pi -p 'summarize the diff'
block  block true  claude (one-shot)            claude -p 'fix the tests' > /tmp/out.txt 2>&1
block  block true  codex (one-shot)             cd /repo && timeout 900 codex exec --full-auto 'add the re
block  block true  opencode (one-shot)          opencode run 'bump the version'
block  block true  pi (one-shot)                sudo -u bot env FOO=1 pi --print 'hello'
block  block true  pi (one-shot)                echo 'go' | xargs -n 1 pi -p
block  block true  codex (one-shot)             codex -m gpt-5-codex exec 'port the auth module'
block  block true  codex (one-shot)             codex --model gpt-5 exec 'x'
block  block true  opencode (one-shot)          opencode --model sonnet run 'x'
block  block true  pi (one-shot)                sudo -E pi -p 'x'
block  block true  pi (one-shot)                bash -c 'hc run --bg pi -p "task"'
block  block true  pi (one-shot)                timeout 600 sudo -u bot pi -p 'x'
block  block true  pi (one-shot)                env -i pi -p 'x'
block  block true  pi (one-shot)                nohup pi -p 'x' &
block  block true  pi (one-shot)                hc run --name=flow pi --print 'x'
block  block true  goose (one-shot)             goose run -t 'x'
block  block true  amp (one-shot)               amp -x 'x'
block  block true  pi (one-shot)                xargs -0 -n1 pi -p
block  block true  pi (one-shot)                true\npi -p 'x'
pass   pass  true  pi (interactive)             hc run --bg --name flow-test pi
pass   pass  true  claude (interactive)         hc run --bg --name flow-ok claude --model opus
pass   pass  true  amp (interactive)            hc run --bg --name amp-test amp
pass   pass  true  codex (interactive)          hc run --bg --name flow codex
pass   pass  true  goose (interactive)          herdr new --name x goose
pass   pass  true  codex (interactive)          codex
pass   pass  true  -                            grep -n 'NON_INTERACTIVE\|block' /home/prm/.pi/agent/exten
pass   pass  true  -                            echo 'hc run --bg --name flow-test pi -p'
pass   pass  true  -                            node -e 'const N=/(?:^|\s)(?:-p|--print|exec)(?:\s|$)/; co
pass   pass  true  -                            cat > /tmp/spawn-acceptance.sh <<'EOS'\nhc run --bg --name
pass   pass  true  -                            hc send flow-test 'then run pi -p or codex exec, your call
pass   pass  true  -                            grep -rn 'codex exec' /home/prm/.agents/AGENTS.md
pass   pass  true  -                            herdr list | grep pi
pass   pass  true  -                            ps aux | grep -e pi
pass   pass  true  -                            echo pi -p
pass   pass  true  -                            python3 -c 'print(1)'
pass   pass  true  -                            hc send pi 'run it'
pass   pass  true  -                            docker run --rm pi
pass   pass  true  -                            cat notes.md | head -3
pass   pass  true  pi (interactive)             pi --help

39/39 isolated cases passed

=== composed: bash-guard.ts handler then herdr-interactive-only.ts handler, one event ===
discovered (readdirSync, unsorted): bash-guard.ts -> herdr-interactive-only.ts
want     got      ok    rewrit  command
block    block    true  true    cd /repo && pi -p 'summarize the diff'
block    block    true  true    cd /repo && claude -p 'fix the tests'
block    block    true  true    echo 'go' | xargs -n 1 pi -p
block    block    true  true    hc run --bg --name flow-test pi -p 'summarize the di
block    block    true  true    claude -p 'fix the tests' > /tmp/out.txt 2>&1
block    block    true  true    opencode run 'bump the version'
block    block    true  true    sudo -u bot env FOO=1 pi --print 'hello'
block    block    true  true    codex -m gpt-5-codex exec 'port the auth module'
block    block    true  true    sudo -E pi -p 'x'
block    block    true  true    cd /repo && timeout 900 codex exec --full-auto 'add 
block    block    true  true    bash -c 'cd /r && pi -p x'
block    block    true  true    sh -c 'true; claude -p x'
pass     pass     true  true    grep -n 'NON_INTERACTIVE\|block' /home/prm/.pi/agent
pass     pass     true  true    grep -rn 'codex exec' /home/prm/.agents/AGENTS.md
pass     pass     true  true    echo 'hc run --bg --name flow-test pi -p'
pass     pass     true  true    node -e 'const N=/(?:^|\s)(?:-p|--print|exec)(?:\s|$
pass     pass     true  true    hc send flow-test 'then run pi -p or codex exec, you
pass     pass     true  true    cat > /tmp/spawn-acceptance.sh <<'EOS'\nhc run --bg 
pass     pass     true  true    herdr list | grep pi
warning  warning  true  true    hc run --bg --name flow-test pi
warning  warning  true  true    hc run --bg --name flow-ok claude --model opus

what the guard received after bash-guard's rewrite:
  "cd /repo && pi -p 'summarize the diff'"...
  "exec 0</dev/null\nexec timeout -s TERM -k 5 600 setsid bash -c 'cd /repo && pi -p '\\''summarize the diff'\\'''"

21/21 composed cases passed

60/60 cases passed (39 isolated, 21 composed)
```

Exit code 0.

## Negative control — the test is not vacuous

Same test file, pointed at a copy of rev1's code (`FIX8_EXT_DIR=/tmp/fix8/rev1dir`), fails where the
review said it would:

```
=== isolated === ... 35/39 isolated cases passed
  codex -m gpt-5-codex exec 'port the auth module'  -> codex (interactive)   [warn-only]
  codex --model gpt-5 exec 'x'                       -> codex (interactive)
  opencode --model sonnet run 'x'                    -> opencode (interactive)
  sudo -E pi -p 'x'                                  -> no spawn at all
=== composed === ... 13/21 composed cases passed
  cd /repo && pi -p 'summarize the diff'      -> pass
  cd /repo && claude -p 'fix the tests'       -> pass
  echo 'go' | xargs -n 1 pi -p                -> pass
  cd /repo && timeout 900 codex exec ...      -> pass
  bash -c 'cd /r && pi -p x'                  -> pass
  sh -c 'true; claude -p x'                   -> pass
  sudo -E pi -p 'x'                           -> pass
```

The six F1 misses and the F2/F3 misses are exactly the review's findings, and rev2 closes all of them.

## Still open (unchanged, not part of this ticket)

- **F4** — heredoc *into* a shell (`bash <<'EOS' … pi -p … EOS`) is treated as data, and a quoted
  fake marker (`echo "<<EOF"`) still swallows following lines. Untouched by rev2.
- Script files (`bash /tmp/x.sh`), `$()`/backticks inside double quotes, variables/aliases/eval,
  wrapper binaries outside the wrapper set (`docker run … pi -p`), `--print=x` joined forms.
- `command -v pi` style probes read `pi` as the binary (pre-existing, warn-only).

Files touched: `~/.pi/agent/extensions/herdr-interactive-only.ts`,
`~/.agents/loop/fix8/fix8.test.mjs` (test, one command for both suites). `bash-guard.ts` not touched.
