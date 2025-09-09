# Neovim AI Plugins Research Report 2024-2025

## Executive Summary

This report analyzes the current Neovim AI plugin configuration for optimization opportunities, deprecations, and enhancements. The research focused on 8 AI plugins: Avante.nvim, CodeCompanion.nvim, CopilotChat.nvim, MCPHub.nvim, OpenCode.nvim, Sidekick.nvim, Supermaven.nvim, and VectorCode.

## Key Findings

### 1. Avante.nvim (Currently Disabled)
**File:** `lua/custom/ai/avante.lua`

**Current Issues:**
- `enabled = false` (line 5) - plugin not being used
- Deprecated `local = true` configuration pattern (commented out lines 50-61)
- MCP integration may be causing conflicts with built-in tools

**Recommendations:**
- Either enable with proper OpenRouter configuration or remove entirely
- Update deprecated configuration: replace `local = true` with `api_key_name = ''`
- Consider if MCP integration is still needed given CodeCompanion also has MCP support

**Action Items:**
```lua
-- Option 1: Enable with updated config
enabled = true,
provider = "openrouter",
__inherited_from = "openai",

-- Option 2: Remove entirely if not needed
```

### 2. CodeCompanion.nvim (Active)
**File:** `lua/custom/ai/codecompanion.lua`

**Current Issues:**
- Using deprecated `grok-code-fast-1` model (line 48)
- Complex MCP and VectorCode extensions may impact performance
- Blink.cmp integration in init function could be optimized

**Recommendations:**
- Update model to current best performer: `claude-3.5-sonnet` or `gpt-4o`
- Consider disabling unused extensions for better performance
- Move Blink.cmp integration to proper configuration section

**Action Items:**
```lua
-- Update model configuration
schema = {
    model = {
        default = "claude-3.5-sonnet", -- Updated from grok-code-fast-1
    },
},
```

### 3. CopilotChat.nvim (Minimal Config)
**File:** `lua/custom/ai/CopilotChat.lua`

**Current Issues:**
- Minimal configuration (`opts = {}`) missing key features
- `build = "make tiktoken"` may not be necessary for latest versions
- Missing integration with other AI plugins

**Recommendations:**
- Add proper configuration for model selection and chat behavior
- Remove unnecessary build command if not needed
- Consider if this plugin duplicates functionality with CodeCompanion

**Action Items:**
```lua
opts = {
    model = "gpt-4o",
    chat_autocomplete = true,
    show_folds = true,
    show_help = true,
    debug = false,
},
```

### 4. MCPHub.nvim (High Priority)
**File:** `lua/custom/ai/mcphub.lua`

**Current Issues:**
- High priority loading may cause startup delays
- Complex auto-approval logic could be security risk
- Multiple native servers may impact performance

**Recommendations:**
- Review native server necessity
- Simplify auto-approval logic for better security
- Consider lazy loading for better startup performance

**Action Items:**
```lua
-- Consider lazy loading
event = "VeryLazy", -- Instead of "VimEnter"
priority = 500, -- Instead of 1000
```

### 5. OpenCode.nvim (Active)
**File:** `lua/custom/ai/opencode.lua`

**Current Issues:**
- Early development stage, potential breaking changes
- Extensive keymap setup may conflict with other plugins
- Duplicates functionality with other AI plugins

**Recommendations:**
- Consider if needed given other AI plugins
- Review keymap conflicts
- Monitor for breaking changes

### 6. Sidekick.nvim (Disabled)
**File:** `lua/custom/ai/sidekick.lua`

**Current Status:**
- `enabled = false` - appropriately disabled
- Good decision given plugin redundancy

**Recommendations:**
- Keep disabled or remove entirely
- No action needed if staying disabled

### 7. Supermaven.nvim (Disabled)
**File:** `lua/custom/ai/supermaven.lua`

**Current Status:**
- `enabled = false` - appropriately disabled
- Conflicting reports about maintenance status after Cursor acquisition

**Recommendations:**
- Keep disabled or remove entirely
- Consider alternatives like Codeium if needed

### 8. VectorCode (Active)
**File:** `lua/custom/ai/VectorCode.lua`

**Current Issues:**
- Minimal configuration may not be optimal
- Build command may not be necessary for all users

**Recommendations:**
- Add proper configuration if actively used
- Consider if RAG capabilities are needed
- Review build command necessity

## Performance Optimization Recommendations

### 1. Plugin Consolidation
**Issue:** Too many AI plugins causing potential conflicts and performance impact.

**Recommendation:** Consolidate to 2-3 core plugins:
- **Primary:** CodeCompanion.nvim (most feature-rich)
- **Secondary:** CopilotChat.nvim (if GitHub Copilot subscription available)
- **Optional:** VectorCode (if RAG capabilities needed)

### 2. Startup Performance
**Current Issues:**
- MCPHub loads with high priority (1000)
- Multiple AI plugins initializing at startup
- Complex initialization chains

**Solutions:**
```lua
-- Lazy load AI plugins
event = "VeryLazy",
-- Reduce MCPHub priority
priority = 500,
```

### 3. Memory Usage
**Issues:**
- Multiple LLM adapters loaded simultaneously
- Complex extension systems
- Redundant functionality

**Solutions:**
- Disable unused adapters
- Remove redundant plugins
- Optimize extension loading

## Deprecation Warnings

### 1. Avante.nvim
- `local = true` → `api_key_name = ''`
- "legacy" mode → "nonagentic" mode

### 2. CopilotChat.nvim
- GPT-4o model deprecated (use GPT-4.1)
- Several Claude/Gemini models deprecated

### 3. General
- Tiktoken build may not be necessary
- Some model names have changed

## Security Considerations

### 1. MCPHub Auto-Approval
**Risk:** Broad auto-approval logic in `mcphub.lua` (lines 22-56)

**Recommendation:**
- Restrict auto-approval to truly safe operations
- Add user confirmation for file modifications
- Review server-specific auto-approvals

### 2. API Key Management
**Current:** Environment variables used appropriately

**Recommendation:** Continue using environment variables, avoid hardcoding keys

## Integration Improvements

### 1. Blink.cmp Integration
**Current:** Multiple plugins setting up Blink.cmp separately

**Recommendation:** Centralize Blink.cmp configuration
```lua
-- In main Blink.cmp config
sources = {
    default = { "lsp", "path", "snippets", "buffer", "avante", "codecompanion" },
},
```

### 2. Plugin Coordination
**Issue:** No coordination between AI plugins

**Recommendation:** Create AI plugin manager
```lua
-- Central AI configuration
local ai_config = {
    primary_provider = "codecompanion",
    secondary_provider = "copilotchat",
    extensions = { "vectorcode" },
}
```

## Alternative Plugins to Consider

### 1. If Consolidating
- **Codeium:** Free commercial alternative to Supermaven
- **Augment:** Custom backend with multi-turn chat
- **Minuet-ai.nvim:** Local model support

### 2. For Specific Features
- **gen.nvim:** Local model integration via Ollama
- **llm.nvim:** Lightweight LLM integration
- **magenta.nvim:** Newer alternative

## Immediate Action Items

### High Priority
1. **Update CodeCompanion model** (line 48 in codecompanion.lua)
2. **Configure CopilotChat properly** (opts = {} in CopilotChat.lua)
3. **Decide on Avante.nvim** (enable or remove)
4. **Review MCPHub security** (auto-approval logic)

### Medium Priority
1. **Optimize startup loading** (event and priority settings)
2. **Consolidate Blink.cmp integration**
3. **Remove truly unused plugins**
4. **Add error handling and logging**

### Low Priority
1. **Monitor for plugin updates**
2. **Consider alternative plugins**
3. **Create AI plugin coordination system**
4. **Add performance monitoring**

## File-Specific Recommendations

### `lua/custom/ai/avante.lua`
- Line 5: Decide on `enabled = true` or remove plugin
- Lines 50-61: Update deprecated OpenRouter config
- Lines 76-87: Review disabled tools necessity

### `lua/custom/ai/codecompanion.lua`
- Line 48: Update model from `grok-code-fast-1`
- Lines 56-96: Review VectorCode extension usage
- Lines 114-124: Optimize Blink.cmp integration

### `lua/custom/ai/CopilotChat.lua`
- Line 8: Add proper configuration instead of empty opts
- Line 7: Review if `build = "make tiktoken"` is needed

### `lua/custom/ai/mcphub.lua`
- Line 3-4: Consider changing event and priority
- Lines 22-56: Review auto-approval security
- Lines 12-17: Review native server necessity

### `lua/custom/ai/sidekick.lua`
- Line 3: Keep disabled or remove entirely

### `lua/custom/ai/supermaven.lua`
- Line 4: Keep disabled or remove entirely

## Conclusion

The current AI plugin setup is functional but has opportunities for significant optimization. The main issues are:

1. **Plugin redundancy** - Too many overlapping AI plugins
2. **Performance impact** - High-priority loading and complex initialization
3. **Security concerns** - Broad auto-approval in MCPHub
4. **Deprecated configurations** - Several outdated settings

By consolidating to 2-3 core plugins, updating deprecated settings, and optimizing startup performance, significant improvements can be achieved in both performance and maintainability.

**Recommended Core Setup:**
1. **CodeCompanion.nvim** (primary AI assistant)
2. **CopilotChat.nvim** (if GitHub Copilot available)
3. **VectorCode** (if RAG capabilities needed)
4. **MCPHub** (with reduced scope and better security)

This would provide comprehensive AI assistance while minimizing conflicts and performance overhead.