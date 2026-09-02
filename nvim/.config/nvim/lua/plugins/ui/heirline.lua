return {
	{
		"rebelot/heirline.nvim",
		event = "VeryLazy",
		config = function()
			local status_line = require("plugins.ui.heirline.statusline")
			require("heirline").setup({
				statusline = status_line,
			})
		end,
	},
}

