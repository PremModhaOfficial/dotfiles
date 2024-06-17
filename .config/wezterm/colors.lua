-- I am helpers.lua and I should live in ~/.config/wezterm/helpers.lua

local wezterm = require("wezterm")

-- This is the module table that we will export
local module = {}

-- This function is private to this module and is not visible
	-- outside.
local function private_helper()
	wezterm.log_error("hello!")
	end

	-- define a function in the module table.
	-- Only functions defined in `module` will be exported to
	-- code that imports this module.
	-- The suggested convention for making modules that update
	-- the config is for them to export an `apply_to_config`
	-- function that accepts the config object, like this:
	function module.apply_to_config(config)
private_helper()

	config.colors = {
		-- Default colors
		foreground = "#A5A5B1",
		background = "#000000",

		-- Cursor colors
		cursor_bg = "#dcdfe4",
		cursor_fg = "#1e1e1e",

		-- ANSI colors
			ansi = {
			-----------------------------------------------------------
				"#53535F",
				"#1C1B6E",
				"#1E1D76",
				"#6A1A5E",
				"#651B6E",
				"#252187",
				"#721C53",
				"#777788",
			},

		-- Bright colors
			brights = {
			-----------------------------------------------------------
				"#041B23",
				"#191966",
				"#1C1B6E",
				"#661953",
				"#621A6A",
				"#231E7A",
				"#6E1B50",
				"#777788",
			},
	}
end

return module
