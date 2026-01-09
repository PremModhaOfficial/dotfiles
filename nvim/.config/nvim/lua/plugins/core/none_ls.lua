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
		local goconst = nls.builtins.diagnostics.golangci_lint.with({
			command = "goconst",
			args = { "./..." },
			to_stdin = false,
			from_stderr = false,
			format = "line",
			check_exit_code = function(code)
				return code <= 1
			end,
			on_output = function(line, params)
				local pattern = "(.+):(%d+):(.+)"
				local file, lnum, msg = line:match(pattern)
				if file and lnum and msg then
					return {
						row = tonumber(lnum),
						col = 1,
						message = msg,
						severity = 2,
						source = "goconst",
					}
				end
			end,
		})
		opts.sources = vim.list_extend(opts.sources or {}, {
			-- nls.builtins.diagnostics.hadolint,
			-- nls.builtins.diagnostics.clippy,
			-- nls.builtins.code_actions.clippy,
			-- nls.builtins.formatting.stylua,
			-- nls.builtins.formatting.prettier,
			-- nls.builtins.formatting.black.with({ extra_args = { "--line-length", "80" }, }),
			-- nls.builtins.formatting.clang_format,
			nls.builtins.diagnostics.markdownlint_cli2,
			-- Go language support
			nls.builtins.code_actions.gomodifytags,
			nls.builtins.code_actions.impl,
			nls.builtins.formatting.goimports,
			nls.builtins.formatting.gofumpt,
			nls.builtins.diagnostics.golangci_lint,
			goconst,
		})
	end,
}
