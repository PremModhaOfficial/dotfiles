local wezterm = require("wezterm")
local colors = require("theme")
-- disable tabs
local config = wezterm.config_builder()
-- config.CloseOnCleanExit = true
-- apply colors
colors.apply_colors(config)

config.enable_wayland = false
config.enable_tab_bar = false
config.font = wezterm.font_with_fallback({
	-- { family = "Iosevkaterm NF", weight = "Regular" },
	{ family = "JetBrainsMono NF", weight = "Light" },
	-- "JetBrainsMono NF",
	"Noto Color Emoji", -- Add fallback for emojis
})

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
	left = 2,
	right = 1,
	top = 1,
	bottom = 1,
}
config.window_background_opacity = 0.69
-- config.dpi = 192
config.adjust_window_size_when_changing_font_size = false

-- Spawn a fish shell in login mode
config.default_prog = { "/bin/fish", "-l" }

if require("overrides") then
	local overrides = require("overrides")
	overrides.override(config)
end

return config
