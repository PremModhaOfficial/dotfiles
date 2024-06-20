local wezterm = require("wezterm")
local colors = require("colors")
--
-- disable tabs
local config = wezterm.config_builder()

config.enable_wayland = false
config.enable_tab_bar = false
config.font = wezterm.font("JetBrainsMono NFM", { weight = "Regular" })

config.font_size = 18
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}
config.window_background_opacity = 0.75
-- config.dpi = 192
config.adjust_window_size_when_changing_font_size = false

colors.apply_colors(config)
-- Spawn a fish shell in login mode
config.default_prog = { "/bin/fish", "-l" }

return config
