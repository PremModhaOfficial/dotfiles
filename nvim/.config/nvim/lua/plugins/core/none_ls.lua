return {
	"nvimtools/none-ls.nvim",
	opts = function(_, opts)
		local nls = require("null-ls")
		local sources = {
			nls.builtins.code_actions.gomodifytags,
			nls.builtins.code_actions.impl,
		}
		if vim.g.markdown_enabled then
			table.insert(sources, 1, nls.builtins.diagnostics.markdownlint_cli2)
		end
		opts.sources = vim.list_extend(opts.sources or {}, sources)
	end,
}
