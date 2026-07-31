return {
	"folke/tokyonight.nvim",
	enabled = false,
	priority = 1000,
	opts = {
		transparent = true,
		style = "night",
		cache = false,
	},
	init = function()
		vim.cmd.colorscheme("tokyonight-night")
	end,
}
