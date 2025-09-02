local wezterm = require("wezterm")
-- disable tabs
local config = wezterm.config_builder()
-- config.CloseOnCleanExit = true
-- apply colors

config.enable_wayland = true
config.enable_tab_bar = false
config.font = wezterm.font_with_fallback({
	-- { family = "JetBrainsMono NF", weight = "Regular" },
	{ family = "Iosevkaterm NF", weight = "Regular" },
	-- "JetBrainsMono Nerd Font Mono",
	"Noto Color Emoji", -- Add fallback for emojis
})

config.keys = {
	{
		key = "Enter",
		mods = "SHIFT|CTRL",
		action = wezterm.action.ToggleFullScreen,
	},
	{
		key = "Enter",
		mods = "ALT",
		action = wezterm.action.DisableDefaultAssignment,
	},
}
config.font_size = 18
config.window_padding = {
	left = 2,
	right = 1,
	top = 1,
	bottom = 1,
}
config.window_background_opacity = 0.49
-- config.dpi = 192
config.adjust_window_size_when_changing_font_size = false

-- Spawn a fish shell in login mode
config.default_prog = { "/bin/fish", "-l" }

-- if require("overrides") then
-- 	local overrides = require("overrides")
-- 	overrides.override(config)
-- end

return config
