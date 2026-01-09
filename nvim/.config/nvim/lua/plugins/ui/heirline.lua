return {
	{
		"rebelot/heirline.nvim",
		event = "VeryLazy",
		config = function()
			local statu_scolumn = require("plugins.ui.heirline.statuscolumn")
			local status_line = require("plugins.ui.heirline.statusline")
			require("heirline").setup({
				statusline = status_line,
				-- statuscolumn = statu_scolumn,
			})
		end,
	},
}

