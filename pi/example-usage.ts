/**
 * Example: Using the Async Event Loop with Pi Agent
 */

import { eventLoop } from "./event-loop";

// ======================
// 1. Register Handlers
// ======================

// Handler for reading files
eventLoop.registerHandler("read", async (cmd) => {
  const { path } = cmd.args;
  console.log(`📖 Reading: ${path}`);
  // Simulate async operation
  await new Promise((r) => setTimeout(r, 500));
  return { content: `File content of ${path}` };
});

// Handler for running bash commands
eventLoop.registerHandler("bash", async (cmd) => {
  const { command } = cmd.args;
  console.log(`🔧 Running: ${command}`);
  await new Promise((r) => setTimeout(r, 300));
  return { stdout: `Output of: ${command}` };
});

// Handler for writing files
eventLoop.registerHandler("write", async (cmd) => {
  const { path, content } = cmd.args;
  console.log(`✍️  Writing: ${path}`);
  await new Promise((r) => setTimeout(r, 400));
  return { success: true, path };
});

// ======================
// 2. Listen to Events
// ======================

// Log when commands start
eventLoop.on("command:started", (cmd) => {
  console.log(`⏱️  [${cmd.id}] Starting: ${cmd.name}`);
});

// Log success
eventLoop.on("command:success", (result) => {
  console.log(
    `✅ [${result.id}] Success (${result.duration}ms) - Result:`,
    result.result
  );
});

// Log errors
eventLoop.on("command:error", (result) => {
  console.log(
    `❌ [${result.id}] Error (${result.duration}ms) - ${result.error?.message}`
  );
});

// ======================
// 3. Queue Commands
// ======================

async function example() {
  // Start the event loop (runs in background)
  const loopPromise = eventLoop.start();

  // Queue some commands
  const readId = eventLoop.enqueue("read", { path: "/etc/config.json" });
  const bashId = eventLoop.enqueue("bash", { command: "ls -la" });
  const writeId = eventLoop.enqueue("write", {
    path: "/tmp/output.txt",
    content: "Hello, World!",
  });

  console.log("\n📤 Commands queued!\n");

  // Wait for all to complete
  try {
    const [readResult, bashResult, writeResult] = await Promise.all([
      eventLoop.waitFor(readId),
      eventLoop.waitFor(bashId),
      eventLoop.waitFor(writeId),
    ]);

    console.log("\n📊 All done! Stats:", eventLoop.getStats());
  } catch (err) {
    console.error("Error:", err);
  }

  // Stop the loop
  await eventLoop.stop();
}

// Run the example
example().catch(console.error);
