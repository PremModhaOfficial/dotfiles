# Stepped Wave Animation Implementation Plan
## LSP Progress Enhancement for Heirline Statusline

**Created**: 2025-11-17  
**Status**: Ready for Execution  
**Estimated Time**: 3-4 hours  
**Task Graph**: `WAVE_ANIMATION_TASK_GRAPH.json`

---

## Executive Summary

This plan implements a **fast, continuous left-to-right traveling wave animation** for the LSP progress state in the NixieProgressBar component using Unicode stepped pattern characters (⎯ and ⎺). The animation completes in ~1.35 seconds (9 frames × 150ms) and is **LSP-exclusive**, preserving all other statusline states unchanged.

### Key Requirements
- **Animation Type**: Stepped Wave (Option 15) - digital/retro aesthetic
- **Speed**: 150ms per frame (25% faster than current 200ms)
- **Scope**: LSP_PROGRESS state only
- **Continuity**: No rest periods, continuous travel
- **Preservation**: Keep `┣┫` brackets, ` LSP` label, `#bb00ff` purple color

---

## Visual Design

### Wave Pattern Progression
```
Frame 0: ┣⎯⎯⎯⎯⎯⎯⎯⎯┫ LSP  (baseline)
Frame 1: ┣⎺⎯⎯⎯⎯⎯⎯⎯┫ LSP  (peak starts building)
Frame 2: ┣⎺⎺⎯⎯⎯⎯⎯⎯┫ LSP  (peak grows)
Frame 3: ┣⎺⎺⎺⎯⎯⎯⎯⎯┫ LSP  (full 3-char peak)
Frame 4: ┣⎯⎺⎺⎺⎯⎯⎯⎯┫ LSP  (peak travels right)
Frame 5: ┣⎯⎯⎺⎺⎺⎯⎯⎯┫ LSP  (continues right)
Frame 6: ┣⎯⎯⎯⎺⎺⎺⎯⎯┫ LSP  (continues right)
Frame 7: ┣⎯⎯⎯⎯⎺⎺⎺⎯┫ LSP  (continues right)
Frame 8: ┣⎯⎯⎯⎯⎯⎺⎺⎺┫ LSP  (peak reaches end)
[loops back to Frame 0]
```

**Total Cycle Time**: 9 frames × 150ms = **1.35 seconds**

### Unicode Characters
- **⎯** (U+23AF): HORIZONTAL LINE EXTENSION - flat baseline
- **⎺** (U+23BA): HORIZONTAL SCAN LINE-1 - raised peak
- **Fallback**: If rendering fails, use `-` and `=` as ASCII alternatives

---

## Task Graph Structure

### Execution Phases

#### **Phase 1: Parallel Research** (Execution Order 1)
Execute these 5 tasks concurrently to gather all required information:

1. **R1** - Heirline Documentation Research (documentation_research_agent)
   - Query Context7 for Heirline provider function capabilities
   - Verify Unicode string handling in Neovim statusline
   - Document component update triggers and timing

2. **R2** - Unicode Character Testing (terminal_testing_agent)
   - Test rendering of ⎯ and ⎺ in user's terminal
   - Verify visual distinction between characters
   - Document fallback options if needed

3. **R3** - LSP Progress Detection Analysis (code_analysis_agent)
   - Map current LSP detection logic
   - Analyze timer architecture (200ms global)
   - Identify update events that trigger refresh

4. **R4** - Bug Review (code_review_agent)
   - Review existing NixieProgressBar bugs from memory
   - Ensure wave implementation won't interfere with fixes
   - Check state initialization issues

5. **V2** - Backup & Rollback Preparation (devops_agent)
   - Create timestamped backup of statusline.lua
   - Document rollback procedures
   - Prepare recovery instructions

**Deliverable**: Comprehensive understanding of system architecture and constraints

---

#### **Phase 2: Design** (Execution Order 2-3)
Sequential design tasks building on research:

6. **D1** - Wave Pattern Design (algorithm_design_agent) *[depends on R2]*
   - Create Lua table with 9 wave pattern strings
   - Validate visual progression
   - Confirm 8-character width fits brackets

7. **D2** - Frame Calculation Logic (algorithm_design_agent) *[depends on R1, R3, D1]*
   - Design formula: `math.floor((vim.loop.now() or 0) / 150) % 9`
   - Calculate timing: 150ms per frame
   - Compare with current 200ms approach

8. **D3** - Implementation Strategy (architecture_design_agent) *[depends on R3, R4]*
   - Decide on self.wave_pattern field approach
   - Plan conditional logic in provider function
   - Ensure isolation from other states

**Deliverable**: Complete technical design with code snippets

---

#### **Phase 3: Implementation** (Execution Order 4-6)
Sequential coding tasks:

9. **I1** - Create Wave Patterns Table (lua_developer_agent) *[depends on D1, D2, D3]*
   - Add `wave_patterns` to NixieProgressBar.static
   - Include 9 patterns with Unicode characters
   - Add explanatory comments

10. **I2** - Modify LSP Detection Logic (lua_developer_agent) *[depends on I1, D2]*
    - Update lines 74-88 with frame calculation
    - Store pattern in self.wave_pattern
    - Preserve existing color and label assignments

11. **I3** - Update Provider Function (lua_developer_agent) *[depends on I2]*
    - Add conditional for LSP_PROGRESS state
    - Return wave display when self.wave_pattern exists
    - Maintain block-based display for other states

**Deliverable**: Fully implemented wave animation code

---

#### **Phase 4: Testing** (Execution Order 7-9)
Parallel and sequential testing:

12. **T1** - LSP Animation Testing (qa_testing_agent) *[depends on I3]*
    - Trigger LSP activity with :LspRestart or formatting
    - Verify wave animation appears
    - Measure frame rate (should be ~150ms)

13. **T2** - State Regression Testing (qa_testing_agent) *[depends on T1]*
    - Test IDLE breathing animation
    - Test MODIFIED pulse animation
    - Test SEARCH progress display
    - Test DIAGNOSTIC error pulse
    - Confirm no visual glitches

14. **T3** - Unicode Compatibility Testing (compatibility_testing_agent) *[depends on T1]*
    - Test rendering in WezTerm (primary)
    - Test in alternative terminals if available
    - Verify no mojibake or encoding issues

15. **T4** - Performance Benchmarking (performance_testing_agent) *[depends on T1, T2]*
    - Measure provider function execution time
    - Monitor CPU usage during animation
    - Verify no lag or stuttering

**Deliverable**: Validated implementation with test results

---

#### **Phase 5: Decision & Documentation** (Execution Order 9-11)

16. **D4** - Timer Decision (architecture_decision_agent) *[depends on R3, D2, T4]*
    - Decide: Keep 200ms global timer OR update to 150ms
    - **Recommendation**: Keep 200ms, use local 150ms calculation
    - Document rationale and impact

17. **DOC1** - Inline Documentation (documentation_agent) *[depends on I3, T2]*
    - Add comment blocks explaining wave design
    - Document 150ms timing choice
    - Explain conditional logic in provider

18. **DOC2** - Implementation Summary (documentation_agent) *[depends on DOC1, T4]*
    - Create before/after comparison
    - Document performance metrics
    - Update NIXIE_STATUSLINE_PLAN.md

**Deliverable**: Complete documentation with rationale

---

#### **Phase 6: Final Validation** (Execution Order 12)

19. **V1** - Integration Testing (qa_validation_agent) *[depends on T1, T2, T3, DOC1]*
    - Test with multiple LSP servers (lua_ls, tsserver, rust-analyzer)
    - Test rapid LSP state changes
    - Verify long-running LSP operations
    - Confirm no race conditions

**Deliverable**: Production-ready implementation

---

## Implementation Details

### Code Changes Summary

#### 1. Static Table Addition (statusline.lua:36-48)
```lua
static = {
    wave_patterns = {
        [0] = "⎯⎯⎯⎯⎯⎯⎯⎯",  -- Baseline
        [1] = "⎺⎯⎯⎯⎯⎯⎯⎯",  -- Peak starts
        [2] = "⎺⎺⎯⎯⎯⎯⎯⎯",  -- Peak grows
        [3] = "⎺⎺⎺⎯⎯⎯⎯⎯",  -- Full peak
        [4] = "⎯⎺⎺⎺⎯⎯⎯⎯",  -- Travel right
        [5] = "⎯⎯⎺⎺⎺⎯⎯⎯",  -- Travel right
        [6] = "⎯⎯⎯⎺⎺⎺⎯⎯",  -- Travel right
        [7] = "⎯⎯⎯⎯⎺⎺⎺⎯",  -- Travel right
        [8] = "⎯⎯⎯⎯⎯⎺⎺⎺",  -- Peak at end
    },
    filetypes = { ... },
},
```

#### 2. LSP Detection Logic (statusline.lua:74-88)
```lua
-- Check LSP progress (animated wave when LSP is working)
local lsp_clients = vim.lsp.get_clients({ bufnr = 0 })
for _, client in pairs(lsp_clients) do
    if client.progress and client.progress.pending and next(client.progress.pending) ~= nil then
        self.state = "LSP_PROGRESS"
        -- Fast stepped wave animation (150ms per frame = 1.35s cycle)
        local frame = math.floor((vim.loop.now() or 0) / 150) % 9
        self.wave_pattern = self.wave_patterns[frame]
        self.color = "#bb00ff" -- Purple for LSP
        self.label = " LSP"
        return
    end
end
```

#### 3. Provider Function (statusline.lua:134-137)
```lua
provider = function(self)
    -- LSP wave animation (stepped pattern)
    if self.state == "LSP_PROGRESS" and self.wave_pattern then
        return "┣" .. self.wave_pattern .. "┫" .. self.label .. " "
    end
    
    -- All other states: block-based display
    local filled = string.rep("▓", self.segments)
    local empty = string.rep("░", 9 - self.segments)
    return "┣" .. filled .. empty .. "┫" .. self.label .. " "
end,
```

---

## Risk Mitigation

### Identified Risks & Contingencies

| Risk | Probability | Impact | Mitigation | Contingency |
|------|-------------|--------|------------|-------------|
| Unicode chars don't render | Low | High | R2 tests early | Use ASCII fallback: `-` and `=` |
| Performance degradation | Medium | Medium | T4 benchmarks | Keep 200ms timing |
| Wave interferes with other states | Low | High | T2 tests all states | Revert using V2 backup |
| LSP detection unreliable | Low | Medium | R3 analyzes logic | Add event triggers |
| Existing bugs cause issues | Medium | Medium | R4 reviews bugs | Fix bugs first (separate task) |

---

## Success Criteria Checklist

- [ ] LSP state shows smooth traveling wave with ⎯⎺ characters
- [ ] Animation completes in ~1.35 seconds (9 frames × 150ms)
- [ ] Wave travels continuously left-to-right without rest
- [ ] IDLE, MODIFIED, SEARCH, DIAGNOSTIC states unchanged
- [ ] No performance degradation or lag
- [ ] Unicode renders correctly (no boxes or glyphs)
- [ ] Purple color #bb00ff preserved
- [ ] ` LSP` label preserved
- [ ] `┣┫` brackets preserved
- [ ] Code documented with inline comments
- [ ] Rollback plan tested and documented

---

## Agent Assignments

| Agent Role | Tasks | Specialization |
|------------|-------|----------------|
| documentation_research_agent | R1 | Heirline/Context7 research |
| terminal_testing_agent | R2 | Unicode rendering tests |
| code_analysis_agent | R3 | LSP logic analysis |
| code_review_agent | R4 | Bug review |
| algorithm_design_agent | D1, D2 | Pattern & timing design |
| architecture_design_agent | D3 | Implementation strategy |
| architecture_decision_agent | D4 | Timer decision |
| lua_developer_agent | I1, I2, I3 | Code implementation |
| qa_testing_agent | T1, T2 | Core functionality testing |
| compatibility_testing_agent | T3 | Cross-terminal testing |
| performance_testing_agent | T4 | Benchmarking |
| documentation_agent | DOC1, DOC2 | Documentation |
| qa_validation_agent | V1 | Final integration testing |
| devops_agent | V2 | Backup & rollback |

---

## Execution Instructions

### Prerequisites
1. Backup current configuration (task V2)
2. Verify Nerd Fonts installed
3. Ensure terminal supports Unicode U+23AF and U+23BA
4. Have test LSP servers available (lua_ls recommended)

### Execution Steps
1. **Start with Phase 1** - Run all research tasks in parallel
2. **Review research findings** - Ensure no blockers identified
3. **Execute Phase 2** - Design tasks sequentially
4. **Review design** - Validate patterns and timing before coding
5. **Execute Phase 3** - Implementation tasks sequentially
6. **Execute Phase 4** - Testing tasks (T1 first, then T2-T4 in parallel)
7. **Make decision** - D4 based on performance results
8. **Execute Phase 5** - Documentation tasks
9. **Execute Phase 6** - Final validation
10. **Verify success criteria** - Check all boxes above

### Rollback Procedure
If any critical issues arise:
```bash
# Option 1: Git rollback
git checkout HEAD -- lua/custom/heirline/statusline.lua

# Option 2: Restore backup
cp lua/custom/heirline/statusline.lua.backup-TIMESTAMP lua/custom/heirline/statusline.lua

# Restart Neovim
nvim
```

---

## Technical Notes

### Why 150ms Timing?
- **Current**: 200ms = 1.8s full cycle (slower, more relaxed)
- **New**: 150ms = 1.35s full cycle (25% faster, more responsive)
- **Rationale**: LSP activity deserves attention-grabbing animation
- **Independence**: Uses `vim.loop.now() / 150` directly, not tied to global timer

### Why 9 Frames?
- Matches existing 9-segment display width
- Provides smooth visual progression
- 3-frame build + 5-frame travel + 1 reset = natural rhythm
- Completes in human-perceptible timeframe (1-2 seconds)

### Why Static Table?
- Performance: Computed once at initialization
- Maintainability: Easy to modify patterns
- Clarity: Self-documenting with visual comments
- Efficiency: No string generation per render

### Why Conditional in Provider?
- **Isolation**: Other states unaffected
- **Safety**: Explicit check prevents unintended behavior
- **Flexibility**: Easy to toggle on/off for debugging
- **Clarity**: Single decision point for wave vs blocks

---

## References

- **Primary File**: `lua/custom/heirline/statusline.lua`
- **Timer Config**: `lua/custom/heirline/init.lua:333-338`
- **Documentation**: `NIXIE_STATUSLINE_PLAN.md`
- **Bug Analysis**: `.serena/memories/neovim-heirline-statusline-analysis.md`
- **Task Graph**: `WAVE_ANIMATION_TASK_GRAPH.json`
- **User Preferences**: `AGENTS.md`

---

## Next Steps

1. Review this plan and task graph thoroughly
2. Confirm Unicode character support in terminal
3. Execute Phase 1 research tasks
4. Report findings and get approval to proceed
5. Execute remaining phases sequentially
6. Celebrate successful implementation! 🎉

---

**Plan Status**: ✅ Ready for Execution  
**Estimated Completion**: 3-4 hours  
**Confidence Level**: High (comprehensive research and testing)
