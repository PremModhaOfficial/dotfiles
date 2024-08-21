return {
	{
		"tiagovla/tokyodark.nvim",
		opts = {
			transparent_background = true, -- set background to transparent
			gamma = 1.00, -- adjust the brightness of the theme
			styles = {
				comments = { italic = true }, -- style for comments
				keywords = { italic = true }, -- style for keywords
				identifiers = { italic = true }, -- style for identifiers
				functions = {}, -- style for functions
				variables = {}, -- style for variables
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
			vim.cmd([[colorscheme tokyodark]])
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
		-- init = function()
		-- 	-- Load the colorscheme here.
		-- 	-- Like many other themes, this one has different styles, and you could load
		-- 	-- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
		-- 	vim.cmd.colorscheme("tokyonight-night")
		--
		-- 	-- You can configure highlights by doing something like:
		-- 	vim.cmd.hi("Comment gui=none")
		-- end,
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
		-- init = function() vim.cmd.colorscheme("gruvbox") -- vim.cmd.hi("Comment gui=none") end,
	},
}
