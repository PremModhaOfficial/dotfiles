return {
	"tiagovla/tokyodark.nvim",
	opts = {
		transparent_background = true,
		gamma = 1.00,
		styles = {
			comments = { italic = true },
			keywords = { bold = true },
			identifiers = { bold = true },
			functions = { bold = true, italic = true },
			types = { italic = true },
			variables = {},
			strings = {},
		},
		custom_highlights = {} or function(highlights, palette)
			return {}
		end,
		custom_palette = {} or function(palette)
			return {}
		end,
		terminal_colors = true,
	},
	config = function(_, opts)
		require("tokyodark").setup(opts)
	end,
}
