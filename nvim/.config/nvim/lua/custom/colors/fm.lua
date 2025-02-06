return {
	"maxmx03/fluoromachine.nvim",
	lazy = false,
	-- enabled = false,
	priority = 1000,
	config = function()
		local fm = require("fluoromachine")

		fm.setup({
			theme = "retrowave",
			glow = false,
			transparent = true,
			brightness = 100.0,
			true_colors = true,
			styles = {
				comments = { italic = true },
				constants = { bold = true },
				functions = { bold = true, blend = 34 },
				keywords = { italic = true },
				numbers = {},
				parameters = {},
				types = {},
				variables = {},
			},
		})
	end,
	-- init = function() vim.cmd([[colorscheme fluoromachine]]) end,
}
