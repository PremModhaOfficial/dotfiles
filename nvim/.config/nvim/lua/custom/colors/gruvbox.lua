return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	-- enabled = false,
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
			invert_intend_guides = true,
			inverse = true, -- invert background for search, diffs, statuslines and errors
			contrast = "hard", -- can be "hard", "soft" or empty string
			palette_overrides = {},
			overrides = {},
			dim_inactive = true,
			transparent_mode = true,
		})
	end,
	init = function()
		vim.cmd([[colorscheme gruvbox]])
		-- vim.cmd.hi("Comment gui=none")
	end,
}
