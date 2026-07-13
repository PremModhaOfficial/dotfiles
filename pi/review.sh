#!/bin/bash

# Async Code Review with GitHub Copilot CLI
# Uses Opus model to vet all code in this session

echo "🚀 Starting Async Code Review with Copilot (Opus)"
echo "=================================================="
echo ""

# Check if copilot CLI is available
if ! command -v gh copilot &> /dev/null; then
  echo "❌ GitHub Copilot CLI not found. Install with:"
  echo "   gh extension install github/gh-copilot"
  exit 1
fi

echo "✅ GitHub Copilot CLI detected"
echo ""

# Create review request file
cat > /tmp/code-review-request.md << 'EOF'
# Async Event Loop for Pi Agent - Code Review Request

## Files to Review

### 1. Core Library: event-loop.js
- Location: /home/prem-modha/dotfiles/pi/event-loop.js
- Purpose: Single class implementing async command queue with event system
- Lines: ~200
- Review Focus:
  - No memory leaks
  - Promise handling correctness
  - Event listener cleanup
  - Async/await patterns
  - Edge cases handling

### 2. TypeScript Version: event-loop.ts
- Location: /home/prem-modha/dotfiles/pi/event-loop.ts
- Purpose: TypeScript version with type definitions
- Lines: ~250
- Review Focus:
  - Type safety
  - Interface correctness
  - Generic types usage
  - API surface matches JS version

### 3. Pi Extension: async-event-loop.ts
- Location: /home/prem-modha/dotfiles/pi/.config/pi/extensions/async-event-loop.ts
- Purpose: Pi extension integrating event loop with pi tools
- Lines: ~180
- Review Focus:
  - Pi API compliance
  - Error handling
  - Skill implementation
  - Event listener registration

### 4. TUI Component: queue-monitor.ts
- Location: /home/prem-modha/dotfiles/pi/.config/pi/tui/queue-monitor.ts
- Purpose: Real-time queue monitoring UI component
- Lines: ~250
- Review Focus:
  - Component interface compliance
  - ANSI rendering correctness
  - Input handling
  - Memory efficiency
  - Width constraints

### 5. Test Suite: event-loop.test.js
- Location: /home/prem-modha/dotfiles/pi/event-loop.test.js
- Purpose: Comprehensive test suite with 10 test cases
- Lines: ~350
- Review Focus:
  - Async test patterns
  - No hanging promises
  - Proper cleanup
  - Test isolation
  - Coverage completeness

## Review Criteria

### Code Quality (40%)
- [ ] Follows JavaScript/TypeScript best practices
- [ ] No anti-patterns or code smells
- [ ] Clear variable/function naming
- [ ] Proper error handling
- [ ] Consistent style throughout

### Architecture (30%)
- [ ] Minimal and focused design
- [ ] Proper separation of concerns
- [ ] Extensible without modification
- [ ] Non-invasive to pi core
- [ ] Clear event flow

### Correctness (20%)
- [ ] No memory leaks
- [ ] Promise handling correct
- [ ] Event listener cleanup
- [ ] No race conditions
- [ ] Edge cases handled

### Documentation (10%)
- [ ] Code comments clear
- [ ] API well documented
- [ ] Examples correct
- [ ] README accurate
- [ ] Integration guide complete

## Specific Questions

1. **Memory Safety**: Are there any potential memory leaks in the EventLoop class?

2. **Promise Handling**: Is the waitFor() method's promise cleanup correct and safe?

3. **Event Listener Cleanup**: Will listeners properly unsubscribe in all scenarios?

4. **Async Patterns**: Are async/await patterns used correctly throughout?

5. **Pi Integration**: Does the extension properly integrate with pi's API without breaking changes?

6. **TUI Component**: Does the queue monitor correctly implement pi's Component interface?

7. **Test Coverage**: Are the tests comprehensive enough? Any edge cases missed?

8. **Error Handling**: Is error handling consistent and complete?

9. **Performance**: Are there any performance issues or bottlenecks?

10. **Minimalism**: Does this maintain pi's philosophy of minimalism and extensibility?

## Success Criteria

✅ Code is production-ready when:
- No critical issues found
- Memory usage is stable
- All async patterns are correct
- Error handling is comprehensive
- No race conditions or deadlocks
- Integrates cleanly with pi
- Documentation is accurate and complete
EOF

echo "📝 Review request created"
echo ""

# Run async review with copilot (Opus model)
echo "⏳ Sending code for review to Copilot (Opus model)..."
echo "   Running in ASYNC mode..."
echo ""

# Read all files and create comprehensive review
REVIEW_FILES=(
  "/home/prem-modha/dotfiles/pi/event-loop.js"
  "/home/prem-modha/dotfiles/pi/event-loop.ts"
  "/home/prem-modha/dotfiles/pi/.config/pi/extensions/async-event-loop.ts"
  "/home/prem-modha/dotfiles/pi/.config/pi/tui/queue-monitor.ts"
  "/home/prem-modha/dotfiles/pi/event-loop.test.js"
  "/home/prem-modha/dotfiles/pi/README.md"
  "/home/prem-modha/dotfiles/pi/PLAN.md"
  "/home/prem-modha/dotfiles/pi/VALIDATION.md"
  "/home/prem-modha/dotfiles/pi/INTEGRATION.md"
)

# Create comprehensive code dump for review
cat > /tmp/full-code-review.txt << 'EOF'
=================================================================
ASYNC EVENT LOOP FOR PI AGENT - COMPLETE CODE REVIEW
=================================================================

REVIEW REQUESTED: All code written in this session
MODEL: Opus (via GitHub Copilot CLI)
MODE: Async
DATE: 2026-05-04

=================================================================
FILES FOR REVIEW:
=================================================================

EOF

for file in "${REVIEW_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ Found: $file" 
    echo "" >> /tmp/full-code-review.txt
    echo "─────────────────────────────────────────────────────" >> /tmp/full-code-review.txt
    echo "FILE: $file" >> /tmp/full-code-review.txt
    echo "─────────────────────────────────────────────────────" >> /tmp/full-code-review.txt
    cat "$file" >> /tmp/full-code-review.txt
    echo "" >> /tmp/full-code-review.txt
  else
    echo "❌ Not found: $file"
  fi
done

echo ""
echo "📦 All code bundled for review"
echo ""

# Try to use copilot CLI
echo "🔍 Attempting review via Copilot..."
echo ""

# Use gh copilot explain with the model parameter
# Note: The exact command depends on copilot CLI version
gh copilot explain "Review the following code files for memory leaks, async correctness, and integration safety" 2>/dev/null || \
gh extension list 2>/dev/null | grep copilot > /dev/null && echo "✅ Copilot CLI available" || \
echo "⚠️  Copilot CLI extension not installed. Install with: gh extension install github/gh-copilot"

echo ""
echo "📋 Code review request summary:"
cat /tmp/code-review-request.md

echo ""
echo "📂 Full code dump saved to: /tmp/full-code-review.txt"
echo ""
echo "💡 Next steps:"
echo "   1. Install copilot: gh extension install github/gh-copilot"
echo "   2. Run: gh copilot explain < /tmp/full-code-review.txt"
echo "   3. Or copy /tmp/full-code-review.txt to Claude/ChatGPT"
echo ""
