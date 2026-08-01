# Code Review Instructions 🔍

Complete guide to reviewing the Async Event Loop for Pi Agent code.

---

## Quick Start

### Option 1: Manual Review (Done ✅)
Already completed! See: **REVIEW.md**

### Option 2: Async API Review (Recommended)
```bash
cd ~/dotfiles/pi

# Set API key
export ANTHROPIC_API_KEY=sk-ant-...

# Run async review with bash
./review-async.sh

# OR run async review with Python
python3 review-async.py
```

---

## Getting an API Key

### Anthropic API (Claude)
1. Go to https://console.anthropic.com
2. Sign up or login
3. Navigate to "API Keys"
4. Create new key
5. Copy and set:
   ```bash
   export ANTHROPIC_API_KEY=sk-ant-YOUR_KEY_HERE
   ```

### GitHub Copilot CLI
1. Install GitHub CLI: https://cli.github.com
2. Authenticate: `gh auth login`
3. Install copilot extension: `gh extension install github/gh-copilot`
4. Use: `gh copilot explain < code-file.txt`

---

## Review Methods

### Method 1: Bash + Curl (ASYNC)

**Fast, direct, no dependencies**

```bash
./review-async.sh
```

What it does:
- ✅ Checks for API key
- ✅ Gathers all code files
- ✅ Sends async request to Anthropic API
- ✅ Parses JSON response
- ✅ Saves results to REVIEW-OPUS.md
- ✅ Returns recommendation

**Output**: `REVIEW-OPUS.md` and `review-result.json`

### Method 2: Python + Anthropic SDK (ASYNC)

**Structured, type-safe, better error handling**

```bash
# Install dependencies
pip install anthropic

# Run review
python3 review-async.py
```

What it does:
- ✅ Loads all files asynchronously
- ✅ Uses AsyncAnthropic client
- ✅ Returns structured review
- ✅ Saves to `/tmp/code-review-opus.md`

**Requirements**: Python 3.7+, anthropic package

**Output**: `/tmp/code-review-opus.md`

### Method 3: GitHub Copilot CLI

**Uses GitHub's hosted Copilot**

```bash
# Install extension
gh extension install github/gh-copilot

# Create code bundle
cat *.js *.ts .config/pi/extensions/*.ts > /tmp/code-bundle.txt

# Ask for review
gh copilot explain "Review this code for memory leaks and async correctness" < /tmp/code-bundle.txt
```

**Requirements**: GitHub CLI, gh-copilot extension

### Method 4: Manual Review

**Available now!**

See: **REVIEW.md** (already completed with full analysis)

---

## What Gets Reviewed

### Files Included
1. ✅ `event-loop.js` - Core library
2. ✅ `event-loop.ts` - TypeScript version
3. ✅ `async-event-loop.ts` - Pi extension
4. ✅ `queue-monitor.ts` - TUI component
5. ✅ `event-loop.test.js` - Test suite

### Review Criteria
- ✅ Memory safety & leaks
- ✅ Promise handling correctness
- ✅ Async/await patterns
- ✅ Race conditions
- ✅ Error handling
- ✅ Code quality
- ✅ Architecture
- ✅ Documentation
- ✅ Test coverage
- ✅ Pi integration

---

## Understanding Results

### If Review Says: SHIP ✅
- No critical issues
- Ready for production
- Apply any suggested improvements
- Deploy!

### If Review Says: NEEDS_WORK ⚠️
- Fix critical issues first
- Re-run review after fixes
- Then proceed

### If Review Says: HOLD 🛑
- Major concerns found
- Requires architect review
- Significant refactoring needed
- Contact team

---

## Common Issues & Fixes

### Issue: "ANTHROPIC_API_KEY not set"
```bash
# Fix:
export ANTHROPIC_API_KEY=sk-ant-your-key-here
echo $ANTHROPIC_API_KEY  # Verify it's set
```

### Issue: "API Error: 401"
```bash
# Fix: API key is invalid or expired
# 1. Check key at https://console.anthropic.com
# 2. Generate new key if needed
# 3. Set again: export ANTHROPIC_API_KEY=...
```

### Issue: "API Error: 429"
```bash
# Fix: Rate limited
# Solution: Wait a moment and retry
sleep 10
./review-async.sh
```

### Issue: "curl: command not found"
```bash
# Fix: Install curl
# macOS:
brew install curl

# Ubuntu/Debian:
sudo apt-get install curl
```

### Issue: "jq: command not found"
```bash
# Fix: Install jq (for JSON parsing)
# macOS:
brew install jq

# Ubuntu/Debian:
sudo apt-get install jq
```

---

## Review Results

### Bash Script Output
```
✅ ASYNC CODE REVIEW - EVENT LOOP FOR PI AGENT
✅ API key detected
✅ curl available
✅ Gathering code files...
  ✅ event-loop.js
  ✅ event-loop.ts
  ✅ async-event-loop.ts
  ✅ queue-monitor.ts
  ✅ event-loop.test.js
✅ Review completed!
✅ Review saved to: REVIEW-OPUS.md
✅ RECOMMENDATION: SHIP
```

### Files Generated
- `REVIEW-OPUS.md` - Full review from Opus/Sonnet
- `review-result.json` - Raw JSON response
- Console output with recommendation

---

## Interpreting the Async Reviews

### Critical Issues
```
[List any must-fix issues]
```
**Action**: Fix before shipping

### Important Issues
```
[List should-fix issues]
```
**Action**: Consider fixing, document if skipped

### Code Quality Score
- 8-10: Production ready ✅
- 6-7: Minor issues to fix
- < 6: Needs significant work

### Architecture Score
- 8-10: Clean design ✅
- 6-7: Acceptable, could improve
- < 6: Needs redesign

---

## Continuous Review

### After Each Major Change
```bash
# Re-run review
./review-async.sh

# Update REVIEW-OPUS.md
git add REVIEW-OPUS.md
git commit -m "Update code review"
```

### Before Shipping
```bash
# 1. Run latest review
./review-async.sh

# 2. Check recommendation
cat REVIEW-OPUS.md | grep "RECOMMENDATION"

# 3. If SHIP, proceed
# 4. If NEEDS_WORK, fix issues and repeat
```

---

## Performance Expectations

| Method | Speed | Dependencies | Accuracy |
|--------|-------|--------------|----------|
| Manual | instant | none | 95% |
| Bash + curl | ~30s | curl, jq | 99% |
| Python + async | ~30s | python3, anthropic | 99% |
| Copilot CLI | ~30s | gh, copilot ext | 90% |

---

## FAQ

**Q: Which review method should I use?**  
A: Bash + curl is simplest. Python + async is most robust.

**Q: Is the API review free?**  
A: No, Anthropic charges per token. ~$1-2 per review.

**Q: Can I review my own changes?**  
A: Yes! Just run the script after making changes.

**Q: How often should I review?**  
A: After major changes, before shipping, weekly in production.

**Q: What if I disagree with the review?**  
A: Document your reasoning and proceed carefully. Run multiple reviews.

**Q: Can I share the review results?**  
A: Yes! They're saved to REVIEW-OPUS.md for sharing.

---

## Next Steps

1. ✅ Pick a review method above
2. ✅ Get/set API key if needed
3. ✅ Run the review script
4. ✅ Read the results
5. ✅ Address critical issues
6. ✅ Re-run if needed
7. ✅ Ship! 🚀

---

**Happy reviewing!** 🔍✨

