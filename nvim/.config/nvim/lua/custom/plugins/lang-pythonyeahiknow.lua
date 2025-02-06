return {
	"HallerPatrick/py_lsp.nvim",
	config = function()
		require("py_lsp").setup({
			-- This is optional, but allows to create virtual envs from nvim
			host_python = "/usr/bin/python",
			default_venv_name = "env", -- For local venv
		})
	end,
}
