# Async Event Loop for Pi Agent ⚡

A **dead simple, clean, and extensible** async event loop for running pi commands asynchronously with a queue-based architecture.

## Features ✨

- ✅ **Simple Queue System** - Enqueue commands, they run in order
- ✅ **Async/Await** - Full async support, no callbacks
- ✅ **Event Hooks** - Listen to `started`, `success`, `error` events
- ✅ **Dead Simple API** - Just 3 methods: `registerHandler()`, `enqueue()`, `on()`
- ✅ **Extensible** - Register custom handlers, add listeners anywhere
- ✅ **Zero Dependencies** - Pure TypeScript, works everywhere
- ✅ **Pi Integration** - Pre-built extension for pi agent

## Quick Start

### 1. Core Library Usage

```typescript
import { eventLoop } from "./event-loop";

// Register a handler
eventLoop.registerHandler("bash", async (cmd) => {
  const { command } = cmd.args;
  // Do something async
  return { output: "..." };
});

// Listen to events
eventLoop.on("command:success", (result) => {
  console.log("Done!", result);
});

// Queue commands
const id = eventLoop.enqueue("bash", { command: "ls" });

// Start the loop
await eventLoop.start();

// Wait for result
const result = await eventLoop.waitFor(id);
```

### 2. Pi Extension (Recommended)

Place `async-event-loop.ts` in `~/.config/pi/extensions/`

Then in pi:

```
# Queue commands
/queue bash npm test
/queue read src/index.ts
/queue write output.json {"data":"test"}

# Check stats
/stats

# Wait for completion
/wait cmd_1234567890_abc
```

## API Reference

### EventLoop Class

#### `registerHandler(name: string, handler: CommandHandler): void`
Register a handler for a command type.

```typescript
eventLoop.registerHandler("mycommand", async (cmd) => {
  console.log(cmd.args); // Your arguments
  return { result: "..." };
});
```

#### `enqueue(name: string, args?: Record<string, any>): string`
Queue a command, returns command ID.

```typescript
const id = eventLoop.enqueue("bash", { command: "ls -la" });
```

#### `on(event: string, handler: EventHandler): () => void`
Listen to events. Returns unsubscribe function.

```typescript
const unsubscribe = eventLoop.on("command:success", (result) => {
  console.log(result);
});

// Unsubscribe
unsubscribe();
```

#### `once(event: string, handler: EventHandler): () => void`
Listen once, then auto-unsubscribe.

```typescript
await eventLoop.once("command:success", (result) => {
  console.log(result);
});
```

#### `async start(): Promise<void>`
Start processing the queue.

```typescript
await eventLoop.start(); // Blocks until stopped
```

#### `async stop(): Promise<void>`
Stop processing.

```typescript
await eventLoop.stop();
```

#### `async waitFor(id: string, timeout?: number): Promise<CommandResult>`
Wait for a command to complete.

```typescript
try {
  const result = await eventLoop.waitFor(id, 30000); // 30s timeout
  console.log(result);
} catch (err) {
  console.error("Timeout or error:", err);
}
```

#### `getResult(id: string): CommandResult | undefined`
Get result if available (non-blocking).

```typescript
const result = eventLoop.getResult(id);
if (result?.status === "success") {
  console.log(result.result);
}
```

#### `getStats(): Stats`
Get event loop statistics.

```typescript
const stats = eventLoop.getStats();
console.log(stats.queueLength);
console.log(stats.successCount);
console.log(stats.errorCount);
```

## Events

The event loop emits these events:

- `loop:started` - Event loop started
- `loop:stopped` - Event loop stopped
- `handler:registered` - Handler registered (data: `{ name }`)
- `command:queued` - Command queued (data: `Command`)
- `command:started` - Command execution started (data: `Command`)
- `command:success` - Command succeeded (data: `CommandResult`)
- `command:error` - Command failed (data: `CommandResult`)

## Examples

### Example 1: Basic Usage

```typescript
import { eventLoop } from "./event-loop";

// Handler
eventLoop.registerHandler("greet", async (cmd) => {
  const { name } = cmd.args;
  return { message: `Hello, ${name}!` };
});

// Events
eventLoop.on("command:success", (result) => {
  console.log(result.result.message);
});

// Queue and run
eventLoop.enqueue("greet", { name: "World" });
await eventLoop.start();
```

### Example 2: Multiple Handlers

```typescript
// File operations
eventLoop.registerHandler("read", async (cmd) => {
  return fs.readFileSync(cmd.args.path, "utf-8");
});

eventLoop.registerHandler("write", async (cmd) => {
  fs.writeFileSync(cmd.args.path, cmd.args.content);
  return { ok: true };
});

// Database
eventLoop.registerHandler("query", async (cmd) => {
  return await db.query(cmd.args.sql);
});

// All work through same interface
eventLoop.enqueue("read", { path: "data.json" });
eventLoop.enqueue("query", { sql: "SELECT * FROM users" });
eventLoop.enqueue("write", { path: "output.txt", content: "..." });
```

### Example 3: Error Handling

```typescript
eventLoop.on("command:error", (result) => {
  console.error(`Failed [${result.id}]: ${result.error?.message}`);
});

eventLoop.on("command:success", (result) => {
  console.log(`Success [${result.id}]: took ${result.duration}ms`);
});

try {
  const result = await eventLoop.waitFor(id);
  console.log("Command succeeded:", result.result);
} catch (err) {
  console.error("Command failed:", err);
}
```

### Example 4: Pi Integration

```typescript
// In your pi extension
eventLoop.registerHandler("bash", async (cmd) => {
  return await pi.bash(cmd.args.command);
});

eventLoop.registerHandler("read", async (cmd) => {
  return await pi.read(cmd.args.path);
});

// Now use through pi skills:
// /queue bash npm test
// /queue read package.json
// /stats
```

## Architecture

```
User
  ↓
[Command] → enqueue() → Queue
                          ↓
                    start() loop
                          ↓
                  getHandler() → execute()
                          ↓
                  [success/error]
                          ↓
                      emit() events
                          ↓
                  listeners + results
```

- **Single queue** - Commands process in order
- **Async handlers** - No blocking
- **Event system** - Loose coupling
- **Result storage** - Access results anytime
- **Non-blocking queue check** - Efficient polling

## Why This Design?

✅ **Simple** - Just a queue + event emitter  
✅ **Testable** - No side effects, pure functions  
✅ **Extensible** - Add handlers anywhere  
✅ **Observable** - Everything emits events  
✅ **Non-invasive** - Works with existing code  
✅ **Async-first** - Built for async/await  

## Installation

1. Copy `event-loop.ts` to your project
2. Import and use!

For pi integration:
1. Copy `event-loop.ts` to `~/dotfiles/pi/`
2. Copy `extensions/async-event-loop.ts` to `~/.config/pi/extensions/`
3. Load in pi: `/reload`

## Development

```bash
# Run example
deno run --allow-all example-usage.ts

# Or with TypeScript
ts-node example-usage.ts

# Or compile to JavaScript first
tsc event-loop.ts && node example-usage.js
```

## License

MIT

## Contributing

This is intentionally minimal. Want to extend it? Just:

1. Subclass `EventLoop`
2. Add methods
3. Emit custom events

No PR needed unless it's a bug fix!

---

**Keep it simple. Make it extensible.** 🚀
