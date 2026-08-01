return {
	"maxmx03/fluoromachine.nvim",
	lazy = true,
	enabled = true,
	priority = 1000,
	config = function()
		local fluoromachine = require("fluoromachine")

		fluoromachine.setup({
			theme = "delta",
			glow = false,
			transparent = true,
			brightness = 0,
			true_colors = true,
			styles = {
				comments = { italic = true },
				constants = { bold = true },
				functions = { bold = true },
				keywords = { bold = true },
				types = { italic = true },
			},
		})
	end,
}
