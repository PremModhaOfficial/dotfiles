local wezterm = require("wezterm")
-- disable tabs
local config = wezterm.config_builder()
-- config.CloseOnCleanExit = true
-- apply colors

config.enable_wayland = true
config.enable_tab_bar = false
config.warn_about_missing_glyphs = false -- Disable glyph warnings
-- config.harfbuzz_features = { "zero", "ss01", "cv05", "calt", "clig", "liga" }
config.allow_square_glyphs_to_overflow_width = "Never" -- Prevent rendering issues
config.check_for_updates = false -- Disable update checks
config.use_ime = false -- Disable input method editor if not needed
config.pane_focus_follows_mouse = false -- Disable focus tracking
config.swap_backspace_and_delete = false -- Disable key swapping

-- Enhanced undercurl support
config.custom_block_glyphs = true
config.underline_position = -4 -- Position undercurls lower for better visibility
-- config.underline_thickness = "200%" -- Make underlines thicker and more visible
config.term = "wezterm" -- Use WezTerm's terminal type for better escape sequence handling

-- Advanced undercurl rendering options
config.cursor_thickness = 1 -- Thinner cursor for less visual distraction

-- GPU optimizations for smooth rendering
config.max_fps = 60 -- Allow higher refresh rates if available
config.enable_kitty_graphics = true -- Enable kitty graphics protocol for better image rendering
config.use_resize_increments = true -- Smoother resize experience

-- fs
config.font = wezterm.font_with_fallback({
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
config.font_size = 10
config.window_padding = {
	left = 2,
	right = 1,
	top = 1,
	bottom = 1,
}
config.window_background_opacity = 0.49
config.adjust_window_size_when_changing_font_size = false

-- Enhanced color support
config.color_scheme_dirs = { os.getenv("HOME") .. "/.config/wezterm/colors" }
config.bold_brightens_ansi_colors = true -- Improve color distinction for bold text

-- Improved rendering features
config.allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace" -- Better emoji rendering
config.freetype_load_target = "Light" -- Optimized font rendering
-- config.freetype_render_target = "HorizontalLcd" -- Improve text clarity

-- Spawn a fish shell in login mode
config.default_prog = { "/bin/fish", "-l" }

-- if require("overrides") then
-- 	local overrides = require("overrides")
-- 	overrides.override(config)
-- end

return config
