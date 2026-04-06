return {
	"maxmx03/fluoromachine.nvim",
	---@module "fluoromachine"
	lazy = true,
	enabled = true,
	priority = 1000,
	config = function()
		local fluoromachine = require("fluoromachine")

		fluoromachine.setup({

			---@type fm.config.theme
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
				-- numbers = {},
				-- parameters = {},
				-- types = {},
				types = { italic = true }, --  NOTE: NICE LOOKING
				-- variables = {},
			},
		})
	end,
	-- init = function() vim.cmd([[colorscheme fluoromachine]]) end,
}
