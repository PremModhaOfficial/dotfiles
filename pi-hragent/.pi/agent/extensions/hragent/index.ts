import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { readFileSync } from "fs";
import { homedir } from "os";
import { join } from "path";

const HRAGENT_DIR = join(homedir(), ".pi", "agent", "hragent");
const SPAWN_SCRIPT = join(HRAGENT_DIR, "spawn.sh");
const PROTOCOL = join(HRAGENT_DIR, "PROTOCOL.md");
const MAX_WORKERS = 7;
const RETRY_LIMIT = 2;

interface WorkerSpec {
  name: string;
  task: string;
  paneId?: string;
  status: "spawning" | "ready" | "working" | "done" | "failed";
  retries: number;
}

interface HragentSession {
  workers: WorkerSpec[];
  task: string;
  startTime: number;
}

export default function hragentExtension(pi: ExtensionAPI) {
  pi.registerCommand("hragent", {
    description: "Spawn subagents via herdr, delegate tasks via intercom protocol. Usage: /hragent <task> [workers=N]",
    handler: async (args, ctx: ExtensionContext) => {
      const parts = args.trim().split(/\s+/);
      const taskParts: string[] = [];
      let workers = 3; // default

      for (const p of parts) {
        if (p.startsWith("workers=")) {
          workers = parseInt(p.split("=")[1], 10);
          if (isNaN(workers) || workers < 1) workers = 1;
          if (workers > MAX_WORKERS) workers = MAX_WORKERS;
        } else {
          taskParts.push(p);
        }
      }

      const task = taskParts.join(" ") || "unspecified task";

      // Read protocol
      let protocolContent = "";
      try {
        protocolContent = readFileSync(PROTOCOL, "utf-8");
      } catch {
        ctx.ui.notify("Protocol file not found at " + PROTOCOL, "error");
        return;
      }

      // Read leanings (main agent uses these to avoid past mistakes)
      let learningsContent = "";
      try {
        learningsContent = readFileSync(join(HRAGENT_DIR, "LEARNINGS.md"), "utf-8");
      } catch {
        // ok
      }

      // Create the session tracking entry
      const session: HragentSession = {
        workers: [],
        task,
        startTime: Date.now(),
      };

      // Determine worker names
      const workerNames: string[] = [];
      for (let i = 1; i <= workers; i++) {
        workerNames.push(`hragent-w${i}`);
      }

      // Build worker specs
      for (const wName of workerNames) {
        session.workers.push({
          name: wName,
          task: "",
          status: "spawning",
          retries: 0,
        });
      }

      // Split task into slices for each worker
      const taskSlices = workers === 1
        ? [task]
        : workerNames.map((name, i) => `[hragent slice ${i + 1}/${workers}] ${task} — work on a distinct subtask and report findings. Always CC main agent on all status messages.`);

      const workerInfoLines = workerNames.map((n, i) => {
        const slice = taskSlices[i] || task;
        return `${n}: ${slice.slice(0, 120)}${slice.length > 120 ? "..." : ""}`;
      });

      // Build spawn commands with --task for each worker
      const spawnCommands = workerNames
        .map((n, i) => {
          const slice = taskSlices[i] || task;
          // Escape double quotes in task for shell safety
          const safeSlice = slice.replace(/"/g, '\\"');
          return `bash ${SPAWN_SCRIPT} "${n}" --cwd "${ctx.cwd}" --split window --task "${safeSlice}"`;
        })
        .join("\n");

      // Store session in pi entries so the main agent can access it
      pi.appendEntry("hragent_session", {
        task,
        workers: session.workers.map((w) => ({ name: w.name, status: w.status })),
        workerTasks: workerInfoLines,
        protocolSection: "protocol loaded below",
      });

      ctx.ui.notify(
        `hragent: ${workers} workers for "${task.length > 40 ? task.slice(0, 40) + "..." : task}"`,
        "info",
      );

      // The agent gets this in context via the response
      const responseLines = [
        `## hragent: ${workers} workers for "${task}"`,
        "",
        "### Protocol (loaded into context)",
        "```",
        protocolContent,
        "```",
        "",
        learningsContent ? "### Past learnings (prevent repeat mistakes)\n" + learningsContent : "",
        "",
        "### Worker assignments",
        ...workerInfoLines.map((l) => `- ${l}`),
        "",
        "### Spawn commands (run these first)",
        "These spawn panes AND send the task (which triggers intercom name sync).",
        "```bash",
        spawnCommands,
        "```",
        "",
        "### Orchestration steps (pub-sub only)",
        "1. Run the spawn commands above — each spawns a window, sets the name, AND sends the first task",
        `   The task message triggers a turn → intercom syncs name → worker starts working`,
        "2. Wait for workers to push [DONE]/[FAIL] via intercom send — never ask, never poll",
        "3. On [HELP]/[HUMN] — relay to user (reply via send, never ask)",
        "4. On [FAIL] — retry up to 2 times via send, then report",
        "5. Workers always CC main on all messages",
        "6. When all workers report [FIN] — summarize and hand back to user",
        "",
        "### Worker names to pane mapping (from spawn output)",
        ...workerNames.map((n) => `- ${n}: (pane_id from spawn output)`),
        "",
        "### Intercom targeting (pub-sub only — never ask)",
        ...workerNames.map((n) => `- send: intercom({ action: "send", to: "${n}", message: "[GO] >${n}: ..." })`),
        "",
        "### Teardown",
        "```bash",
        "herdr pane close <pane_id_for_each_worker>",
        "```",
      ];

      pi.sendMessage(
        {
          customType: "hragent_instructions",
          content: responseLines.join("\n"),
          display: true,
          details: {
            task,
            workers: session.workers.map((w) => w.name),
            workerTasks: workerInfoLines,
            protocolLoaded: true,
            spawnCommands,
          },
        },
        { triggerTurn: true },
      );
    },
  });
}
