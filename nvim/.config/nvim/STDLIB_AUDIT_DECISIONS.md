# Ponytail Audit Decisions — STDLIB + YAGNI + SHRINK

## FINDING 1: undercurl.lua (42 lines)
- **Decision:** DELETE entirely
- **Reason:** Zero `require("lib.undercurl")` calls anywhere. Dead code.
- **Status:** ✅ Deleted

## FINDING 2: OSC52 autocmd in options.lua
- **Decision:** DELETE autocmd block (lines 19-27)
- **Reason:** Neovim 0.10+ handles OSC52 natively. This was a 0.9 workaround gated on 0.10 check = dead code.
- **Status:** ✅ Deleted

## FINDING 3: vim_sleuth.lua vs options.lua indent conflict
- **Decision:** DELETE vim_sleuth.lua
- **Reason:** options.lua hardcodes tabstop/shiftwidth=4, expandtab=true. vim-sleuth auto-detects and overrides — redundant.
- **Status:** ✅ Deleted

## FINDING 4: borderless.lua (223 → 157 lines)
- **Decision:** SHRINK — loop over BlinkCmpKind highlights, drop unused FzfLua section
- **Reason:** FzfLua not installed, BlinkCmp kind highlights were 20 individual calls
- **Status:** ✅ Shrunk to 157 effective lines

## FINDING 5: obsidian_extras.lua (227 → 87 lines)
- **Decision:** SHRINK — remove 12 duplicate keymaps, keep 4 autocommands + 4 commands
- **Reason:** Keymaps duplicated obsidian.nvim builtins (`:ObsidianNew`, `:ObsidianSearch`, etc.)
- **Status:** ✅ Shrunk to 87 lines

## FINDING 6: opts = {} empty tables
- **Decision:** DELETE from 6 files
- **Files:** quickfix_list.lua, atone.lua, eldritch.lua, daddy_why.lua, store.lua, comment.lua
- **Reason:** Redundant in lazy.nvim — plugin auto-setup handles defaults
- **Status:** ✅ Deleted from all 6

## FINDING 7: kube-schema.nvim.lua
- **Decision:** DELETE
- **Reason:** Zero references outside its own file. Unused plugin.
- **Status:** ✅ Deleted

## FINDING 8: enable = true in LSP configs
- **Decision:** LEAVE ALONE
- **Reason:** These configure specific LSP server capabilities, not plugin-level toggles. Not redundant.
- **Status:** ✅ No change
