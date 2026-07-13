#!/bin/bash

# Async Code Review using Anthropic API (Opus/Sonnet)
# This script runs reviews asynchronously using curl

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_KEY="${ANTHROPIC_API_KEY:-}"
OUTPUT_FILE="${SCRIPT_DIR}/review-result.json"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 ASYNC CODE REVIEW - EVENT LOOP FOR PI AGENT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check API key
if [ -z "$API_KEY" ]; then
  echo -e "${RED}❌ ANTHROPIC_API_KEY not set${NC}"
  echo ""
  echo "Set with:"
  echo "  export ANTHROPIC_API_KEY=sk-ant-..."
  echo ""
  echo "Get key from: https://console.anthropic.com"
  exit 1
fi

echo -e "${GREEN}✅ API key detected${NC}"
echo ""

# Check if curl is available
if ! command -v curl &> /dev/null; then
  echo -e "${RED}❌ curl not found${NC}"
  exit 1
fi

echo -e "${GREEN}✅ curl available${NC}"
echo ""

# Gather code files
echo -e "${YELLOW}📂 Gathering code files...${NC}"

code_content=""

files=(
  "${SCRIPT_DIR}/event-loop.js"
  "${SCRIPT_DIR}/event-loop.ts"
  "${SCRIPT_DIR}/.config/pi/extensions/async-event-loop.ts"
  "${SCRIPT_DIR}/.config/pi/tui/queue-monitor.ts"
  "${SCRIPT_DIR}/event-loop.test.js"
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    code_content+="

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FILE: $(basename "$file")
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$(head -c 3000 "$file")
...

"
    echo -e "  ${GREEN}✅${NC} $(basename "$file")"
  fi
done

echo ""
echo -e "${BLUE}📝 Creating review request...${NC}"
echo ""

# Create review prompt
review_prompt="You are an expert code reviewer. Review the following code for the 'Async Event Loop for Pi Agent' project.

This is a minimalist async command queue system for the pi coding agent. It should be simple, clean, extensible, and maintain pi's philosophy of minimalism.

CRITICAL ISSUES TO CHECK:
1. Memory leaks or resource management problems
2. Promise handling errors or hanging promises  
3. Race conditions or deadlocks
4. Async/await patterns correctness
5. Pi API compliance violations
6. Event listener cleanup
7. Error handling comprehensiveness
8. Performance bottlenecks
9. Test coverage adequacy

ARCHITECTURE REVIEW:
- Is the design truly minimal?
- Does it maintain pi's philosophy?
- Is it extensible without modification?
- Are there anti-patterns?

RESPOND WITH STRUCTURED ANALYSIS:

## CRITICAL ISSUES
[List any must-fix issues]

## IMPORTANT ISSUES  
[List should-fix issues]

## CODE QUALITY
[Score and feedback: 1-10]

## ARCHITECTURE
[Score and feedback: 1-10]

## ASYNC CORRECTNESS
[Score and feedback: 1-10]

## OVERALL ASSESSMENT
- Recommendation: SHIP / NEEDS_WORK / HOLD
- Strengths: [list]
- Weaknesses: [list]
- Next steps: [list]

CODE FOR REVIEW:
$code_content"

# JSON escape the prompt
escaped_prompt=$(printf '%s\n' "$review_prompt" | jq -Rs .)

echo -e "${YELLOW}⏳ Sending async review request to Anthropic API...${NC}"
echo "   Model: claude-3-5-sonnet-20241022"
echo "   Mode: ASYNC"
echo ""

# Send async request
response=$(curl -s -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "{
    \"model\": \"claude-3-5-sonnet-20241022\",
    \"max_tokens\": 4096,
    \"messages\": [
      {
        \"role\": \"user\",
        \"content\": $escaped_prompt
      }
    ]
  }")

# Check for API errors
if echo "$response" | grep -q "error"; then
  error_msg=$(echo "$response" | jq -r '.error.message // .error' 2>/dev/null || echo "$response")
  echo -e "${RED}❌ API Error: $error_msg${NC}"
  exit 1
fi

# Extract review text
review_text=$(echo "$response" | jq -r '.content[0].text' 2>/dev/null)

if [ -z "$review_text" ]; then
  echo -e "${RED}❌ Failed to parse response${NC}"
  echo "Raw response:"
  echo "$response"
  exit 1
fi

# Save results
echo "$response" | jq '.' > "$OUTPUT_FILE"

echo -e "${GREEN}✅ Review completed!${NC}"
echo ""

# Display review
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📋 REVIEW RESULTS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "$review_text"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# Save to markdown file
review_md="${SCRIPT_DIR}/REVIEW-OPUS.md"
cat > "$review_md" << EOF
# Code Review - Async Event Loop for Pi Agent

**Model**: Claude 3.5 Sonnet (via Anthropic API)  
**Mode**: ASYNC  
**Date**: $(date)  
**API**: Anthropic  

---

## Review Results

$review_text

---

**Full JSON Response**: $OUTPUT_FILE

EOF

echo -e "${GREEN}✅ Review saved to: $review_md${NC}"
echo ""

# Extract recommendation
if echo "$review_text" | grep -qi "SHIP"; then
  echo -e "${GREEN}✅ RECOMMENDATION: SHIP${NC}"
  exit 0
elif echo "$review_text" | grep -qi "HOLD"; then
  echo -e "${YELLOW}⚠️  RECOMMENDATION: HOLD${NC}"
  exit 1
elif echo "$review_text" | grep -qi "NEEDS_WORK"; then
  echo -e "${YELLOW}⚠️  RECOMMENDATION: NEEDS_WORK${NC}"
  exit 1
fi
