Run these commands in Neovim to check and list key bindings:

1. List all keymaps: `:map` or `:nmap` for normal mode, `:vmap` for visual, etc.

2. Search for Avante-specific keymaps: `:map | grep Avante` or `:map | grep leader`

3. Check if leader key is set: `:echo g:mapleader` (usually backslash)

4. For blink.cmp keymaps: `:map | grep blink` or `:map | grep C-a`

5. For Snacks keymaps: `:map | grep Snacks` or `:map | grep leader>gi`

6. If keymaps are missing, they might be conflicted. Check for conflicts with `:map <leader>aa` etc.

Paste output of keymap checks to .context/keymaps_output.md