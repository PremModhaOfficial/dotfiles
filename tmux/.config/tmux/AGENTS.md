# AGENTS.md - Dotfiles Configuration Guide

## Build/Lint/Test Commands

### Configuration Validation
- **Validate tmux config**: `tmux source ~/.config/tmux/tmux.conf`
- **Check shell scripts**: `shellcheck Scripts/.local/bin/*`
- **Lua syntax check**: `luacheck nvim/.config/nvim/init.lua`
- **Test tmux sessionizer**: `./Scripts/.local/bin/tmux-sessionizer --help`

### Neovim Plugin Management
- **Update plugins**: `:Lazy update` (in Neovim)
- **Check plugin status**: `:Lazy` (in Neovim)
- **Health check**: `:checkhealth` (in Neovim)

## Code Style Guidelines

### Shell Scripts (Bash/Fish)
- Use `#!/usr/bin/env bash` or `#!/usr/bin/env fish` shebangs
- Quote all variable expansions: `"$variable"`
- Use `set -euo pipefail` for robust error handling
- Functions should use `local` for variables
- Follow POSIX shell standards where possible

### Lua (Neovim Configuration)
- Use 4-space indentation (matching Neovim defaults)
- Prefer `vim.keymap.set()` over legacy `vim.api.nvim_set_keymap()`
- Use descriptive variable names with snake_case
- Group related configurations with clear comments
- Follow Neovim Lua API conventions

### Naming Conventions
- **Shell scripts**: lowercase with hyphens (`tmux-sessionizer`)
- **Lua modules**: snake_case (`custom.plugins`)
- **Variables**: snake_case (`selected_name`)
- **Functions**: PascalCase for constructors, camelCase for methods

### Error Handling
- Check command success with `||` operators
- Use `set -e` to exit on errors in shell scripts
- Validate inputs before processing
- Provide meaningful error messages

### File Organization
- Keep configurations modular and well-documented
- Use consistent directory structure
- Separate concerns (colors, plugins, keymaps)
- Include comments for complex configurations

### Security Best Practices
- Avoid storing secrets in dotfiles
- Use secure permissions on sensitive scripts (`chmod 700`)
- Validate external inputs and URLs
- Follow principle of least privilege

### Testing Approach
- Manual testing for configuration changes
- Use `tmux source-file` to test tmux changes
- Restart Neovim to test Lua configuration changes
- Test scripts individually before integration

### Commit Guidelines
- Use descriptive commit messages
- Test configurations before committing
- Include relevant context in commit messages
- Keep commits focused on single changes