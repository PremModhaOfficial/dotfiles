# Neovim Heirline Statusline Configuration Analysis

## File Overview
**Location**: `lua/custom/heirline/statusline.lua`
**Purpose**: Custom statusline implementation using Heirline plugin with Nixie tube aesthetic

## Key Components

### 1. Performance Optimizations
- **Highlight Caching**: `safe_hl()` function with cache mechanism for performance
- **Cache Management**: Automatic cache clearing on colorscheme changes
- **Update Events**: Optimized component refresh frequencies

### 2. Core Statusline Components

#### VimMode Component (Lines 122-224)
- **LED Indicator**: `<|●|>` with dynamic color based on mode
- **Mode Names**: Comprehensive mapping for all Vim modes
- **Colors**: Mode-specific colors using syntax highlight groups
- **Update Events**: `ModeChanged` with scheduled redraw

#### NixieProgressBar (Lines 35-119)
- **State Machine**: Priority system - SEARCH > LSP_PROGRESS > DIAGNOSTIC > MODIFIED > IDLE
- **Visual Design**: `┣▓▓▓░░░░░┫` format with 9-segment display
- **States**:
  - SEARCH: Green, shows search progress (current/total)
  - LSP_PROGRESS: Purple, animated spinner effect
  - DIAGNOSTIC: Red/Yellow based on error/warning count
  - MODIFIED: Orange, based on changedtick
  - IDLE: Default gray

#### GitBranch Component (Lines 227-275)
- **Branch Display**: Shows current branch (defaults to "main")
- **Git Status**: Added/Changed/Removed counts with colors
- **Click Handler**: Opens Snacks git branch picker
- **Colors**: Comment fg for branch, diffAdded fg for changes

#### FilePath Component (Lines 278-331)
- **Toggle Display**: Click to toggle between filename and full path
- **Format**: `┣ filename ┫` with directory colors
- **Click Handler**: Toggles `show_full_path` state

#### LspDiagnostics Component (Lines 334-413)
- **Error/Warning Display**: Boxed format with `▌E#▐` and `▌W#▐ `
- **Click Handler**: Opens Snacks diagnostics picker
- **Colors**: DiagnosticError/DiagnosticWarn backgrounds

#### LspAttached Component (Lines 416-462)
- **Server Display**: Shows connected LSP servers separated by "+"
- **Filtering**: Excludes copilot and efm by default
- **Click Handler**: Opens `:LspInfo`
- **Colors**: Bright cyan/blue (#00d7ff)

#### Ruler Component (Lines 465-593)
- **Multi-part Display**:
  - Total lines: `[123]` (light gray)
  - Encoding: `utf-8` (bright green #00ff87)
  - Position: `[12:34]` (purple #d787ff)
  - Position indicator: `Top/Mid/Bot` (purple #bb00ff)
  - Dynamic dial: Position-based gradient (orange to red)
- **Click Handler**: Jump to top/bottom of file

### 3. Specialized Components

#### AI Integration (Lines 596-648)
- **CodeCompanion**: Processing indicator with space
- **CodeCompanionAgent**: Agent indicator with `󱙺` icon
- **Update Events**: User autocommands for request states

#### MacroRec Component (Lines 651-671)
- **Recording Indicator**: Shows `┫ 󱎘 @x ┣` when recording
- **Colors**: Hot pink (#ff0066)
- **Update Events**: RecordingEnter/RecordingLeave

#### FileType Component (Lines 674-717)
- **Icon Mapping**: Extensive filetype icon dictionary
- **Display**: `┣ 󰢱 lua ┫` format
- **Colors**: Warm amber/orange (#ff8800)

### 4. Statusline Structure (Lines 720-764)
- **Left Section**: VimMode, NixieProgressBar, GitBranch, FilePath, FileType, LspDiagnostics
- **Center**: `%=` (space filler)
- **Right Section**: CodeCompanionAgent, CodeCompanion, MacroRec, LspAttached, Ruler

### 5. Filetype Exclusions
- **Inactive Filetypes**: alpha, lazy, TelescopePrompt, netrw, etc.
- **Conditional Display**: Components check against exclusion lists

## Design Philosophy
- **Nixie Tube Aesthetic**: Retro digital display with box characters
- **Color Coding**: Semantic colors for different states and information types
- **Interactive Elements**: Click handlers for navigation and information access
- **Performance Focus**: Cached highlights and optimized update events
- **Information Density**: Maximum relevant information in minimal space

## Bugs Found in NixieProgressBar

### Bug 1: Missing self.label Initialization (CRITICAL)
**Location**: Lines 40-97, init function
**Issue**: `self.label` is NOT initialized in the default IDLE state (line 97). Only set in other states. This can cause `nil` errors.
**Behavior**: When buffer enters IDLE state at startup, `self.label` is undefined, which will cause concatenation errors in the provider function (line 102: `self.label .. " "`).
**Impact**: Statusline may crash or show incorrect display on IDLE state.
**Fix**: Add `self.label = ""` in the default IDLE state initialization (line 97).

### Bug 2: Uninitialized state.filetypes in condition (CRITICAL)
**Location**: Lines 36-39, condition function
**Issue**: The condition checks `self.filetypes` but this variable is NEVER initialized in NixieProgressBar's init function. It's only defined in the main statusline's static table (lines 722-732).
**Behavior**: Will reference an inherited variable that may not exist in the component's context reliably.
**Impact**: Condition may fail to properly exclude special filetypes, causing the bar to display in inappropriate buffers (git, alpha, lazy, etc.).
**Fix**: Either inherit from statusline's static table or initialize self.filetypes in the component's own static table.

### Bug 3: LSP Progress Frame Animation (MINOR)
**Location**: Line 64 in init function
**Issue**: LSP progress uses `local frame = math.floor(vim.loop.now() / 100) % 9`, giving range 0-8, which creates a 9-frame animation. However, statusline init() is called on EACH update event, so the animation frame changes based on when init() is called, not on continuous time.
**Impact**: Animation may appear jerky or not truly continuous since it's tied to event-driven updates rather than render loops.
**Fix**: Less critical as it still animates, but could be smoothed with a different time-based approach.

### Bug 4: Inconsistent Segment Scaling
**Location**: Lines 52, 65, 77, 87
**Issue**: Different state scaling formulas:
- SEARCH: `math.min(9, math.floor((current / total) * 9))` → 0-9
- LSP: `frame` → 0-8 (only 9 frames)
- DIAGNOSTIC: `math.min(9, math.floor((total_diag / 10) * 9) + 1)` → 1-9 (minimum 1 segment)
- MODIFIED: `math.min(9, math.floor((changedtick % 100) / 11) + 1)` → 1-9 (minimum 1 segment)
**Impact**: LSP shows 0-8 range while others show 0-9 or 1-9, creating visual inconsistency. DIAGNOSTIC and MODIFIED always show at least 1 segment even with 0 issues.

## Technical Implementation
- **Heirline Framework**: Component-based statusline system
- **Snacks Integration**: Uses Snacks picker for interactive elements
- **Vim API**: Extensive use of `vim.api` and `vim.fn` for state
- **Event-Driven**: Responsive updates based on Vim events
- **Modular Design**: Each component is self-contained with its own logic

## Color Scheme Integration
- **Dynamic Colors**: Uses syntax highlight groups for theme compatibility
- **Fallback Colors**: White/black defaults for missing highlights
- **Custom Colors**: Specific hex values for consistent UI elements
- **Theme Adaptation**: Automatically adapts to colorscheme changes

## COMPREHENSIVE BUG ANALYSIS & SOLUTIONS

### Critical Bug #1: Missing self.label Initialization in IDLE State
**Severity**: CRITICAL (Causes runtime error)
**Location**: statusline.lua:97
**Root Cause**: Inconsistent state initialization across branches
**Problem Details**:
- init() function has 4 state branches: SEARCH, LSP_PROGRESS, DIAGNOSTIC, MODIFIED
- Each branch initializes self.label with specific text
- BUT IDLE state (lines 94-97) does NOT initialize self.label
- provider() function (line 102) concatenates: self.label .. " "
- This causes nil error when component is in IDLE state

**Heirline Architecture Context**:
- From DeepWiki: Component init() runs during evaluation phase (step 3)
- Provider function executes after init() (step 6)
- If init() leaves variables undefined, provider() will fail
- This is a violation of component contract: init() must fully initialize all state

**Solution Approach**:
Add missing initialization in default IDLE state

### Critical Bug #2: Missing self.filetypes Static Table
**Severity**: CRITICAL (Violates encapsulation, unreliable behavior)
**Location**: statusline.lua:36-39
**Root Cause**: Reliance on inherited state without declaring dependency
**Problem Details**:
- condition() accesses self.filetypes
- self.filetypes is ONLY defined in parent statusline's static table (lines 722-732)
- Component relies on implicit inheritance through Heirline's metatable system
- Per DeepWiki: "Property Inheritance and Restriction" - restricted fields don't auto-inherit
- filetypes is not defined in restricted[] list, so it CAN inherit, but it's unreliable

**Heirline Architecture Context**:
- From DeepWiki: Components inherit parent properties unless restricted
- Static table values are NOT automatically inherited in all cases
- Best practice: Components should declare all dependencies
- The inherit model is prototype-chain based but fragile without explicit declaration

**Solution Approach**:
- Define component-level static table with its own filetypes
- OR explicitly access parent via nonlocal() helper
- Best: Self-contained component definition

### Minor Design Issue #3: Inconsistent Segment Scaling
**Severity**: MEDIUM (Visual inconsistency)
**Location**: Lines 52, 65, 77, 87
**Problem Details**:
- SEARCH: 0-9 segments (uses math.min)
- LSP: 0-8 segments (uses % 9)
- DIAGNOSTIC: 1-9 segments (always +1)
- MODIFIED: 1-9 segments (always +1)
- Visual inconsistency: LSP/SEARCH can show full empty, others always show minimum

**Root Cause**: Different algorithmic approaches to segment calculation
**Impact**: User sees inconsistent visual feedback

**Solution Approach**:
Standardize scaling to consistent range (0-9) across all states

### Minor Design Issue #4: Event-Driven Animation Jitter
**Severity**: LOW (Polish issue)
**Location**: Line 64
**Problem Details**:
- LSP spinner uses `vim.loop.now() / 100 % 9` (time-based)
- BUT init() is called on update events, not continuous render loop
- Events: TextChanged, DiagnosticChanged, LspProgress, User, CursorHold
- CursorHold happens every ~4 seconds by default
- Animation frames are EVENT-DRIVEN, not time-driven = jerky

**Root Cause**: Mixing continuous time calculation with event-driven updates
**Impact**: Animation doesn't appear smooth

**Solution Approach**:
Use stable event-driven spinner (rotating array) instead of time-based

## HEIRLINE BEST PRACTICES APPLIED

From DeepWiki research:

1. **Component Isolation** (from Inheritance doc):
   - Don't rely on implicit parent inheritance
   - Declare component dependencies explicitly
   - Use static tables for component-level configuration

2. **Init Function Contract** (from Evaluation & Rendering):
   - Init must fully initialize ALL state variables used in provider/hl/condition
   - Follow evaluation order: init → hl → on_click → provider
   - Provider assumes init completed successfully

3. **Update Events** (from Update doc):
   - Use specific events, not broad ones
   - Cache management is automatic
   - Per-window caching prevents cross-window state pollution

4. **Condition Function** (from Condition doc):
   - Must be pure (no side effects)
   - Should be efficient (called on every update)
   - Has access to self state via component instance

## QUESTIONS FOR USER

Before implementing fixes, I need clarification on:

1. **Nixie Tube Animation**: Do you want smooth continuous animation or event-driven spinner?
   - Current: Event-driven (jerky but lightweight)
   - Option A: Time-based (smooth but needs different approach)
   - Option B: Deterministic spinner pattern (smooth, no timekeeping)

2. **Filetype Exclusion Scope**: Should NixieProgressBar have its own filetype list or inherit from parent?
   - Current: Implicitly inherits from parent statusline
   - Option A: Copy parent's list to component's static table
   - Option B: Reference parent via explicit helper function
   - Option C: Make component standalone with minimal exclusion list

3. **Segment Scaling Consistency**: What's your preference for segment range?
   - Option A: All states use 0-9 (SEARCH currently does this)
   - Option B: All states use 1-10 (DIAGNOSTIC currently does this)
   - Option C: Context-aware (empty bar for 0 state, show minimum when active)

4. **State Machine Priority**: Is the current priority order optimal?
   - Current: SEARCH > LSP_PROGRESS > DIAGNOSTIC > MODIFIED > IDLE
   - Would you change this? For example, should diagnostics take priority over search?