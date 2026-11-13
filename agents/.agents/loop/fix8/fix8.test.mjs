// FIX-8 rev3 — one command, two suites plus a negative control:
//
//   node ~/.agents/loop/fix8/fix8.test.mjs
//
// ISOLATED  classify() on the command as typed.
// COMPOSED  the real pipeline: extensions are discovered with readdirSync over
//           ~/.pi/agent/extensions (unsorted, as loader.js:647 does), loaded in
//           that order, and both `tool_call` handlers are driven on ONE event
//           object in handler order (runner.js:965-980). bash-guard.ts mutates
//           event.input.command, so the guard must still see the spawn after the
//           command has been rewritten to `bash -c '<command>'`.
// CONTROL   the same file re-run with FIX8_EXT_DIR=./rev1 (the reviewed rev1
//           extension + a symlink to the real bash-guard.ts). It must still fail,
//           so a green run cannot be an artefact of the harness.
//
// Documented gaps: shapes no static check here classifies. Each stays a gap for a
// reason, not for lack of trying, and is asserted below as a *pass* so the gap
// cannot silently turn into a block:
//   ssh, docker run, systemd-run   the agent runs on another host, container or
//                                  unit; that target's config picks the binary,
//                                  not the words of this command
//   eval                           the command is assembled at run time from
//                                  variables, so its words do not exist until
//                                  eval executes
//   script files (`bash x.sh`)     commands live in another file, read at run
//                                  time and changeable after this check
//   heredoc piped into a shell     the body is stdin data; text written to a file
//                                  is indistinguishable from text fed to a shell
//
// Two shapes block on purpose although nothing is spawned — deliberate
// fail-closed decisions, asserted below as `block` so a later reader cannot
// "fix" them without the suite objecting:
//   a never-called function body   `f() { pi -p x; }` blocks: reaching the executed
//                                  word past grouping keywords costs this
//   `hc run --bg nvim pi -p x`     the harness scan keeps looking for an agent
//                                  after the program name, as fail-closed (`exec`
//                                  and `pane run` stop at their first positional)
//
// rev5 rows: a quoted pane payload is scanned segment by segment (`cd /r && pi -p
// x`), a shell comment is not a command, the exec/pane program is its first
// positional (`hc exec grep -n pi -p f`), and package runners execute the package
// they name (`npx`, `bunx`, `pnpm dlx`, `uvx`, `deno run`).
//
// `$(...)`/backticks are NOT a gap: a substitution body runs before the outer
// command, so it is scanned whether or not quotes hide it. Single-quoted text is
// literal, so `echo '$(pi -p t)'` stays a pass.
import { spawnSync } from "node:child_process";
import { readdirSync } from "node:fs";
import { registerHooks } from "node:module";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const PKG = "/home/prm/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent/dist/index.js";
registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === "@earendil-works/pi-coding-agent") {
      return { url: pathToFileURL(PKG).href, shortCircuit: true };
    }
    return nextResolve(specifier, context);
  },
});

const EXT_DIR = process.env.FIX8_EXT_DIR ?? "/home/prm/.pi/agent/extensions";
const REV1_DIR = join(new URL(".", import.meta.url).pathname, "rev1");
const HOOK = join(EXT_DIR, "herdr-interactive-only.ts");
const { classify } = await import(pathToFileURL(HOOK).href);

// ---------------------------------------------------------------- isolated ---

const isolated = [
  // must block: real one-shot spawns
  ["block", "hc run --bg --name flow-test pi -p 'summarize the diff'"],
  ["block", "claude -p 'fix the tests' > /tmp/out.txt 2>&1"],
  ["block", "cd /repo && timeout 900 codex exec --full-auto 'add the retry'"],
  ["block", "opencode run 'bump the version'"],
  ["block", "sudo -u bot env FOO=1 pi --print 'hello'"],
  ["block", "echo 'go' | xargs -n 1 pi -p"],
  // F2: the subcommand is not the value of a preceding flag
  ["block", "codex -m gpt-5-codex exec 'port the auth module'"],
  ["block", "codex --model gpt-5 exec 'x'"],
  ["block", "opencode --model sonnet run 'x'"],
  // F3: -E is a boolean, so `pi` is still the binary
  ["block", "sudo -E pi -p 'x'"],
  // counts that used to be missed below a bash -c boundary
  ["block", "bash -c 'hc run --bg pi -p \"task\"'"],
  ["block", "timeout 600 sudo -u bot pi -p 'x'"],
  ["block", "env -i pi -p 'x'"],
  ["block", "nohup pi -p 'x' &"],
  ["block", "hc run --name=flow pi --print 'x'"],
  ["block", "goose run -t 'x'"],
  ["block", "amp -x 'x'"],
  ["block", "xargs -0 -n1 pi -p"],
  ["block", "true\npi -p 'x'"],
  // rev4: the shape this machine actually used — a two-level herdr subcommand
  ["block", "herdr pane run wC:pF 'pi -p t'"],
  ["block", "herdr pane run wC:pF 'PI_SESSION_NAME=x pi -p t'"],
  // rev4: hc exec is a fire-and-forget launcher too
  ["block", "hc exec pi -p x"],
  ["block", "hc exec --on m pi -p x"],
  ["block", "hc exec bash -c 'pi -p x'"],
  // rev4: wrapper flags may follow the timeout duration
  ["block", "timeout 5 -s KILL pi -p x"],
  ["block", "timeout -s KILL 5 pi -p x"],
  // rev4: a quoted substitution is scanned like the unquoted one (safe direction:
  // it blocks), while single-quoted text is literal and still passes
  ["block", 'echo "$(pi -p t)"'],
  ["pass", "echo '$(pi -p t)'"],
  // rev4: deliberate fail-closed over-block, kept and asserted
  ["block", "hc run --bg nvim pi -p x"],

  // rev5: the machine's own shape — a quoted pane payload is a whole command
  // line, so its `&&`/`|` segments are scanned, not only the first
  ["block", "herdr pane run wC:pF 'cd /r && pi -p x'"],
  ["block", "herdr pane run wC:pF 'echo hi | pi -p x'"],
  ["block", "tmux new-session -d 'cd /r && pi -p x'"],
  // rev5: a shell comment never runs, so text inside it is not a spawn
  ["pass", 'true # echo "$(pi -p t)"'],
  ["pass", "# TODO: the guard blocks $(pi -p x) so use hc run"],
  ["pass", 'ls -la # TODO: echo "$(pi -p t)"'],
  // rev5: exec/pane run their first positional as the program, so an agent word
  // inside grep's arguments is not a spawn
  ["pass", "hc exec grep -n pi -p f"],
  ["pass", "herdr pane run wC:pF grep -n pi -p f"],
  // rev5: package runners execute the package they name
  ["block", "npx pi -p x"],
  ["block", "bunx pi -p x"],
  ["block", "pnpm dlx pi -p x"],
  ["block", "uvx pi -p x"],
  ["block", "deno run -A pi -p x"],
  ["pass", "npx skills@1.7.0"],
  // rev5: the definition-only over-block, pinned in isolation too
  ["block", "f() { pi -p x; }"],

  // must pass: interactive spawns
  ["pass", "hc run --bg --name flow-test pi"],
  ["pass", "hc run --bg --name flow-ok claude --model opus"],
  ["pass", "hc run --bg --name amp-test amp"],
  ["pass", "hc run --bg --name flow codex"],
  ["pass", "herdr new --name x goose"],
  ["pass", "herdr pane run wC:pF 'PI_SESSION_NAME=mpd-setup pi'"],
  ["pass", "herdr pane run wC:pF nvim"],
  ["pass", "codex"],

  // must pass: quoting cases that used to block
  ["pass", "grep -n 'NON_INTERACTIVE\\|block' " + HOOK + " | head"],
  ["pass", "echo 'hc run --bg --name flow-test pi -p'"],
  ["pass", `node -e 'const N=/(?:^|\\s)(?:-p|--print|exec)(?:\\s|$)/; console.log(N.test("hc run --bg pi -p"))'`],
  ["pass", "cat > /tmp/spawn-acceptance.sh <<'EOS'\nhc run --bg --name flow-test pi -p 'x'\nEOS"],
  ["pass", "hc send flow-test 'then run pi -p or codex exec, your call'"],
  ["pass", "grep -rn 'codex exec' /home/prm/.agents/AGENTS.md"],
  ["pass", "herdr list | grep pi"],
  ["pass", "ps aux | grep -e pi"],
  ["pass", "echo pi -p"],
  ["pass", "python3 -c 'print(1)'"],
  ["pass", "hc send pi 'run it'"],
  ["pass", "docker run --rm pi"],
  ["pass", "cat notes.md | head -3"],
  ["pass", "pi --help"],
];

let isoFail = 0;
console.log("=== isolated: classify() on the command as typed ===");
console.log("want   got   ok    spawns                       command");
for (const [want, command] of isolated) {
  const spawns = classify(command);
  const got = spawns.some((s) => s.nonInteractive) ? "block" : "pass";
  const ok = got === want;
  if (!ok) isoFail++;
  const names = spawns.map((s) => `${s.agent}${s.nonInteractive ? " (one-shot)" : " (interactive)"}`).join(", ") || "-";
  console.log(
    `${want.padEnd(6)} ${got.padEnd(5)} ${String(ok).padEnd(5)} ${names.padEnd(28)} ${command.replace(/\n/g, "\\n").slice(0, process.env.FIX8_FULL ? 400 : 58)}`,
  );
}
console.log(`\n${isolated.length - isoFail}/${isolated.length} isolated cases passed`);

// ---------------------------------------------------------------- composed ---

const isExtensionFile = (name) => name.endsWith(".ts") || name.endsWith(".js");
const discovered = readdirSync(EXT_DIR, { withFileTypes: true })
  .filter((e) => (e.isFile() || e.isSymbolicLink()) && isExtensionFile(e.name))
  .map((e) => e.name);
const loadOrder = discovered.filter((n) => n === "bash-guard.ts" || n === "herdr-interactive-only.ts");
const orderOk = loadOrder[0] === "bash-guard.ts";

const handlers = [];
for (const name of loadOrder) {
  const mod = await import(pathToFileURL(join(EXT_DIR, name)).href);
  mod.default({ on: (event, handler) => handlers.push({ name, handler }) });
}

console.log("\n=== composed: bash-guard.ts handler then herdr-interactive-only.ts handler, one event ===");
console.log(`discovered (readdirSync, unsorted): ${loadOrder.join(" -> ")}${orderOk ? "" : "   <-- ORDER CHANGED"}`);

async function run(command) {
  const event = { type: "tool_call", toolName: "bash", input: { command } };
  const warned = [];
  const ctx = { ui: { notify: (_message, level) => warned.push(level) } };
  const seen = [];
  let result;
  for (const { name, handler } of handlers) {
    seen.push({ name, command: event.input.command });
    const r = await handler(event, ctx);
    if (r) {
      result = r;
      if (r.block) break;
    }
  }
  const guardSaw = seen.find((s) => s.name === "herdr-interactive-only.ts")?.command;
  const got = result?.block ? "block" : warned.length ? warned[0] : "pass";
  return { got, warned, guardSaw, rewritten: guardSaw !== command, reason: result?.reason };
}

const composed = [
  // the three chained spawns the isolated suite missed in production
  ["block", "cd /repo && pi -p 'summarize the diff'"],
  ["block", "cd /repo && claude -p 'fix the tests'"],
  ["block", "echo 'go' | xargs -n 1 pi -p"],
  // the real one-shots from rev1
  ["block", "hc run --bg --name flow-test pi -p 'summarize the diff'"],
  ["block", "claude -p 'fix the tests' > /tmp/out.txt 2>&1"],
  ["block", "opencode run 'bump the version'"],
  ["block", "sudo -u bot env FOO=1 pi --print 'hello'"],
  // F2 / F3
  ["block", "codex -m gpt-5-codex exec 'port the auth module'"],
  ["block", "sudo -E pi -p 'x'"],
  // nested shells under the bash-guard wrapper
  ["block", "cd /repo && timeout 900 codex exec --full-auto 'add the retry'"],
  ["block", "bash -c 'cd /r && pi -p x'"],
  ["block", "sh -c 'true; claude -p x'"],

  // false positives that must still pass silently
  ["pass", `grep -n 'NON_INTERACTIVE\\|block' ${HOOK} | head`],
  ["pass", "grep -rn 'codex exec' /home/prm/.agents/AGENTS.md"],
  ["pass", "echo 'hc run --bg --name flow-test pi -p'"],
  ["pass", `node -e 'const N=/(?:^|\\s)(?:-p|--print|exec)(?:\\s|$)/; console.log(N.test("hc run --bg pi -p"))'`],
  ["pass", "hc send flow-test 'then run pi -p or codex exec, your call'"],
  ["pass", "cat > /tmp/spawn-acceptance.sh <<'EOS'\nhc run --bg --name flow-test pi -p 'x'\nEOS"],
  ["pass", "herdr list | grep pi"],

  // interactive spawn still gets the report-back warning, not a block
  ["warning", "hc run --bg --name flow-test pi"],
  ["warning", "hc run --bg --name flow-ok claude --model opus"],

  // rev3: the two defects from the rev2 review, five shapes that used to pass
  ["block", "cd /repo && \\\npi -p 'summarize the diff'"],
  ["block", "{ pi -p x; }"],
  ["block", "! pi -p x"],
  ["block", "if true; then pi -p x; fi"],
  ["block", "f() { pi -p x; }\n( pi -p x )"],
  // rev3: a launcher whose agent sits in its argument list
  ["block", "tmux new-session -d pi -p x"],

  // rev4: herdr pane run / hc exec, timeout after the right flag order, and a
  // quoted substitution now asserted to block in isolation and composition alike
  ["block", "herdr pane run wC:pF 'pi -p t'"],
  ["warning", "herdr pane run wC:pF 'PI_SESSION_NAME=mpd-setup pi'"],
  ["block", "hc exec pi -p x"],
  ["block", "hc exec bash -c 'pi -p x'"],
  ["block", "timeout 5 -s KILL pi -p x"],
  ["block", 'echo "$(pi -p t)"'],
  ["pass", "echo '$(pi -p t)'"],
  // rev4: deliberate fail-closed over-block, recorded so it is not "fixed"
  ["block", "hc run --bg nvim pi -p x"],
  ["block", "f() { pi -p x; }"],

  // rev5: a chained quoted pane payload, a comment, the exec/pane program rule,
  // and the package runners, under the real bash-guard rewrite
  ["block", "herdr pane run wC:pF 'cd /r && pi -p x'"],
  ["pass", 'true # echo "$(pi -p t)"'],
  ["pass", "hc exec grep -n pi -p f"],
  ["pass", "herdr pane run wC:pF grep -n pi -p f"],
  ["block", "npx pi -p x"],
  ["block", "deno run -A pi -p x"],
  ["pass", "npx skills@1.7.0"],

  // rev3: the documented gaps, asserted as pass so they stay gaps
  ["pass", "ssh box pi -p t"],
  ["pass", "docker run --rm pi -p t"],
  ["pass", "systemd-run --user --scope pi -p t"],
  ["pass", "eval 'pi -p t'"],
  ["pass", "bash /tmp/spawn.sh"],
  ["pass", "bash <<EOS\npi -p t\nEOS"],
  // rev4: no longer a gap — both quoting forms of a substitution are scanned
  ["block", 'bash -c "echo $(pi -p t)"'],
];

let compFail = 0;
console.log("want     got      ok    rewrit  command");
const sample = [];
for (const [want, command] of composed) {
  const { got, rewritten, guardSaw } = await run(command);
  const ok = got === want;
  if (!ok) compFail++;
  if (!rewritten) compFail++; // the composition must be real, not simulated
  if (sample.length < 1) sample.push({ command, guardSaw });
  console.log(
    `${want.padEnd(8)} ${got.padEnd(8)} ${String(ok && rewritten).padEnd(5)} ${String(rewritten).padEnd(7)} ${command.replace(/\n/g, "\\n").slice(0, process.env.FIX8_FULL ? 400 : 52)}`,
  );
}
for (const { command, guardSaw } of sample) {
  console.log(`\nwhat the guard received after bash-guard's rewrite:\n  ${JSON.stringify(command).slice(0, 80)}...\n  ${JSON.stringify(guardSaw)}`);
}
console.log(`\n${composed.length - compFail}/${composed.length} composed cases passed`);

const total = isolated.length + composed.length;
const failed = isoFail + compFail;
console.log(`\n${total - failed}/${total} cases passed (${isolated.length} isolated, ${composed.length} composed)`);

// ------------------------------------------------------------- control ---

let controlOk = true;
if (!process.env.FIX8_CONTROL) {
  const child = spawnSync(process.execPath, [new URL(import.meta.url).pathname], {
    env: { ...process.env, FIX8_EXT_DIR: REV1_DIR, FIX8_CONTROL: "1" },
    encoding: "utf8",
  });
  const failing = (child.stdout ?? "").split("\n").filter((line) => /^(block|pass|warning)\b.*\bfalse\b/.test(line));
  controlOk = child.status !== 0 && failing.length > 0;
  console.log(`\n=== negative control: rev1 extension under the same suite ===`);
  console.log(`${child.status === 0 ? "UNEXPECTED: rev1 passed" : `rev1 still fails, exit ${child.status}`} — ${failing.length} cases failing`);
  for (const line of failing) console.log(`  ${line.slice(0, 78)}`);
  console.log(controlOk ? "control ok: a green run cannot be a harness artefact" : "CONTROL BROKEN: rev1 no longer fails");
}

process.exit(failed === 0 && orderOk && controlOk ? 0 : 1);
