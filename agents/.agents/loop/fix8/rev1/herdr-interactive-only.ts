// Herdr/HC agents must be interactive sessions that report back.
// A `pi -p` (or `claude -p`, `codex exec`, `opencode run`) spawn is fire-and-forget:
// the parent cannot see progress, cannot answer questions, and cannot stop it.
//
// The check parses the command instead of grepping it, because words inside
// arguments are not actions: `grep "pi -p"` and `node -e '...-p...'` are not
// spawns, and neither is a heredoc body written to a file. Only an agent CLI
// invoked as the executed binary (directly, under a wrapper, or as the agent
// argument of `hc run`/`herdr new`) counts.
//
// What it still cannot see: script files (`bash x.sh`), heredoc bodies piped
// into a shell, `$(...)`/backticks inside double quotes, variables, aliases.
import { type ExtensionAPI, isToolCallEventType } from "@earendil-works/pi-coding-agent";

export type AgentName = "pi" | "claude" | "codex" | "opencode" | "goose" | "amp";
export type Spawn = { agent: AgentName; nonInteractive: boolean };

const AGENTS = new Set<string>(["pi", "claude", "codex", "opencode", "goose", "amp"]);
const AGENT_ONE_SHOT_FLAGS = new Set(["-p", "--print"]);
const HARNESSES = new Set(["hc", "herdr"]);
const SPAWN_SUBCOMMANDS = new Set(["run", "new", "spawn", "agent", "start"]);
const SHELLS = new Set(["bash", "sh", "zsh", "dash", "ksh"]);
const WRAPPERS = new Set([
  "env", "sudo", "doas", "timeout", "xargs", "nice", "nohup", "stdbuf", "setsid", "time", "exec", "command",
]);
// Flags that swallow the next token as their value, so the value is not mistaken
// for the invoked binary (`sudo -u bot pi`, `xargs -n 1 pi`, `--name flow-test pi`).
const VALUE_FLAGS = new Set([
  "-u", "-g", "-s", "-k", "-n", "-I", "-P", "-L", "-E", "-a", "-d", "-e",
  "--user", "--group", "--signal", "--kill-after", "--max-args", "--replace",
  "--max-procs", "--delimiter", "--arg-file", "--name", "--cwd", "--dir",
  "--label", "--workspace", "--tab", "--shell", "--env", "--timeout",
]);
const MAX_DEPTH = 3;
const REPORTING = /intercom|hc send|send-keys|report back|report progress|message me|notify the parent/i;

function base(token: string): string {
  return token.slice(token.lastIndexOf("/") + 1);
}

// Drop heredoc bodies: they are data handed to a command, not commands.
function stripHeredocs(command: string): string {
  const lines = command.split("\n");
  const kept: string[] = [];
  for (let i = 0; i < lines.length; i++) {
    kept.push(lines[i]);
    const marker = lines[i].match(/<<-?\s*(['"]?)([A-Za-z_][A-Za-z0-9_]*)\1/);
    if (!marker) continue;
    for (i++; i < lines.length && lines[i].trim() !== marker[2]; i++);
  }
  return kept.join("\n");
}

// Split into words and `;` segment separators, honouring quotes, escaping and
// dropping redirects and their targets (`2>&1`, `>/dev/null`, `<<EOS`).
export function tokenize(command: string): string[] {
  const tokens: string[] = [];
  let word = "";
  let quoted = false;
  let quote: "" | "'" | '"' = "";
  const flush = () => {
    if (quoted) tokens.push(word);
    word = "";
    quoted = false;
  };
  for (let i = 0; i < command.length; i++) {
    const ch = command[i];
    if (quote) {
      if (ch === quote) quote = "";
      else if (ch === "\\" && quote === '"' && i + 1 < command.length) word += command[++i];
      else word += ch;
      continue;
    }
    if (ch === "'" || ch === '"') {
      quote = ch;
      quoted = true;
      continue;
    }
    if (ch === "\\" && i + 1 < command.length) {
      word += command[++i];
      quoted = true;
      continue;
    }
    if (ch === " " || ch === "\t") {
      flush();
      continue;
    }
    if (ch === "\n" || ch === ";" || ch === "&" || ch === "|" || ch === "(" || ch === ")") {
      if (/^\d+$/.test(word)) word = ""; // file descriptor before `>`
      flush();
      while (command[i + 1] === "&" || command[i + 1] === "|") i++; // &&, ||, |&
      tokens.push(";");
      continue;
    }
    if (ch === ">" || ch === "<") {
      if (/^\d+$/.test(word)) word = "";
      flush();
      while (command[i + 1] === ">" || command[i + 1] === "<") i++;
      while (i + 1 < command.length && /\s/.test(command[i + 1])) i++;
      if (command[i + 1] === "&") i++;
      while (i + 1 < command.length && !/[\s;&|<>()]/.test(command[i + 1])) i++;
      continue;
    }
    word += ch;
    quoted = true;
  }
  flush();
  return tokens;
}

function isOneShot(agent: AgentName, args: string[]): boolean {
  const subcommand = args.find((arg) => !arg.startsWith("-"));
  if (agent === "codex") return subcommand === "exec";
  if (agent === "opencode" || agent === "goose") return subcommand === "run";
  if (agent === "amp") return args.some((arg) => arg === "-x" || arg === "--execute" || AGENT_ONE_SHOT_FLAGS.has(arg));
  return args.some((arg) => AGENT_ONE_SHOT_FLAGS.has(arg));
}

// Index just past the wrapper's own flags (`sudo -u bot`, `xargs -n 1`).
function skipFlags(tokens: string[], from: number): number {
  let i = from;
  while (i < tokens.length && tokens[i].startsWith("-")) {
    const flag = tokens[i++];
    if (flag.length <= 2 && VALUE_FLAGS.has(flag) && i < tokens.length) i++;
  }
  return i;
}

function analyze(tokens: string[], depth: number, found: Spawn[]): void {
  if (depth > MAX_DEPTH) return;

  let i = 0;
  for (;;) {
    const token = tokens[i];
    if (token === undefined) return;
    if (/^[A-Za-z_][A-Za-z0-9_]*=/.test(token)) {
      i++; // env prefix: `FOO=bar pi`
      continue;
    }
    if (!WRAPPERS.has(base(token))) break;
    i = skipFlags(tokens, i + 1);
    if (base(token) === "timeout" && /^[\d.]+[smhd]?$/.test(tokens[i] ?? "")) i++;
  }

  const exe = base(tokens[i]);
  const args = tokens.slice(i + 1);

  if (SHELLS.has(exe)) {
    const cIndex = args.findIndex((arg) => /^-[a-zA-Z]*c$/.test(arg));
    if (cIndex > -1 && args[cIndex + 1] !== undefined) {
      analyze(tokenize(stripHeredocs(args[cIndex + 1])), depth + 1, found);
    }
    return;
  }

  if (AGENTS.has(exe)) {
    found.push({ agent: exe as AgentName, nonInteractive: isOneShot(exe as AgentName, args) });
    return;
  }

  if (HARNESSES.has(exe)) {
    const subcommand = tokens[skipFlags(tokens, i + 1)];
    if (subcommand === undefined || !SPAWN_SUBCOMMANDS.has(subcommand)) return;
    for (let k = skipFlags(tokens, i + 2); k < tokens.length; k++) {
      const token = tokens[k];
      if (token.startsWith("-")) {
        if (!token.includes("=") && VALUE_FLAGS.has(token)) k++; // flag value
        continue;
      }
      if (!AGENTS.has(base(token))) continue;
      const agent = base(token) as AgentName;
      found.push({ agent, nonInteractive: isOneShot(agent, tokens.slice(k + 1)) });
      return;
    }
  }
}

/** Every agent spawn the command actually executes. */
export function classify(command: string): Spawn[] {
  const found: Spawn[] = [];
  let segment: string[] = [];
  for (const token of [...tokenize(stripHeredocs(command)), ";"]) {
    if (token === ";") {
      analyze(segment, 0, found);
      segment = [];
    } else segment.push(token);
  }
  return found;
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("bash", event)) return;
    const command = event.input.command ?? "";
    const spawns = classify(command);
    if (spawns.length === 0) return;

    const oneShot = spawns.find((spawn) => spawn.nonInteractive);
    if (oneShot) {
      return {
        block: true,
        reason:
          `\`${oneShot.agent}\` is being spawned non-interactively (${oneShot.agent === "codex" ? "exec" : oneShot.agent === "opencode" || oneShot.agent === "goose" ? "run" : "-p/--print"}). ` +
          "Herdr agent spawns must be interactive sessions, not one-shots. " +
          "A non-interactive agent cannot ask you anything, cannot be steered mid-run, and its output " +
          "is invisible to the parent session. Start the agent interactively in a Herdr pane " +
          "(`hc run --bg pi` with no `-p`, then `hc send <name> '<task>'` and `hc read <name>`), and make " +
          "the task text tell it to report back: send progress and questions to the parent via the " +
          "intercom tool (or `hc send <parent>`).",
      };
    }

    if (!REPORTING.test(command)) {
      ctx.ui.notify(
        "Herdr agent spawned without a reporting instruction — add one so it talks back to this session.",
        "warning",
      );
    }
  });
}
