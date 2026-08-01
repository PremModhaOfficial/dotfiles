import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { readFileSync } from "fs";
import { execSync } from "child_process";
import { homedir } from "os";
import { join } from "path";

const HRAGENT_DIR = join(homedir(), ".pi", "agent", "hragent");
const SPAWN_SCRIPT = join(HRAGENT_DIR, "spawn.sh");
const PROTOCOL = join(HRAGENT_DIR, "PROTOCOL.md");
const LEARNINGS = join(HRAGENT_DIR, "LEARNINGS.md");

const ROLE_PROMPTS = [
  "You are the researcher. Investigate, gather facts, report findings.",
  "You are the implementer. Write code, make changes, report what you did.",
  "You are the reviewer. Review the work, find issues, report verdicts.",
  "You are the tester. Write and run tests, report pass/fail.",
  "You are the documenter. Write docs, READMEs, comments, report what you wrote.",
  "You are the optimizer. Profile, benchmark, suggest improvements, report results.",
  "You are the integrator. Merge changes, resolve conflicts, report status.",
];

export default function hragentExtension(pi: ExtensionAPI) {
  pi.registerCommand("hragent", {
    description: "Spawn subagents via herdr, delegate tasks via intercom. Usage: /hragent <task> [workers=N]",
    handler: async (args, ctx: ExtensionContext) => {
      const parts = args.trim().split(/\s+/);
      const taskParts: string[] = [];
      let workers = 0; // 0 = auto-detect from task complexity

      for (const p of parts) {
        if (p.startsWith("workers=")) {
          workers = Math.max(parseInt(p.split("=")[1], 10) || 0, 0);
        } else {
          taskParts.push(p);
        }
      }

      const task = taskParts.join(" ") || "unspecified task";

      // Auto-detect worker count if not specified: 1 for simple tasks, 3 for complex
      if (workers === 0) {
        const wordCount = task.split(/\s+/).length;
        workers = wordCount > 20 ? 5 : wordCount > 8 ? 3 : 1;
      }

      // Detect main agent name for intercom routing
      let mainName = "";
      try {
        const listOut = execSync("herdr agent list", { encoding: "utf-8" });
        const agents = JSON.parse(listOut).result?.agents || [];
        // The main agent is the one that's focused (or the first non-worker)
        const mainAgent = agents.find((a: any) => a.focused && !a.name?.startsWith("hragent-"))
          || agents.find((a: any) => !a.name?.startsWith("hragent-"));
        mainName = mainAgent?.name || mainAgent?.agent_session?.value?.split("/").pop()?.replace(/\.jsonl$/, "") || "";
      } catch {
        // ok — workers will just use "main" as fallback
      }

      // Load protocol and learnings
      let protocolContent = "";
      try {
        protocolContent = readFileSync(PROTOCOL, "utf-8");
      } catch {
        ctx.ui.notify("Protocol file not found at " + PROTOCOL, "error");
        return;
      }

      let learningsContent = "";
      try {
        learningsContent = readFileSync(LEARNINGS, "utf-8");
      } catch {
        // ok
      }

      // Build worker names and role-specific task slices
      const workerNames = Array.from({ length: workers }, (_, i) => `hragent-w${i + 1}`);
      const taskSlices = workers === 1
        ? [task]
        : workerNames.map((_, i) => {
            const role = ROLE_PROMPTS[i % ROLE_PROMPTS.length];
            return `${role}\n\nTask: ${task}\n\nYou are worker ${i + 1} of ${workers}. Focus on your role. CC main agent on all status messages.`;
          });

      const workerInfoLines = workerNames.map((n, i) => {
        const role = ROLE_PROMPTS[i % ROLE_PROMPTS.length].split(".")[0].replace("You are the ", "");
        return `${n} (${role})`;
      });

      // Build spawn commands
      const spawnCommands = workerNames
        .map((n, i) => {
          const safeSlice = taskSlices[i].replace(/"/g, '\\"').replace(/\n/g, " ");
          const mainFlag = mainName ? ` --main "${mainName}"` : "";
          return `bash ${SPAWN_SCRIPT} "${n}" --cwd "${ctx.cwd}"${mainFlag} --task "${safeSlice}"`;
        })
        .join("\n");

      pi.appendEntry("hragent_session", {
        task,
        workers: workerNames,
        workerTasks: workerInfoLines,
      });

      ctx.ui.notify(
        `hragent: ${workers} workers for "${task.length > 40 ? task.slice(0, 40) + "..." : task}"`,
        "info",
      );

      const responseLines = [
        `## hragent: ${workers} workers for "${task}"`,
        "",
        "### Protocol",
        "```",
        protocolContent,
        "```",
        "",
        "### Workers",
        ...workerInfoLines.map((l) => `- ${l}`),
        "",
        "### Spawn commands",
        "```bash",
        spawnCommands,
        "```",
        "",
        learningsContent ? "### Past learnings\n" + learningsContent : "",
        "",
        "### Rules (follow PROTOCOL.md BY_LAW strictly)",
        "1. Run spawn commands — wait for all [ACK] before proceeding",
        "2. Workers push status — you never poll, never ask for status",
        "3. On [DONE]: send next task if more work, else wait for [FIN]",
        "4. On [FAIL]: retry up to 2 times via send, then report",
        "5. On [HELP]/[HUMN]: answer if you can, relay to user if you can't",
        "6. On [FIN] from all: summarize, teardown via herdr pane close <pane_id>",
      ];

      pi.sendMessage(
        {
          customType: "hragent_instructions",
          content: responseLines.join("\n"),
          display: true,
          details: { task, workers: workerNames, workerTasks: workerInfoLines, spawnCommands },
        },
        { triggerTurn: true },
      );
    },
  });
}
