local wezterm = require("wezterm")
-- disable tabs
local config = wezterm.config_builder()
-- config.CloseOnCleanExit = true

config.enable_wayland = true
config.enable_tab_bar = false
config.font = wezterm.font_with_fallback({
	{
		family = "IosevkaTerm Nerd Font",
		harfbuzz_features = { "liga=1", "calt=1", "ss02", "ss03", "ss19", "ss20" },
	},
	"Noto Color Emoji",
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
	left = 5,
	right = 5,
	top = 5,
	bottom = 5,
}
config.window_background_opacity = 0.79
-- config.dpi = 192
config.adjust_window_size_when_changing_font_size = false

-- Spawn a fish shell in login mode
config.default_prog = { "/bin/fish", "-l" }

-- if require("overrides") then
-- 	local overrides = require("overrides")
-- 	overrides.override(config)
-- end

return config
