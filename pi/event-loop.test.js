/**
 * Test Suite for Async Event Loop (JavaScript)
 * Run with: node event-loop.test.js
 */

const { EventLoop } = require("./event-loop.js");

async function test(name, fn) {
  try {
    console.log(`\n🧪 Test: ${name}`);
    await fn();
    console.log(`✅ Passed`);
  } catch (err) {
    console.error(`❌ Failed: ${err.message}`);
    console.error(err.stack);
    process.exit(1);
  }
}

async function assert(condition, message) {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
}

async function assertEquals(actual, expected, message) {
  if (actual !== expected) {
    throw new Error(
      `${message}\nExpected: ${expected}\nActual: ${actual}`
    );
  }
}

// Test Suite
async function runTests() {
  console.log("🚀 Running Event Loop Tests\n");

  // Test 1: Basic command registration and execution
  await test("Register handler and execute command", async () => {
    const loop = new EventLoop();
    let executed = false;

    loop.registerHandler("test", async () => {
      executed = true;
      return { ok: true };
    });

    loop.on("command:success", () => {
      // Event fired
    });

    const id = loop.enqueue("test");
    const loopPromise = loop.start();

    const result = await loop.waitFor(id);
    await loop.stop();

    await assert(executed, "Handler should be executed");
    await assertEquals(result.status, "success", "Command should succeed");
    await assertEquals(result.result.ok, true, "Result should have ok: true");
  });

  // Test 2: Multiple commands in order
  await test("Execute multiple commands in order", async () => {
    const loop = new EventLoop();
    const order = [];

    loop.registerHandler("cmd", async (cmd) => {
      order.push(cmd.args.id);
      await new Promise((r) => setTimeout(r, 10));
      return { id: cmd.args.id };
    });

    const id1 = loop.enqueue("cmd", { id: "first" });
    const id2 = loop.enqueue("cmd", { id: "second" });
    const id3 = loop.enqueue("cmd", { id: "third" });

    const loopPromise = loop.start();

    await Promise.all([
      loop.waitFor(id1),
      loop.waitFor(id2),
      loop.waitFor(id3),
    ]);

    await loop.stop();

    await assertEquals(order[0], "first", "First should execute first");
    await assertEquals(order[1], "second", "Second should execute second");
    await assertEquals(order[2], "third", "Third should execute third");
  });

  // Test 3: Error handling
  await test("Handle command errors", async () => {
    const loop = new EventLoop();
    let errorEmitted = false;

    loop.registerHandler("error", async () => {
      throw new Error("Test error");
    });

    loop.on("command:error", () => {
      errorEmitted = true;
    });

    const id = loop.enqueue("error");
    const loopPromise = loop.start();

    try {
      await loop.waitFor(id);
      throw new Error("Should have thrown");
    } catch (err) {
      // Expected
    }

    await loop.stop();
    await assert(errorEmitted, "Error event should be emitted");
  });

  // Test 4: Event listeners
  await test("Event listeners work correctly", async () => {
    const loop = new EventLoop();
    const events = [];

    loop.on("command:started", () => events.push("started"));
    loop.on("command:success", () => events.push("success"));

    loop.registerHandler("test", async () => {
      await new Promise((r) => setTimeout(r, 5));
      return { ok: true };
    });

    const id = loop.enqueue("test");
    const loopPromise = loop.start();
    await loop.waitFor(id);
    await loop.stop();

    await assert(
      events.includes("started"),
      "Should emit started event"
    );
    await assert(
      events.includes("success"),
      "Should emit success event"
    );
  });

  // Test 5: Once listener
  await test("Once listener fires only once", async () => {
    const loop = new EventLoop();
    let count = 0;

    loop.once("command:success", () => {
      count++;
    });

    loop.registerHandler("test", async () => ({ ok: true }));

    const id1 = loop.enqueue("test");
    const id2 = loop.enqueue("test");

    const loopPromise = loop.start();
    await loop.waitFor(id1);
    await loop.waitFor(id2);
    await loop.stop();

    await assertEquals(count, 1, "Once listener should fire only once");
  });

  // Test 6: Handler not found
  await test("Throw error when handler not found", async () => {
    const loop = new EventLoop();
    const id = loop.enqueue("nonexistent");

    const loopPromise = loop.start();

    try {
      await loop.waitFor(id);
      throw new Error("Should have thrown");
    } catch (err) {
      await assert(
        err.message.includes("No handler registered"),
        "Should throw handler not found error"
      );
    }

    await loop.stop();
  });

  // Test 7: Get result
  await test("Get result synchronously", async () => {
    const loop = new EventLoop();

    loop.registerHandler("test", async () => ({ value: 42 }));

    const id = loop.enqueue("test");
    const loopPromise = loop.start();
    await loop.waitFor(id);

    const result = loop.getResult(id);
    await loop.stop();

    await assert(result !== undefined, "Result should be available");
    await assertEquals(result.status, "success", "Status should be success");
    await assertEquals(result.result.value, 42, "Value should be 42");
  });

  // Test 8: Stats
  await test("Get accurate stats", async () => {
    const loop = new EventLoop();
    let successCount = 0;
    let errorCount = 0;

    loop.on("command:success", () => {
      successCount++;
    });

    loop.on("command:error", () => {
      errorCount++;
    });

    loop.registerHandler("ok", async () => ({ ok: true }));
    loop.registerHandler("bad", async () => {
      throw new Error("Bad");
    });

    const id1 = loop.enqueue("ok");
    const id2 = loop.enqueue("ok");
    const id3 = loop.enqueue("bad");

    const loopPromise = loop.start();
    await loop.waitFor(id1);
    await loop.waitFor(id2);
    await loop.waitFor(id3);
    await loop.stop();

    const stats = loop.getStats();
    await assertEquals(stats.successCount, 2, "Should have 2 successes");
    await assertEquals(stats.errorCount, 1, "Should have 1 error");
    await assertEquals(stats.totalResults, 3, "Should have 3 total results");
  });

  // Test 9: Timeout on waitFor
  await test("Timeout on waitFor", async () => {
    const loop = new EventLoop();
    let timedOut = false;

    loop.registerHandler("slow", async () => {
      await new Promise((r) => setTimeout(r, 5000));
      return { ok: true };
    });

    const id = loop.enqueue("slow");
    const loopPromise = loop.start();

    try {
      await loop.waitFor(id, 100); // 100ms timeout
    } catch (err) {
      timedOut = err.message.includes("timed out");
    }

    await loop.stop();
    await assert(timedOut, "Should timeout");
  });

  // Test 10: Unsubscribe from listener
  await test("Unsubscribe from listener", async () => {
    const loop = new EventLoop();
    let count = 0;

    const unsubscribe = loop.on("command:success", () => {
      count++;
    });

    loop.registerHandler("test", async () => ({ ok: true }));

    const id1 = loop.enqueue("test");
    const loopPromise = loop.start();
    await loop.waitFor(id1);

    unsubscribe(); // Unsubscribe

    const id2 = loop.enqueue("test");
    await loop.waitFor(id2);
    await loop.stop();

    // Count should still be 1 because we unsubscribed
    await assertEquals(count, 1, "Should only fire once after unsubscribe");
  });

  console.log("\n✅ All tests passed!\n");
}

// Run tests
runTests().catch((err) => {
  console.error("Test suite failed:", err);
  process.exit(1);
});
