return {
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
	-- init = function()
	-- 	if ColorSheme == "gruvbox" then
	-- 		vim.cmd([[colorscheme gruvbox]])
	-- 		vim.cmd.hi("Comment gui=none")
	-- 	end
	-- end,
}
