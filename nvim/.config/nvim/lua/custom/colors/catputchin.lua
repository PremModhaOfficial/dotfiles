return {
	"catppuccin/nvim",
	name = "catppuccin",
	enabled = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "macchiato", -- latte, frappe, macchiato, mocha
			-- background = { -- :h background light = "latte", dark = "mocha", },
			transparent_background = true, -- disables setting the background color.
			show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
			term_colors = true, -- sets terminal colors (e.g. `g:terminal_color_0`)
			styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
				comments = { "italic" }, -- Change the style of comments
				conditionals = { "italic" },
				loops = { "italic" },
				functions = { "bold" },
				keywords = { "bold", "italic" },
				strings = {},
				variables = {},
				numbers = {},
				booleans = {},
				properties = {},
				types = {},
				operators = {},
				-- miscs = {}, -- Uncomment to turn off hard-coded styles
			},
		})

		-- setup must be called before loading
	end,
	-- init = function()
	-- 	if ColorSheme == "catppuccin" then
	-- 		vim.cmd([[colorscheme catppuccin]])
	-- 	end
	-- end,
}
