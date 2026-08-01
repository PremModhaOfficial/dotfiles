return {
	"eldritch-theme/eldritch.nvim",
	lazy = false,
	priority = 1000,

	config = function()
		require("eldritch").setup({
			transparent = true,
			terminal_colors = true,
			styles = {
				comments = { italic = true },
				keywords = { italic = true },
				functions = { bold = true },
				variables = {},
				sidebars = "transparent",
				floats = "transparent",
			},
			sidebars = { "qf", "help" },
			hide_inactive_statusline = true,
			dim_inactive = false,
			lualine_bold = true,
			heirline_bold = true,

			on_colors = function(colors) end,

			on_highlights = function(highlights, colors) end,
		})
	end,
}
