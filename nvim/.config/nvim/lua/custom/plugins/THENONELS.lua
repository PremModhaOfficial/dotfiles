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
	opts = function(_, opts)
		local nls = require("null-ls")
		opts.sources = vim.list_extend(opts.sources or {}, {
			nls.builtins.diagnostics.hadolint,
			nls.builtins.formatting.stylua,
			nls.builtins.formatting.prettier,
			-- nls.builtins.formatting.black.with({ extra_args = { "--line-length", "80" }, }),
		})
	end,
}
