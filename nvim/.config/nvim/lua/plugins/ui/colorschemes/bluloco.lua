return {
	"uloco/bluloco.nvim",
	lazy = false,
	priority = 1000,
	dependencies = { "rktjmp/lush.nvim" },
	config = function()
		require("bluloco").setup({
			style = "dark",
			transparent = true,
			italics = true,
			terminal = vim.fn.has("gui_running") == 1,
			guicursor = true,
		})

		vim.opt.termguicolors = true
	end,
}
