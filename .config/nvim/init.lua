-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

if vim.g.neovide then
    vim.o.guifont = "JetBrains Mono NL Bold Nerd Font Complete Mono" -- text below applies for VimScript
    vim.g.neovide_transparency = 0.2
    vim.g.neovide_scroll_animation_length = 0.3
    vim.g.neovide_refresh_rate = 90
    vim.g.neovide_refresh_rate_idle = 5
    vim.g.neovide_confirm_quit = true
    vim.g.neovide_fullscreen = true
    -- vim.g.neovide_profiler = true
    vim.g.neovide_input_use_logo = true -- true on macOS
    vim.g.neovide_input_macos_alt_is_meta = true
    vim.g.neovide_cursor_trail_size = 0.8
    vim.g.neovide_cursor_animate_command_line = true
    vim.g.neovide_underline_automatic_scaling = true
    vim.g.neovide_scale_factor = 1.15
    vim.g.neovide_floating_blur_amount_x = 2.0
    vim.g.neovide_floating_blur_amount_y = 2.0
end
