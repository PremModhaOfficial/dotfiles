return {
	"maxmx03/fluoromachine.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		local fm = require("fluoromachine")

		fm.setup({
			theme = "fluoromachine",
			glow = false,
			transparent = true,
			brightness = 100.0,
			true_colors = true,
			styles = {
				functions = { bold = true },
				comments = { italic = true },
				keywords = { italic = true },
				strings = { italic = true },
				constants = { bold = true },
				variables = {},
				fields = {},
				parameters = {},
			},
		})
	end,
	init = function()
		vim.cmd([[colorscheme fluoromachine]])
	end,
}
