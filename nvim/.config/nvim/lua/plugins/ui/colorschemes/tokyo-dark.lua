return {
	"tiagovla/tokyodark.nvim",
	enabled = false,
	---@module "tokyodark"
	opts = {
		transparent_background = true, -- set background to transparent
		gamma = 1.00, -- adjust the brightness of the theme
		styles = {
			comments = { italic = true }, -- style for comments
			keywords = { bold = true }, -- style for keywords
			identifiers = { bold = true }, -- style for identifiers
			functions = { bold = true, italic = true }, -- style for functions
			variables = {}, -- style for variables
			strings = {}, -- style for strings
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
	-- init = function() vim.cmd([[colorscheme tokyodark]]) end,
}
