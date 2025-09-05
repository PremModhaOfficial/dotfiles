return {
	{
		"rebelot/heirline.nvim",
		event = "VeryLazy",
		config = function()
			local statu_scolumn = require("custom.heirline.statuscolumn")
			local status_line = require("custom.heirline.statusline")
			require("heirline").setup({
				statusline = status_line,
				statuscolumn = statu_scolumn,
			})
		end,
	},
}