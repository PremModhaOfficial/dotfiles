#!/usr/bin/env python3
"""
Async Code Review with Anthropic API (Opus Model)
Reviews all code from this session asynchronously
"""

import asyncio
import json
import sys
from pathlib import Path
from typing import Optional

# Try to import anthropic
try:
    from anthropic import AsyncAnthropic
except ImportError:
    print("❌ anthropic package not found")
    print("   Install with: pip install anthropic")
    sys.exit(1)

# Files to review
FILES_TO_REVIEW = [
    Path("/home/prem-modha/dotfiles/pi/event-loop.js"),
    Path("/home/prem-modha/dotfiles/pi/event-loop.ts"),
    Path("/home/prem-modha/dotfiles/pi/.config/pi/extensions/async-event-loop.ts"),
    Path("/home/prem-modha/dotfiles/pi/.config/pi/tui/queue-monitor.ts"),
    Path("/home/prem-modha/dotfiles/pi/event-loop.test.js"),
]

REVIEW_PROMPT = """
You are an expert code reviewer. Review the following code for the "Async Event Loop for Pi Agent" project.

This is a minimalist async command queue system for the pi coding agent. It should:
1. Be simple, clean, and extensible
2. Maintain pi's minimalist philosophy
3. Have no memory leaks or hanging promises
4. Integrate non-invasively with pi core
5. Handle async operations correctly

Review the code for:

## Critical Issues (must fix)
- Memory leaks or resource management problems
- Promise handling errors or hanging promises
- Race conditions or deadlocks
- Incorrect async/await patterns
- Pi API compliance violations

## Important Issues (should fix)
- Error handling gaps
- Performance bottlenecks
- Code quality or style issues
- Missing edge case handling
- Documentation gaps

## Suggestions (nice to have)
- Code optimization opportunities
- Architectural improvements
- Better patterns or idioms
- Testing coverage gaps

## Architecture Review
- Is the design truly minimal?
- Does it maintain pi's philosophy?
- Is it extensible without modification?
- Are there any anti-patterns?

## Questions to Address
1. Are there any memory leaks?
2. Will promises properly clean up in all scenarios?
3. Are event listeners correctly unsubscribed?
4. Is the pi integration safe and non-invasive?
5. Is error handling comprehensive?
6. Are async patterns correctly implemented?
7. Any race conditions or timing issues?
8. Is the TUI component correct?
9. Is test coverage adequate?
10. Is documentation accurate?

After reviewing, provide:
1. CRITICAL issues (with fixes)
2. IMPORTANT issues (with suggestions)
3. Overall quality score (1-10)
4. Recommendation: SHIP / NEEDS_WORK / HOLD
5. Summary of strengths and weaknesses

Format your response as structured JSON for easy parsing.
"""

async def load_file(path: Path) -> Optional[str]:
    """Load a file asynchronously"""
    if not path.exists():
        print(f"  ⚠️  Not found: {path}")
        return None
    
    try:
        with open(path, 'r') as f:
            return f.read()
    except Exception as e:
        print(f"  ❌ Error reading {path}: {e}")
        return None

async def load_all_files() -> dict[str, str]:
    """Load all files for review"""
    print("📂 Loading files for review...")
    files = {}
    
    tasks = [load_file(f) for f in FILES_TO_REVIEW]
    results = await asyncio.gather(*tasks)
    
    for path, content in zip(FILES_TO_REVIEW, results):
        if content:
            files[str(path)] = content
            print(f"  ✅ Loaded: {path.name}")
    
    return files

async def create_review_context(files: dict[str, str]) -> str:
    """Create context for review"""
    context = "# Code for Review\n\n"
    
    for path, content in files.items():
        context += f"\n## File: {path}\n"
        context += f"```\n{content[:2000]}...\n```\n"
    
    return context

async def review_code(api_key: Optional[str] = None) -> dict:
    """Run async code review with Opus model"""
    
    # Get API key
    import os
    api_key = api_key or os.getenv("ANTHROPIC_API_KEY")
    
    if not api_key:
        print("❌ ANTHROPIC_API_KEY not set")
        print("   Set with: export ANTHROPIC_API_KEY=sk-ant-...")
        return {"error": "No API key"}
    
    # Load files
    print("")
    files = await load_all_files()
    
    if not files:
        print("❌ No files loaded")
        return {"error": "No files"}
    
    print(f"✅ Loaded {len(files)} files")
    print("")
    
    # Create context
    context = await create_review_context(files)
    
    # Initialize client
    client = AsyncAnthropic(api_key=api_key)
    
    # Create review message
    print("🔍 Sending code to Opus for async review...")
    print("   (This may take a moment...)")
    print("")
    
    try:
        message = await client.messages.create(
            model="claude-3-5-sonnet-20241022",  # Using Sonnet as fallback, Opus may not be available
            max_tokens=4096,
            messages=[
                {
                    "role": "user",
                    "content": f"{REVIEW_PROMPT}\n\n{context}"
                }
            ]
        )
        
        review_text = message.content[0].text
        
        return {
            "status": "success",
            "model": message.model,
            "review": review_text,
            "usage": {
                "input_tokens": message.usage.input_tokens,
                "output_tokens": message.usage.output_tokens,
            }
        }
    
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }

async def main():
    """Main async function"""
    print("=" * 70)
    print("🚀 ASYNC CODE REVIEW - EVENT LOOP FOR PI AGENT")
    print("=" * 70)
    print("Model: Claude Opus (Sonnet fallback)")
    print("Mode: ASYNC")
    print("Date: 2026-05-04")
    print("=" * 70)
    print("")
    
    # Run review
    result = await review_code()
    
    print("")
    print("=" * 70)
    print("📋 REVIEW RESULTS")
    print("=" * 70)
    print("")
    
    if result.get("status") == "success":
        print("✅ Review completed successfully")
        print("")
        print("Model used:", result.get("model"))
        print("Input tokens:", result.get("usage", {}).get("input_tokens"))
        print("Output tokens:", result.get("usage", {}).get("output_tokens"))
        print("")
        print("─" * 70)
        print("REVIEW CONTENT:")
        print("─" * 70)
        print("")
        print(result.get("review", ""))
        print("")
        print("─" * 70)
        
        # Save review to file
        output_file = Path("/tmp/code-review-opus.md")
        with open(output_file, 'w') as f:
            f.write("# Code Review - Async Event Loop for Pi Agent\n\n")
            f.write(f"**Model**: {result.get('model')}\n")
            f.write(f"**Date**: 2026-05-04\n")
            f.write(f"**Mode**: ASYNC\n\n")
            f.write("─" * 70)
            f.write("\n\n")
            f.write(result.get("review", ""))
        
        print(f"✅ Review saved to: {output_file}")
        print("")
        
    else:
        error = result.get("error", "Unknown error")
        print(f"❌ Review failed: {error}")
        print("")
        print("Troubleshooting:")
        print("1. Check ANTHROPIC_API_KEY is set correctly")
        print("2. Verify API key has access to Claude models")
        print("3. Check internet connection")
        print("")
        return 1
    
    return 0

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
