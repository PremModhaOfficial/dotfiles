return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	enabled = false,
	config = function()
		require("gruvbox").setup({
			terminal_colors = true,
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
			invert_selection = true,
			invert_signs = false,
			invert_tabline = true,
			invert_intend_guides = true,
			inverse = false,
			contrast = "soft",
			palette_overrides = {},
			overrides = {},
			dim_inactive = false,
			transparent_mode = true,
		})
	end,
}
