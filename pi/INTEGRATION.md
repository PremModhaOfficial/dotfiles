# Integration Guide 🔌

Step-by-step guide to integrate the async event loop into your pi workflow.

---

## Quick Start (2 minutes)

### 1. Copy Files

```bash
# Copy core library
cp event-loop.js ~/.config/pi/extensions/

# Copy extension
cp .config/pi/extensions/async-event-loop.ts ~/.config/pi/extensions/

# Copy TUI component (optional)
mkdir -p ~/.config/pi/tui
cp .config/pi/tui/queue-monitor.ts ~/.config/pi/tui/
```

### 2. Reload Pi

```bash
# In pi interactive mode
/reload
```

Expected output:
```
✅ Extension loaded: async-event-loop
```

### 3. Test It

```bash
# Queue a command
/queue bash echo "Hello, async world!"

# Check stats
/stats

# Wait for completion
/wait cmd_xxx_yyy
```

That's it! ✅

---

## What's Now Available

### Skills

#### `/queue <command> <args>`
Queue a command to run asynchronously.

```bash
# Queue bash command
/queue bash npm test

# Queue file read
/queue read src/index.ts

# Queue file write
/queue write output.json {"status":"ok"}

# Queue file edit
/queue edit src/index.ts [{"oldText":"foo","newText":"bar"}]
```

#### `/stats`
Show queue statistics.

```bash
# Output:
# 📊 Event Loop Stats:
#   Queue Length: 2
#   Running: true
#   Total Results: 145
#   Success: 142
#   Errors: 3
```

#### `/wait <command-id>`
Wait for a specific queued command to complete.

```bash
# From /queue output:
# ✅ Queued bash [cmd_1234567890_abc]

/wait cmd_1234567890_abc

# Output:
# ✅ Command completed: { status: "success", result: {...}, duration: 124 }
```

---

## Common Workflows

### Workflow 1: Batch Testing

Run multiple test suites in parallel (queued for sequential execution):

```bash
# Queue them up
/queue bash npm run test:unit
/queue bash npm run test:integration
/queue bash npm run test:e2e

# Check progress
/stats

# Wait for all to complete (run in separate window)
/queue bash "echo 'All tests done!'"
```

**Why?** Pi stays responsive while tests run. You can queue more commands, read files, etc.

### Workflow 2: Build + Deploy

```bash
# Build
/queue bash npm run build

# Wait for it
# (check /stats while it builds)

# Once done, deploy
/queue bash npm run deploy

# Monitor
/stats
```

**Why?** No blocking. You can edit files, read docs, etc. while building.

### Workflow 3: File Processing Pipeline

```bash
# Read multiple files
/queue read src/main.ts
/queue read src/utils.ts
/queue read src/types.ts

# Stats
/stats

# Results are stored, access them in code
```

### Workflow 4: Check System Health

```bash
# Queue diagnostics
/queue bash "df -h"
/queue bash "ps aux | grep node"
/queue bash "npm outdated"

# Monitor results
/stats
```

---

## Configuration

### Optional: Custom Timeout

Edit the Pi extension to change default timeout:

```typescript
// In ~/.config/pi/extensions/async-event-loop.ts

async waitFor(id, timeout = 60000) {  // Changed from 30000 to 60000
  // ...
}
```

### Optional: Auto-cleanup

Limit stored results:

```typescript
// Add to extension init:

const MAX_RESULTS = 100;
setInterval(() => {
  if (eventLoop.results.size > MAX_RESULTS) {
    const oldest = Array.from(eventLoop.results.keys())[0];
    eventLoop.results.delete(oldest);
  }
}, 5000);
```

---

## Advanced Usage

### In Your Own Scripts

If you're extending pi further, use the event loop directly:

```typescript
import { eventLoop } from "./event-loop.js";

// Register custom handler
eventLoop.registerHandler("mycommand", async (cmd) => {
  const { input } = cmd.args;
  return await myAsyncFunction(input);
});

// In a skill:
eventLoop.enqueue("mycommand", { input: "data" });
```

### Listen to Events

```typescript
// In your extension init:

eventLoop.on("command:success", (result) => {
  pi.log(`✅ Command succeeded: ${result.id}`);
});

eventLoop.on("command:error", (result) => {
  pi.log(`❌ Error: ${result.error.message}`);
});
```

### Get Results Programmatically

```typescript
// After command completes:

const result = eventLoop.getResult(commandId);
if (result?.status === "success") {
  pi.log(`Result: ${JSON.stringify(result.result)}`);
}
```

---

## Troubleshooting

### Issue: Extension doesn't load

**Check**: File permissions
```bash
ls -la ~/.config/pi/extensions/async-event-loop.ts
```

**Fix**: Make sure it's readable
```bash
chmod 644 ~/.config/pi/extensions/async-event-loop.ts
```

**Check**: TypeScript syntax
```bash
tsc ~/.config/pi/extensions/async-event-loop.ts --noEmit
```

### Issue: Commands not executing

**Check**: Is the loop running?
```bash
/stats  # Should show "Running: true"
```

**Fix**: Manually start if needed
```typescript
// In extension init, ensure:
await eventLoop.start();
```

### Issue: Memory usage growing

**Check**: How many results stored?
```bash
/stats  # Look at "Total Results"
```

**Fix**: Clear old results
```typescript
// Add to extension:
eventLoop.results.clear();  // Clears all
```

### Issue: Timeout errors

**Check**: Are commands actually slow?
```bash
/queue bash "time <your_command>"
```

**Fix**: Increase timeout
```typescript
// Change waitFor timeout:
await eventLoop.waitFor(id, 120000);  // 2 minutes
```

### Issue: TUI doesn't show

**Check**: Is pi version recent enough?
```bash
pi --version  # Should be 0.3.0+
```

**Fix**: Make sure TUI component is in right place
```bash
ls ~/.config/pi/tui/queue-monitor.ts
```

---

## Uninstalling

### Remove extension

```bash
rm ~/.config/pi/extensions/async-event-loop.ts
rm ~/.config/pi/tui/queue-monitor.ts
```

### Reload pi

```bash
# In pi:
/reload
```

Pi will work exactly as before. The event loop is completely optional.

---

## Performance Tips

### 1. Use appropriate timeouts
```bash
# For quick commands: 5s timeout
/wait <id>

# For slow commands: 60s timeout
# Edit skill code to adjust
```

### 2. Monitor queue length
```bash
/stats  # Keep this under 20 for best responsiveness
```

### 3. Batch similar commands
```bash
# Good: Queue all bash commands together
/queue bash npm test
/queue bash npm lint

# Also works: Mix command types
/queue bash npm test
/queue read src/index.ts
```

### 4. Clear results periodically
```typescript
// In extension, periodically:
if (eventLoop.results.size > 1000) {
  eventLoop.results.clear();
}
```

---

## FAQ

**Q: Will this slow down pi?**  
A: No. The event loop runs in background. Pi remains responsive.

**Q: Can I use /queue with my custom tools?**  
A: Yes! Register them as handlers (see Advanced Usage).

**Q: What if a command hangs?**  
A: It will timeout after 30 seconds (configurable), and pi remains responsive.

**Q: Can I see results of queued commands?**  
A: Yes! Use `/wait <id>` or access directly in code via `eventLoop.getResult(id)`.

**Q: Is my session data preserved?**  
A: Results are in memory only. They clear when pi exits (by design - stays minimal).

**Q: Can I queue commands from code/extensions?**  
A: Yes! `eventLoop.enqueue(name, args)` works anywhere.

**Q: Does this change pi's core behavior?**  
A: Zero impact on pi core. It's a pure extension. Uninstall anytime.

---

## Next Steps

1. ✅ Installed? Great!
2. 📖 Read the README.md for full API
3. 🧪 Run example workflows above
4. 🔧 Customize timeout/config as needed
5. 📊 Open TUI monitor (`showQueueMonitor()`)
6. 🚀 Integrate into your workflow

---

## Support

### Issues?
Check PLAN.md or VALIDATION.md for detailed info.

### Contribute?
Send a PR with improvements!

### Questions?
Check the API reference in README.md

---

**Happy queuing! ⚡**
