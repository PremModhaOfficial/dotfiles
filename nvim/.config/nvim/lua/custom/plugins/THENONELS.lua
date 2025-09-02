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
			-- nls.builtins.diagnostics.hadolint,
			-- nls.builtins.diagnostics.clippy,
			-- nls.builtins.code_actions.clippy,
			-- nls.builtins.formatting.stylua,
			-- nls.builtins.formatting.prettier,
			-- nls.builtins.formatting.black.with({ extra_args = { "--line-length", "80" }, }),
			-- nls.builtins.formatting.clang_format,
			nls.builtins.diagnostics.markdownlint_cli2,
			nls.builtins.code_actions.gomodifytags,
			nls.builtins.code_actions.impl,
			nls.builtins.formatting.goimports,
			nls.builtins.formatting.gofumpt,
		})
	end,
}
