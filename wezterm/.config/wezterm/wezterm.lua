local wezterm = require("wezterm")
local colors = require("colors")
--
-- disable tabs
local config = wezterm.config_builder()

-- config.CloseOnCleanExit = true

config.enable_wayland = false
config.enable_tab_bar = false
config.font = wezterm.font("JetBrainsMono NF", { weight = "Regular" })

config.keys = {
	-- Turn off the default CMD-m Hide action, allowing CMD-m to
	-- be potentially recognized and handled by the tab
	{
		key = "Enter",
		mods = "ALT",
		action = wezterm.action.DisableDefaultAssignment,
	},
}
config.font_size = 18
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}
config.window_background_opacity = 0.69
-- config.dpi = 192
config.adjust_window_size_when_changing_font_size = false

colors.apply_colors(config)
-- Spawn a fish shell in login mode
config.default_prog = { "/bin/fish", "-l" }

return config
