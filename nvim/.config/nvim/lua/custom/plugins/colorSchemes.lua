ColorScheme = "fluoromachine"
return {
	{
		"scottmckendry/cyberdream.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd([[ set background=dark ]])
			require("cyberdream").setup({
				-- Enable transparent background
				transparent = true,
				-- Enable italics comments
				italic_comments = true,
				-- Replace all fillchars with ' ' for the ultimate clean look
				hide_fillchars = true,
				-- Modern borderless telescope theme - also applies to fzf-lua
				borderless_telescope = false,
				-- Set terminal colors used in `:terminal`
				terminal_colors = true,
				-- Use caching to improve performance - WARNING: experimental feature - expect the unexpected!
				-- Early testing shows a 60-70% improvement in startup time. YMMV. Disables dynamic light/dark theme switching.
				cache = true, -- generate cache with :CyberdreamBuildCache and clear with :CyberdreamClearCache
				theme = {
					variant = "auto", -- use "light" for the light variant. Also accepts "auto" to set dark or light colors based on the current value of `vim.o.background`
					highlights = {
						-- Highlight groups to override, adding new groups is also possible
						-- See `:h highlight-groups` for a list of highlight groups or run `:hi` to see all groups and their current values
						-- Example:
						Comment = { fg = "#696969", bg = "NONE", italic = true },
						-- Complete list can be found in `lua/cyberdream/theme.lua`
					},
					-- Override a highlight group entirely using the color palette
					-- overrides = function(colors) -- NOTE: This function nullifies the `highlights` option
					--     -- Example:
					--     return {
					--         Comment = { fg = colors.green, bg = "NONE", italic = true },
					--         ["@property"] = { fg = colors.magenta, bold = true },
					--     }
					-- end,
					-- Override a color entirely
					-- 	colors = { -- For a list of colors see `lua/cyberdream/colours.lua` Example: bg = "#000000", green = "#00ff00", magenta = "#ff00ff", },
				},
			})
		end,
		init = function()
			if ColorScheme == "cyberdream" then
				vim.cmd([[
				colorscheme cyberdream
				CyberdreamBuildCache
				]])
			end
		end,
	},
	{
		"maxmx03/fluoromachine.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			local fm = require("fluoromachine")

			fm.setup({
				glow = false,
				theme = "retrowave",
				transparent = true,
				brightness = 0.05,
				true_colors = true,
			})
		end,
		init = function()
			if ColorScheme == "fluoromachine" then
				vim.cmd([[colorscheme fluoromachine]])
			end
		end,
	},
	{
		"tiagovla/tokyodark.nvim",
		opts = {
			transparent_background = true, -- set background to transparent
			gamma = 1.00, -- adjust the brightness of the theme
			styles = {
				comments = { italic = true }, -- style for comments
				keywords = { italic = true }, -- style for keywords
				identifiers = { italic = true }, -- style for identifiers
				functions = { bold = true }, -- style for functions
				variables = {}, -- style for variables
				strings = { italic = true }, -- style for strings
				-- folds = { bold = true, italic = true }, -- style for folds
			},
			---@diagnostic disable-next-line: unused-local
			custom_highlights = {} or function(highlights, palette)
				return {}
			end, -- extend highlights
			---@diagnostic disable-next-line: unused-local
			custom_palette = {} or function(palette)
				return {}
			end, -- extend palette
			terminal_colors = true, -- enable terminal colors
		},
		config = function(_, opts)
			require("tokyodark").setup(opts) -- calling setup is optional
		end,
		init = function()
			if ColorScheme == "tokyodark" then
				vim.cmd([[colorscheme tokyodark]])
			end
		end,
	},
	{ -- You can easily change to a different colorscheme.
		-- Change the name of the colorscheme plugin below, and then
		-- change the command in the config to whatever the name of that colorscheme is.
		--
		-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
		"folke/tokyonight.nvim",
		priority = 1000, -- Make sure to load this before all the other start plugins.
		config = function()
			require("tokyonight").setup()
		end,
		init = function()
			if ColorScheme == "tokyonight" then
				-- Load the colorscheme here.
				-- Like many other themes, this one has different styles, and you could load
				-- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
				vim.cmd.colorscheme("tokyonight-night")

				-- You can configure highlights by doing something like:
				vim.cmd.hi("Comment gui=none")
			end
		end,
	},

	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		config = function()
			require("gruvbox").setup({
				terminal_colors = true, -- add neovim terminal colors
				undercurl = true,
				underline = true,
				bold = true,
				italic = {
					strings = true,
					emphasis = true,
					comments = true,
					operators = false,
					folds = true,
				},
				strikethrough = true,
				invert_selection = false,
				invert_signs = false,
				invert_tabline = true,
				invert_intend_guides = false,
				inverse = false, -- invert background for search, diffs, statuslines and errors
				contrast = "hard", -- can be "hard", "soft" or empty string
				palette_overrides = {},
				overrides = {},
				dim_inactive = false,
				transparent_mode = true,
			})
		end,
		init = function()
			if ColorScheme == "gruvbox" then
				vim.cmd([[colorscheme gruvbox]])
				vim.cmd.hi("Comment gui=none")
			end
		end,
	},
}
