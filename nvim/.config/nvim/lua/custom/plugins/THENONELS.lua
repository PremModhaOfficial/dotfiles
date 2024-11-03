return {
	"nvimtools/none-ls.nvim",
	keys = {
		{
			"<leader>lf",
			vim.lsp.buf.format,
			mode = "",
			desc = "[L]sp [F]ormat buffer",
		},
	},
	config = function()
		local null_ls = require("null-ls")
		null_ls.setup({
			debug = true,
			source = {
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.prettier,
				null_ls.builtins.formatting.black.with({
					extra_args = { "--line-length", "80" },
				}),
			},
		})
		-- vim.keymap.set(
		-- 	"n",
		-- 	"<leader>lf",
		-- 	vim.lsp.buf.format,
		-- 	{ noremap = true, silent = true, desc = "Format current buffer with lsp" }
		-- )
	end,
	-- Your configuration comes here
}
