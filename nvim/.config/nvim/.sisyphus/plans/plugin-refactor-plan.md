# Neovim Plugin Structure Refactoring Plan

## Overview

**Goal**: Refactor plugin structure for cohesion, extensibility, and AI-assisted change tracking (clear blast radius).

**Principles**:
1. One plugin = one file (or clearly grouped)
2. Consistent `snake_case` naming
3. Clear section markers for AI grep-ability
4. Keymaps: global in core + plugin-specific with markers

---

## Phase 1: Cleanup (Low Risk)

### 1.1 Delete Archive
**Blast Radius**: None (unused code)

```
DELETE: lua/_archive/ (entire directory)
```

**Rationale**: Git history preserves everything. Archive clutters config and confuses AI tools.

---

### 1.2 Remove MCP-Related Code
**Blast Radius**: `plugins/ai/mcphub.lua`, `mcp_servers/`, `lib/codecompanion_fix.lua`

```
DELETE: lua/mcp_servers/ (entire directory)
DELETE: lua/plugins/ai/mcphub.lua
DELETE: lua/lib/codecompanion_fix.lua
```

**Verification**: Grep for `require.*mcp` and `require.*codecompanion_fix` to ensure no dangling references.

---

## Phase 2: Naming Standardization (Medium Risk)

### 2.1 Rename Plugin Files to snake_case
**Blast Radius**: File renames only, no code changes needed (lazy.nvim uses directory imports)

| Current | New |
|---------|-----|
| `plugins/ai/CopilotChat.lua` | `plugins/ai/copilot_chat.lua` |
| `plugins/ai/VectorCode.lua` | `plugins/ai/vector_code.lua` |
| `plugins/core/THENONELS.lua` | `plugins/core/none_ls.lua` |
| `plugins/tools/Overseer.lua` | `plugins/tools/overseer.lua` |
| `plugins/editor/qickList.lua` | `plugins/editor/quickfix_list.lua` |
| `plugins/ui/colorschemes/colorSchemes.lua` | `plugins/ui/colorschemes/theme_picker.lua` |

**Note**: Files already in snake_case or kebab-case stay as-is. Kebab-case is acceptable (Lua handles it).

---

### 2.2 Standardize Lang Plugin Naming
**Blast Radius**: `plugins/lang/` directory

| Current | New |
|---------|-----|
| `lang-java.lua` | `java.lua` |
| `lang-rust.lua` | `rust.lua` |
| `lang-sql.lua` | `sql.lua` |
| `lang-typescript.lua` | `typescript.lua` |

**Rationale**: The `lang/` folder already indicates these are language configs. `lang-` prefix is redundant.

---

## Phase 3: Extract Inline Plugins (Medium Risk)

### 3.1 Move Inline Plugins from `core/lazy.lua`
**Blast Radius**: `core/lazy.lua` + new files in `plugins/core/`

Currently inline in `core/lazy.lua`:
- `tpope/vim-sleuth`
- `numToStr/Comment.nvim`
- `folke/lazydev.nvim`
- `Bilal2453/luvit-meta`
- `lewis6991/gitsigns.nvim`
- `folke/which-key.nvim`
- `stevearc/conform.nvim`
- `folke/todo-comments.nvim`

**New Files**:

```
plugins/core/
  vim_sleuth.lua      # vim-sleuth (simple, one-liner)
  comment.lua         # Comment.nvim
  lazydev.lua         # lazydev + luvit-meta (grouped - both for Lua dev)
  gitsigns.lua        # gitsigns.nvim
  which_key.lua       # which-key.nvim
  conform.lua         # conform.nvim (formatting)
  todo_comments.lua   # todo-comments.nvim
```

**Updated `core/lazy.lua`**:
```lua
require("lazy").setup({
  rocks = { hererocks = true },
  spec = {
    { import = "plugins.core" },
    { import = "plugins.editor" },
    { import = "plugins.ui" },
    { import = "plugins.ui.colorschemes" },
    { import = "plugins.git" },
    { import = "plugins.lang" },
    { import = "plugins.ai" },
    { import = "plugins.tools" },
  },
}, {
  ui = { ... }
})
```

---

### 3.2 Fix Code Duplication
**Blast Radius**: `core/lazy.lua`, `lib/utils.lua`

The `border()` function is duplicated. 

**Action**: 
1. Keep `border()` in `lib/utils.lua`
2. Update `core/lazy.lua` to use `require("lib.utils").border`
3. Update any other files using local `border()` to use the shared one

---

## Phase 4: Structural Improvements (Low Risk)

### 4.1 Remove Empty Folder
**Blast Radius**: None

```
DELETE: lua/plugins/lsp/ (empty directory)
```

---

### 4.2 Add Section Markers for AI Grep-ability
**Blast Radius**: All plugin files (additive change)

Add standardized comment markers to each plugin file:

```lua
-- ============================================================================
-- PLUGIN: <plugin-name>
-- PURPOSE: <one-line description>
-- DEPENDENCIES: <comma-separated list or "none">
-- ============================================================================

return {
  "<owner>/<repo>",
  
  -- ... config ...

  -- ================================ KEYMAPS ==================================
  keys = {
    -- keymaps here
  },
  
  -- ================================ AUTOCMDS =================================
  -- (if any autocmds defined in config function)
}
```

**Priority**: Apply to frequently-modified files first:
1. `plugins/core/lspconfig.lua`
2. `plugins/ai/codecompanion.lua`
3. `plugins/editor/snacks.lua`
4. `plugins/lang/*.lua`

---

### 4.3 Organize `lib/` Utilities
**Blast Radius**: `lib/` directory

| Current | Action |
|---------|--------|
| `lib/utils.lua` | Keep (shared utilities) |
| `lib/custom-java.lua` | Rename to `lib/java_runner.lua` |
| `lib/obsidianCustoms.lua` | Rename to `lib/obsidian_extras.lua` |
| `lib/undercurl.lua` | Keep or merge into utils if small |
| `lib/codecompanion_fix.lua` | DELETE (Phase 1.2) |

Update references in:
- `plugins/lang/java.lua` (after rename)
- `plugins/tools/obsidian.lua`

---

## Phase 5: Final Structure

```
lua/
  core/
    init.lua          # Bootstrap
    options.lua       # Vim options
    keymaps.lua       # Global keymaps (with section markers)
    autocmds.lua      # Global autocmds
    lazy.lua          # Minimal - just imports

  lib/
    utils.lua         # Shared utilities (border, colorscheme helpers)
    java_runner.lua   # Java/Vert.x execution logic
    obsidian_extras.lua  # Obsidian enhancements

  plugins/
    core/
      blink.lua
      comment.lua           # NEW (from inline)
      conform.lua           # NEW (from inline)
      gitsigns.lua          # NEW (from inline)
      lazydev.lua           # NEW (from inline, includes luvit-meta)
      lspconfig.lua
      none_ls.lua           # RENAMED from THENONELS.lua
      todo_comments.lua     # NEW (from inline)
      treesitter.lua
      vim_sleuth.lua        # NEW (from inline)
      which_key.lua         # NEW (from inline)

    editor/
      harpoon.lua
      minifiles.lua
      mini-pairs.lua
      quickfix_list.lua     # RENAMED from qickList.lua
      search-replace.lua
      snacks.lua
      undootree.lua
      vim-tmux-navigator.lua
      wezterm.lua

    ui/
      colorschemes/
        aurora.lua
        bluloco.lua
        ... (unchanged)
        theme_picker.lua    # RENAMED from colorSchemes.lua
      diagnostics_ui.lua
      dropbar.lua
      heirline/
        init.lua
        statuscolumn.lua
        statusline.lua
      heirline.lua
      indets.lua
      lualine-evil.lua
      mini-icons.lua
      ui.lua

    git/
      lazygit.lua
      lazyjj.lua

    lang/
      java.lua              # RENAMED from lang-java.lua
      rust.lua              # RENAMED from lang-rust.lua
      sql.lua               # RENAMED from lang-sql.lua
      typescript.lua        # RENAMED from lang-typescript.lua

    ai/
      codecompanion.lua
      copilot.lua
      copilot_chat.lua      # RENAMED from CopilotChat.lua
      opencode.lua
      sidekick.lua
      supermaven.lua
      vector_code.lua       # RENAMED from VectorCode.lua

    tools/
      daddy_why.lua
      dap.lua
      diagrams.lua
      image.lua
      leetcode.lua
      neotest.lua
      obsidian.lua
      orgmode.lua
      overseer.lua          # RENAMED from Overseer.lua
      rest.lua

DELETED:
  - lua/_archive/ (entire directory)
  - lua/mcp_servers/ (entire directory)
  - lua/plugins/ai/mcphub.lua
  - lua/plugins/lsp/ (empty directory)
  - lua/lib/codecompanion_fix.lua
```

---

## Execution Order

| Step | Phase | Risk | Reversible | Verification |
|------|-------|------|------------|--------------|
| 1 | Delete `_archive/` | None | Git | N/A |
| 2 | Delete MCP-related files | Low | Git | `grep -r "mcp\|codecompanion_fix" lua/` |
| 3 | Delete empty `plugins/lsp/` | None | Git | N/A |
| 4 | Rename plugin files (snake_case) | Medium | Git | `:Lazy` shows all plugins loading |
| 5 | Extract inline plugins to files | Medium | Git | `:Lazy` shows all plugins loading |
| 6 | Fix `border()` duplication | Low | Git | No errors on startup |
| 7 | Rename `lib/` files | Low | Git | No errors on startup |
| 8 | Add section markers | None | Git | N/A (additive) |

---

## Rollback Strategy

Each phase is a separate git commit:
```bash
git commit -m "refactor(nvim): delete archive directory"
git commit -m "refactor(nvim): remove mcp-related code"
git commit -m "refactor(nvim): standardize plugin filenames to snake_case"
git commit -m "refactor(nvim): extract inline plugins from lazy.lua"
git commit -m "refactor(nvim): consolidate lib utilities"
git commit -m "refactor(nvim): add section markers for AI grep-ability"
```

If any phase breaks config: `git revert HEAD`

---

## AI Blast Radius Improvements

After refactoring, AI tools can:

1. **Find plugin config by name**: `grep -l "copilot" plugins/` finds `copilot.lua`, `copilot_chat.lua`
2. **Find all keymaps for a plugin**: Search for `-- ================================ KEYMAPS` in file
3. **Understand scope**: One file = one plugin = one concern
4. **Predict file locations**: snake_case naming is predictable
5. **Avoid accidental changes**: No inline plugins in lazy.lua means no accidental edits to core loading

---

## Post-Refactor Verification Checklist

- [ ] `:Lazy` shows all plugins loaded
- [ ] `:checkhealth` passes
- [ ] LSP attaches correctly (`:LspInfo`)
- [ ] Treesitter works (`:TSInstallInfo`)
- [ ] Keymaps work (`<leader>` shows which-key)
- [ ] Colorscheme loads
- [ ] No startup errors (`:messages`)
