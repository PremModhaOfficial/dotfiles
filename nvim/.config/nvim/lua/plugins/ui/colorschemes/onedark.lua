return {
	{
		"navarasu/onedark.nvim",
		config = function()
			require("onedark").setup({
				style = "deep",
				transparent = true,
				term_colors = true,
				ending_tildes = true,
				cmp_itemkind_reverse = true,

				toggle_style_list = { "dark", "darker", "cool", "deep", "warm", "warmer", "light" },

				code_style = {
					comments = "italic",
					keywords = "italic",
					functions = "bold",
					strings = "none",
					variables = "none",
				},

				lualine = {
					transparent = true,
				},

				colors = {},
				highlights = {},

				diagnostics = {
					darker = true,
					undercurl = true,
					background = true,
				},
			})
		end,
	},
}
