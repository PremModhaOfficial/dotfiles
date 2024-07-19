return {
	"mbbill/undotree",
	-- undotree = require("undotree"),
	config = function()
		vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
		vim.g.undotree_WindowLayout = 2
		vim.g.undotree_SetFocusWhenToggle = 1
	end,
}
