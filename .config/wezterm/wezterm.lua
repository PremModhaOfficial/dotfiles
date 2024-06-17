-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.enable_wayland = false

-- For example, changing the color scheme:
-- config.color_scheme = "tokyonight"
config.font = wezterm.font("JetBrainsMono NFM")
config.font_size = 16.0
config.line_height = 1.0
config.enable_tab_bar = false
config.window_background_opacity = 0.77
config.adjust_window_size_when_changing_font_size = false
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}
config.keys = {
	{ key = "+", mods = "CTRL", action = wezterm.action.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
	{ key = "\r", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },
}

config.default_prog = { "/usr/bin/fish" }

local colors = require("colors")
-- and finally, return the configuration to wezterm

colors.apply_to_config(config)

return config
