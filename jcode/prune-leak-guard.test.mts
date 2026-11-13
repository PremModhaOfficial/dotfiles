// Smoke test for ~/.pi/agent/extensions/prune-leak-guard.ts.
// Run: ~/.pi/agent/npm/node_modules/.bin/tsx prune-leak-guard.test.mts
//
// The ctx here mirrors pi's real ExtensionContext subset the hook uses:
// sessionManager.getSessionFile(). PI_SESSION_FILE is deliberately NOT set,
// because it exists only inside bash tool subprocesses — a hook that depends on
// it never runs, and case 1 is what catches that.

import ext from "/home/prm/.pi/agent/extensions/prune-leak-guard.ts";

type Handler = (event: unknown, ctx: unknown) => Promise<unknown>;
const handlers: Record<string, Handler> = {};

const SESSION = "/tmp/guard-test-session.jsonl";
const CHECK = "/home/prm/dotfiles/jcode/prune-leak-check.py";

let execCalls: string[][] = [];
const notified: Array<{ message: string; type?: string }> = [];
let fakeCode = 0;
let fakeKilled = false;
let fakeOut = "";

const fakePi = {
  on(name: string, handler: Handler) {
    handlers[name] = handler;
    return () => {};
  },
  async exec(command: string, args: string[]) {
    execCalls.push([command, ...args]);
    return { stdout: fakeOut, stderr: "", code: fakeCode, killed: fakeKilled, truncated: false };
  },
};

const factory = typeof ext === "function" ? ext : (ext as { default: unknown }).default;
assert(typeof factory === "function", `extension export is ${typeof ext}, not a function`);
(factory as (pi: unknown) => void)(fakePi);

const run = handlers["turn_end"];
assert(Boolean(run), "no turn_end handler registered");

// pi's real shape, and no PI_SESSION_FILE in the environment.
delete process.env.PI_SESSION_FILE;
const ctx = {
  ui: { notify: (message: string, type?: string) => notified.push({ message, type }) },
  sessionManager: { getSessionFile: () => SESSION },
};

const realNow = Date.now;
const later = (ms: number) => {
  Date.now = () => realNow() + ms;
};

// 1. one turn with no env var: the check must still run, on the ctx session file.
await run({ turnIndex: 1 }, ctx);
assert(execCalls.length === 1, `expected 1 exec from ctx.sessionManager, got ${execCalls.length}`);
assert(execCalls[0][0] === "python3", `expected python3, got ${execCalls[0][0]}`);
assert(execCalls[0][1] === CHECK, `expected ${CHECK}, got ${execCalls[0][1]}`);
assert(execCalls[0][2] === SESSION, `session path not passed: ${execCalls[0][2]}`);
assert(notified.length === 0, "a clean run must not notify");

// 2. immediate turn: throttled, no second exec.
await run({ turnIndex: 2 }, ctx);
assert(execCalls.length === 1, "throttle not applied");

// 3. after the interval, a leak notifies with the report and strips the summary line.
fakeCode = 1;
fakeOut = "s.jsonl:9: edit carries <tag> in an argument: x\nscanned 1 file(s): 1 leak(s)\n";
later(60_000);
await run({ turnIndex: 3 }, ctx);
Date.now = realNow;
assert(execCalls.length === 2, "second scan expected after the interval");
assert(notified.length === 1, `one notify expected, got ${notified.length}`);
assert(notified[0].type === "warning", `expected warning, got ${notified[0].type}`);
assert(notified[0].message.includes("s.jsonl:9"), `report missing: ${notified[0].message}`);
assert(!notified[0].message.includes("scanned"), "summary line should be stripped");

// 4. exit 2 (unreadable) must be surfaced, not swallowed.
fakeCode = 2;
later(120_000);
await run({ turnIndex: 4 }, ctx);
Date.now = realNow;
assert(notified.length === 2, "exit 2 must notify");
assert(notified[1].type === "error", `expected error for exit 2, got ${notified[1].type}`);

// 5. a killed run must be surfaced too.
fakeCode = 0;
fakeKilled = true;
later(180_000);
await run({ turnIndex: 5 }, ctx);
Date.now = realNow;
assert(notified.length === 3, "killed run must notify");

// 6. no session file: nothing to scan, no exec.
const before = execCalls.length;
later(240_000);
await run({ turnIndex: 6 }, { ...ctx, sessionManager: { getSessionFile: () => undefined } });
Date.now = realNow;
assert(execCalls.length === before, "must not exec without a session file");

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) {
    console.error("FAIL:", message);
    process.exit(1);
  }
}

console.log(`guard smoke ok: 6 cases, ${execCalls.length} exec(s), ${notified.length} notify`);
