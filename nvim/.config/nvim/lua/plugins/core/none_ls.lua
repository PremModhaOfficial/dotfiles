return {
	"nvimtools/none-ls.nvim",
	opts = function(_, opts)
		local nls = require("null-ls")
		local helpers = require("null-ls.helpers")
		local goconst = {
			name = "goconst",
			method = nls.methods.DIAGNOSTICS,
			filetypes = { "go" },
			generator = nls.generator({
				command = "goconst",
				args = { "./..." },
				to_stdin = false,
				from_stderr = false,
				format = "line",
				check_exit_code = function(code)
					return code <= 1
				end,
				on_output = helpers.diagnostics.from_patterns({
					{
						pattern = [[([^:]+):(%d+):(%d+):%s*(.*)]],
						groups = { "filename", "row", "col", "message" },
						overrides = {
							diagnostic = {
								severity = vim.diagnostic.severity.WARN,
								source = "goconst",
							},
						},
					},
					{
						pattern = [[([^:]+):(%d+):%s*(.*)]],
						groups = { "filename", "row", "message" },
						overrides = {
							diagnostic = {
								col = 1,
								severity = vim.diagnostic.severity.WARN,
								source = "goconst",
							},
						},
					},
				}),
			}),
		}
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
