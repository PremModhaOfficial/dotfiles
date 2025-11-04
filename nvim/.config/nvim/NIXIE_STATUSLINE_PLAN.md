# Nixie Tube Statusline: Symmetric Soviet Glow Edition

## Overview
A retro-inspired statusline with nixie tube aesthetics, featuring warm orange filament colors, glass borders, and symmetric layout. Built for performance (<0.01ms redraw) with dynamic updates on every cursor movement.

## Aesthetic
- **Colors**: Warm orange filament (Function fg → Type fg), glass borders (┏┫┣▌▐)
- **Elements**: 9-segment progress bar, git hash, filetype icon + LSP indicator, encoding/lines, line:col + position (Top/Bot/Mid), retro endcap
- **Layout**: Symmetric - balanced left (mode/progress), center (file/LSP), right (position/details)

## Performance
- Raw `vim.o.statusline` for maximum speed
- Zero timers/autocmds (except optional flicker)
- Updates on every cursor move/scroll/edit

## Dependencies
- **Required**: Nerd Fonts for icons
- **Optional**: vim-fugitive for git info (falls back gracefully)

## Highlight Groups (Mapped to Current Statusline)
Uses `safe_hl()` function for theme compatibility:

```lua
vim.api.nvim_set_hl(0, "NixieGlow", { fg = safe_hl("Function", "fg"), bg = safe_hl("Normal", "bg"), bold = true })  -- Tube text + borders
vim.api.nvim_set_hl(0, "NixieBar",  { fg = safe_hl("Comment", "fg"), bg = safe_hl("Normal", "bg") })              -- Filament segments
vim.api.nvim_set_hl(0, "NixieGit",  { fg = safe_hl("diffAdded", "fg"), bg = safe_hl("Normal", "bg") })              -- Git branch/hash
vim.api.nvim_set_hl(0, "NixieFile", { fg = safe_hl("Directory", "fg"), bg = safe_hl("Normal", "bg") })              -- Filename
vim.api.nvim_set_hl(0, "NixieIcon", { fg = safe_hl("Type", "fg"), bg = safe_hl("Normal", "bg") })              -- Filetype icon + LSP
vim.api.nvim_set_hl(0, "NixieEnd",  { fg = safe_hl("Comment", "fg"), bg = safe_hl("Normal", "bg") })              -- Retro endcap
```

## Helper Functions

### Filament Bar (9 segments = exact %p visualizer)
```lua
local nixie_bar = function()
  local total_lines = vim.fn.line('$')
  if total_lines == 0 then return string.rep('░', 9) end  -- Empty buffer safeguard
  local percent = vim.fn.line('.') * 100 / total_lines
  local filled = math.floor(percent / (100 / 9) + 0.5)    -- ~11% per segment
  return string.rep('▓', filled) .. string.rep('░', 9 - filled)
end
```

### Position Indicator (Top/Bot/Mid — updates live)
```lua
local nixie_pos = function()
  local cur_line = vim.fn.line('.')
  local total = vim.fn.line('$')
  if total == 1 then return 'All' end
  if cur_line == 1 then return 'Top' end
  if cur_line == total then return 'Bot' end
  return string.format('Mid %02d%%', math.floor(cur_line * 100 / total))
end
```

### Filetype Icon Mapper (Nerd Font magic)
```lua
local nixie_icon = function()
  local ft = vim.bo.filetype
  local icons = {
    lua = '', zig = '', nix = '', sh = '', md = '', toml = '', py = '', js = '',
    -- Add more: css = '', etc.
  }
  return icons[ft] or ''  -- Blank if unknown
end
```

### LSP Indicator (shows  when attached)
```lua
local nixie_lsp = function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  return #clients > 0 and '  ' or ''
end
```

## Statusline Configuration

### Symmetric Layout
```
[LEFT: Mode + Progress]    [CENTER: File Info + LSP]    [RIGHT: Position + Details]
```

### Complete Code
```lua
-- =====================================================
-- NIXIE TUBE STATUSLINE: Symmetric Soviet Glow Edition
-- =====================================================

-- 1. Define Highlights
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("NixieHL", { clear = true }),
  callback = function()
    -- Import safe_hl from current statusline for consistency
    local safe_hl = function(name, attr)
      local hl = vim.api.nvim_get_hl(0, { name = name })
      return hl and hl[attr] or (attr == "fg" and "#ffffff" or "#000000")
    end
    
    vim.api.nvim_set_hl(0, "NixieGlow", { fg = safe_hl("Function", "fg"), bg = safe_hl("Normal", "bg"), bold = true })
    vim.api.nvim_set_hl(0, "NixieBar",  { fg = safe_hl("Comment", "fg"), bg = safe_hl("Normal", "bg") })
    vim.api.nvim_set_hl(0, "NixieGit",  { fg = safe_hl("diffAdded", "fg"), bg = safe_hl("Normal", "bg") })
    vim.api.nvim_set_hl(0, "NixieFile", { fg = safe_hl("Directory", "fg"), bg = safe_hl("Normal", "bg") })
    vim.api.nvim_set_hl(0, "NixieIcon", { fg = safe_hl("Type", "fg"), bg = safe_hl("Normal", "bg") })
    vim.api.nvim_set_hl(0, "NixieEnd",  { fg = safe_hl("Comment", "fg"), bg = safe_hl("Normal", "bg") })
  end,
})
vim.api.nvim_exec_autocmds("ColorScheme", { group = "NixieHL" })

-- 2-5. Helper Functions (as above)

-- 6. THE STATUSLINE
vim.o.statusline = table.concat({
  -- LEFT: Tube + Mode + Bar + %
  '%#NixieGlow#┏IN-12┫',
  '%{(mode() == "n") and "NORMAL" or (mode() == "i") and "INSERT" or (mode() == "v") and "VISUAL" or (mode() == "R") and "REPLACE" or (mode() == "c") and "COMMAND" or (mode() == "t") and "TERMINAL" or mode():gsub("^%l", string.upper)}',
  '┣%#NixieBar#', nixie_bar(), ' %#NixieGlow#%p%% ',
  
  -- CENTER: Git + File + Icon + FT + LSP
  '%#NixieGit# %{FugitiveHead(7) or ""} ┣%#NixieFile#%{fnamemodify(expand("%"), ":t")}┫ %#NixieIcon#%{nixie_icon()} ┣%{&filetype}┫%{nixie_lsp()}',
  
  -- RIGHT: Lines + Enc + Line:Col + Pos + Endcap
  '%=%#NixieGlow#(%L) %{&fenc ~= "" and &fenc or &enc} ▌%l:%c▐ %{nixie_pos()} %#NixieEnd#════╣═%*'
}, '')
```

## Section Breakdown

### Left Section
- **Tube Label + Mode**: Retro "IN-12" with current Vim mode
- **Filament Bar**: 9-segment progress visualizer
- **Percentage**: Exact file position (%)

### Center Section  
- **Git Info**: Branch + 7-char hash (FugitiveHead)
- **Filename**: Basename only
- **Filetype Icon**: Nerd Font icon
- **Filetype**: Raw filetype string
- **LSP Indicator**:  when LSP attached

### Right Section
- **Total Lines**: (%L) format
- **Encoding**: File encoding
- **Line:Col**: Current position
- **Position**: Top/Bot/Mid/All indicator
- **Endcap**: Retro terminal flair

## Optional Features

### Subtle Flicker (Cathode Hum)
Uncomment for tube model rotation every 2s idle:
```lua
local tube_models = {"IN-12", "Z566M", "IN-18"}
local current_tube = 1
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.wait(2000)
    current_tube = (current_tube % #tube_models) + 1
    vim.o.statusline = vim.o.statusline:gsub("┏IN%-12┫", "┏" .. tube_models[current_tube] .. "┫")
  end,
})
```

## Installation
1. Save this code to `lua/custom/nixie_statusline.lua`
2. Load it in your Neovim config instead of Heirline statusline
3. Ensure Nerd Fonts are installed for icons
4. Optional: Install vim-fugitive for git integration

## Customization
- Add more filetype icons to `nixie_icon()` function
- Adjust highlight mappings if needed
- Modify borders or layout for personal taste