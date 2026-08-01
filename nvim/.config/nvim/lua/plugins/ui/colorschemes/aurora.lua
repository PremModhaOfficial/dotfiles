return {
	"ray-x/aurora",
	config = function()
		vim.cmd.colorscheme("aurora")
		vim.api.nvim_set_hl(0, "@number", { fg = "#e933e3" })
	end,
}
