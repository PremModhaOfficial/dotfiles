# Async Event Loop Integration Plan ⚡

## Overview
Integrate a **minimal, non-invasive async event loop** into pi agent while preserving its core philosophy of simplicity and extensibility.

---

## 1. Core Principles (MUST NOT BREAK)

✅ **Pi's Minimalism**: No core changes required
✅ **Extensibility**: Works as optional extension
✅ **Zero Dependencies**: Pure TypeScript/JS, no external libs
✅ **Non-invasive**: Opt-in, doesn't affect existing workflows
✅ **Observable**: Full event transparency
✅ **Async-first**: Native async/await support

---

## 2. Architecture

```
┌─────────────────────────────────────────┐
│         Pi Core (Unchanged)             │
│  - read, write, edit, bash tools        │
│  - Message queue                        │
│  - Session management                   │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│      Async Event Loop (Extension)       │
│  - Command queue                        │
│  - Handler registry                     │
│  - Event emitter                        │
│  - Result storage                       │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│  Pi Integration Layer (Skills/TUI)      │
│  - /queue skill                         │
│  - /stats skill                         │
│  - /wait skill                          │
│  - Queue TUI panel                      │
└─────────────────────────────────────────┘
```

---

## 3. File Structure

```
dotfiles/pi/
├── event-loop.js              # Core (JS version)
├── event-loop.ts              # Core (TS version)
├── example-usage.ts           # Usage examples
├── event-loop.test.js         # Tests (async-safe)
├── README.md                  # Full documentation
├── PLAN.md                    # This file
├── VALIDATION.md              # Validation checklist
├── INTEGRATION.md             # Integration guide
│
├── .config/pi/
│   ├── extensions/
│   │   └── async-event-loop.ts      # Pi extension
│   │
│   └── tui/
│       └── queue-monitor.ts         # TUI component
```

---

## 4. Minimalist Integration Checklist

### 4.1 Core Library (`event-loop.js`)
- [x] Single class: `EventLoop`
- [x] Three main methods: `registerHandler()`, `enqueue()`, `on()`
- [x] No external dependencies
- [x] ~200 lines of code
- [ ] Validate no memory leaks
- [ ] Validate no hanging promises
- [ ] Validate clean shutdown

### 4.2 Pi Extension (`async-event-loop.ts`)
- [x] Register pi's tools as handlers
- [x] Add 3 skills: `/queue`, `/stats`, `/wait`
- [x] Pretty logging via `pi.log()`
- [ ] Handle pi reload gracefully
- [ ] Test with real pi session
- [ ] Validate with multiple concurrent commands

### 4.3 TUI Component (`queue-monitor.ts`)
- [ ] Show queue length in real-time
- [ ] Display recent commands
- [ ] Show success/error counts
- [ ] Update on events (started, success, error)
- [ ] Keep it < 100 lines

### 4.4 Documentation
- [x] README.md - Full API reference
- [ ] VALIDATION.md - Testing checklist
- [ ] INTEGRATION.md - Setup guide
- [ ] Example workflows

---

## 5. What MUST NOT Change in Pi

### Core Tools
```typescript
// These work exactly the same
pi.bash(command)     // Unchanged
pi.read(path)        // Unchanged
pi.write(path, content)  // Unchanged
pi.edit(path, edits)     // Unchanged
```

### Extensions API
```typescript
// Extension API remains identical
export default {
  name: "async-event-loop",
  init: async (pi) => { }   // Same interface
  skills: [{ }]             // Same interface
}
```

### Message Queue
- Pi's message queue remains untouched
- Event loop runs separately
- Can coexist peacefully

### Settings & Config
- No new required settings
- Optional: `eventLoopConfig` in pi.json
- Backward compatible

---

## 6. Safety Guarantees

### No Memory Leaks
```typescript
// Cleanup:
- Auto-unsubscribe in once()
- Proper timer cleanup in waitFor()
- No circular references
```

### No Hanging Promises
```typescript
// All promises have:
- Timeout mechanism (30s default)
- Proper error handling
- Cleanup on completion
```

### Clean Shutdown
```typescript
// When pi exits:
await eventLoop.stop()  // Gracefully stop
// All listeners cleaned up
// All timers cleared
```

---

## 7. Testing Strategy

### Unit Tests
- ✅ Handler registration
- ✅ Command enqueueing
- ✅ Command execution in order
- ✅ Error handling
- ✅ Event emission
- ✅ Result storage
- ⚠️ Async cleanup (FIX HANGING)

### Integration Tests
- [ ] With real pi tools
- [ ] Multiple concurrent commands
- [ ] Extension loading/reloading
- [ ] Memory usage over time
- [ ] Clean shutdown

### Pi Session Tests
- [ ] `/queue bash ls`
- [ ] `/queue read <file>`
- [ ] `/queue write <file> <data>`
- [ ] `/stats` shows correct counts
- [ ] `/wait <id>` completes

### TUI Tests
- [ ] Queue panel renders
- [ ] Updates on events
- [ ] No lag with many commands

---

## 8. Async Mode (Fix Hanging Tests)

**Problem**: Some test cases hang due to listener cleanup

**Solution**: Use isolated EventLoop instances with proper cleanup

```javascript
// ✅ Good - Isolated, clean shutdown
async function test() {
  const loop = new EventLoop();
  try {
    // Setup handlers
    // Run test
    const result = await loop.waitFor(id, 5000);
    // Assert
  } finally {
    await loop.stop(); // Always cleanup
  }
}

// ❌ Bad - Shared state, might hang
const globalLoop = new EventLoop();
// Multiple tests reuse same loop
```

**Implementation**:
1. Each test gets own EventLoop
2. Always call `await loop.stop()` in finally block
3. Use shorter timeouts (5s instead of 30s)
4. Run tests sequentially, not parallel

---

## 9. Validation Checklist

### Before Shipping
- [ ] All tests pass without hanging
- [ ] No memory leaks (check with process.memoryUsage())
- [ ] Pi extension loads without errors
- [ ] Skills work with actual pi session
- [ ] TUI component renders correctly
- [ ] Documentation complete
- [ ] Example workflows work

### Performance Baseline
- [ ] Queue processes < 10ms per command
- [ ] Event listeners < 1ms
- [ ] Memory stable after 100+ commands
- [ ] CPU usage minimal at idle
- [ ] Clean startup/shutdown < 100ms

---

## 10. Usage Scenarios

### Scenario 1: Batch Operations
```
User: "Run 5 npm scripts in background"
→ /queue bash npm test
→ /queue bash npm lint
→ /queue bash npm build
→ /queue bash npm deploy
→ /queue bash npm clean
→ /stats  # Shows 5 in queue
→ Monitor in TUI panel
```

### Scenario 2: File Processing
```
User: "Read 10 files and process them"
→ /queue read file1.ts
→ /queue read file2.ts
→ ... (8 more)
→ /wait cmd_xxx  # Wait for specific one
→ All results stored in eventLoop.results
```

### Scenario 3: Parallel Monitoring
```
User: "Build stuff while I read files"
→ Main pi session: /queue bash npm build
→ Another panel: /queue read src/index.ts
→ TUI shows both queuing + execution
→ No blocking each other
```

---

## 11. Migration Path (If Needed)

**Phase 1**: Optional extension (current)
```
- User manually loads extension
- Works alongside pi tools
- Zero impact if not used
```

**Phase 2**: Discoverable feature
```
- Show in /help
- Suggest in tutorials
- Gather feedback
```

**Phase 3**: Consider as core (maybe never)
```
- Only if widely adopted
- Only if proves stable
- Only if pi team agrees
```

---

## 12. Known Limitations

- ✅ Single queue (sequential execution)
- ✅ Result storage limited to memory (no persistence)
- ✅ No distributed execution (single-machine)
- ✅ No priority queuing (FIFO only)

**Future Enhancements** (Without breaking minimalism):
- Priority queue option
- Result disk cache option
- Plugin for worker threads
- Batch result export

---

## 13. Deployment Checklist

### Before Release
- [ ] Tests all pass (no hanging)
- [ ] README complete with examples
- [ ] VALIDATION.md created
- [ ] INTEGRATION.md created
- [ ] TUI component tested
- [ ] Extension tested with real pi
- [ ] Performance benchmarked
- [ ] Edge cases documented

### Documentation
- [ ] API reference complete
- [ ] Examples for each feature
- [ ] Troubleshooting guide
- [ ] Architecture diagram
- [ ] Video tutorial (optional)

### Support
- [ ] Issues template created
- [ ] FAQ section ready
- [ ] Discord/community links

---

## 14. Success Metrics

✅ If we achieve:
- 0 memory leaks over 1hr with 1000+ commands
- 0 hanging test cases
- < 10ms overhead per command
- Clean integration with pi (no core changes)
- Users can load/unload without restart
- Documentation complete & clear
- TUI works smoothly

---

## Timeline

- **Now**: Fix hanging tests, create TUI, validation docs
- **Today**: Complete all checks above
- **Tomorrow**: Integration testing with real pi
- **Ready to ship**: When all ✅ items complete

---

**Next Steps**:
1. Fix hanging test (async cleanup)
2. Create TUI component
3. Write VALIDATION.md
4. Write INTEGRATION.md
5. Run full test suite
6. Document examples
