# Neovim Configuration Project Conventions

## Architecture
- **Base**: Kickstart.nvim with Lazy.nvim plugin manager
- **Structure**: Modular organization in `lua/custom/` directory
- **Entry Point**: `init.lua` loads Lazy.nvim and custom plugin specs

## Plugin Organization
```
lua/custom/
├── ai/           # AI assistance plugins (avante, codecompanion, copilot)
├── colors/       # Colorscheme configurations
├── editor/       # Editor integrations (wezterm)
├── plugins/      # Core plugins (40+ files)
├── heirline/     # Custom statusline/statuscolumn
└── archives/     # Old/backup configurations
```

## Completion System
- **Engine**: Blink.cmp v1.6.0 with performance optimizations
- **AI Providers**: avante, codecompanion, copilot (OpenRouter backend)
- **Model**: qwen/qwen3-coder:free with tool support
- **Performance**: Ghost text, buffer caching (500k limit), optimized sources

## Autopairs Current State
- **Plugin**: saghen/blink.pairs
- **Location**: `lua/custom/plugins/autopairs.lua`
- **Features**: Basic bracket/quote pairing
- **Disabled Filetypes**: TelescopePrompt, codecompanion, Avante
- **Custom Highlights**: orange, purple, blue, unmatched pairs

## User Preferences
- **Performance First**: Optimized for smooth experience
- **Clean Aesthetics**: Minimal but informative design
- **Dynamic Colors**: Mode-based with cached highlights
- **Tool Integration**: Seamless AI and development tool integration

## Key Dependencies
- Blink.cmp integration (autopairs must work with completion)
- Custom Heirline statusline (visual consistency)
- AI plugin compatibility (avoid conflicts in chat buffers)
