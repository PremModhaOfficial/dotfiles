return {
	"mfussenegger/nvim-jdtls",
	ft = { "java", "jdtls" },
	dependencies = {
		"nvim-lua/plenary.nvim",
		"mfussenegger/nvim-dap",
		"williamboman/mason.nvim",
	},
	config = function()
		local jdtls = require("jdtls")
		local home = os.getenv("HOME")
		local jdtls_path = home .. "/.local/share/nvim/mason/packages/jdtls"
		local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
		local workspace_dir = home .. "/.cache/jdtls/" .. project_name
		vim.fn.mkdir(workspace_dir, "p")
		local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
		local bundles = vim.fn.glob(
			home
				.. "/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
			true,
			true
		)
		local config = {
			cmd = {
				"java",
				"-Declipse.application=org.eclipse.jdt.ls.core.id1",
				"-Dosgi.bundles.defaultStartLevel=4",
				"-Declipse.product=org.eclipse.jdt.ls.core.product",
				"-Dlog.protocol=true",
				"-Dlog.level=ALL",
				"-Xms1g",
				"--add-modules=ALL-SYSTEM",
				"--add-opens",
				"java.base/java.util=ALL-UNNAMED",
				"--add-opens",
				"java.base/java.lang=ALL-UNNAMED",
				"-jar",
				launcher_jar,
				"-configuration",
				jdtls_path .. "/config_linux",
				"-data",
				workspace_dir,
			},
			root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),
			settings = {
				java = {
					configuration = {
						runtimes = {
							{
								name = "JavaSE-21",
								path = "/usr/lib/jvm/openjdk-21",
								default = true,
							},
						},
					},
					-- sources = { attach = { "/usr/lib/jvm/openjdk-21/src.zip" }, },
					format = {
						enabled = true,
						settings = {
							url = "~/javaFormatMotadata.xml",
						},
					},
				},
			},
			init_options = {
				bundles = bundles,
			},
			on_attach = function(client, bufnr)
				local java_runner = require("config.custom-java")

				-- Enhanced picker with runtime flags configuration
				vim.keymap.set("n", "<F6>", java_runner.run_main_class_picker, {
					desc = "Run Java Main Class (Enhanced Picker with Flags)",
					buffer = bufnr,
				})

				-- NEW: Original auto-run behavior (F6 -> F9)
				vim.keymap.set("n", "<F9>", java_runner.run_main_class_auto, {
					desc = "Run Java Main Class (Auto-run if single, else pick)",
					buffer = bufnr,
				})

				-- Configure runtime flags
				vim.keymap.set("n", "<leader>jf", java_runner.configure_runtime_flags, {
					desc = "Configure Java Runtime Flags",
					buffer = bufnr,
				})

				-- Quick run current file's main method directly
				vim.keymap.set("n", "<F10>", java_runner.run_current_main, {
					desc = "Run current file's main method",
					buffer = bufnr,
				})

				-- Helper function to detect main method context
				local function is_main_method_context()
					local current_line = vim.api.nvim_get_current_line()
					local line_num = vim.api.nvim_win_get_cursor(0)[1]

					-- Check current line and a few lines around it
					for i = math.max(1, line_num - 2), math.min(vim.api.nvim_buf_line_count(0), line_num + 2) do
						local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""
						if
							line:match("public%s+static%s+void%s+main")
							or line:match("static%s+public%s+void%s+main")
						then
							return true
						end
					end
					return false
				end

				-- Store original code action handler
				local original_code_action_handler = vim.lsp.handlers["textDocument/codeAction"]

				-- Enhanced code action handler that doesn't rely on LSP commands
				vim.lsp.handlers["textDocument/codeAction"] = function(err, result, ctx, config)
					if err then
						return original_code_action_handler(err, result, ctx, config)
					end

					result = result or {}

					-- Add "Run main()" action if we're in main method context
					if is_main_method_context() then
						table.insert(result, 1, { -- Insert at beginning for prominence
							title = "▶ Run main()",
							kind = "source.organizeImports", -- Use a kind that shows prominently
							command = {
								title = "Run main()",
								command = "java.run.main.current",
								arguments = { vim.uri_from_bufnr(0) },
							},
						})
					end

					return original_code_action_handler(err, result, ctx, config)
				end

				-- Handle the custom command without relying on LSP
				vim.lsp.commands = vim.lsp.commands or {}
				vim.lsp.commands["java.run.main.current"] = function(command, ctx)
					java_runner.run_main_class_picker()
				end

				-- Context-aware keymap for quick access
				vim.keymap.set("n", "<leader>rm", function()
					if is_main_method_context() then
						java_runner.run_main_class_picker()
					else
						vim.notify("Place cursor on or near a main method to run", vim.log.levels.WARN)
					end
				end, {
					desc = "Run main() method (context-aware)",
					buffer = bufnr,
				})

				-- Standard jdtls setup
				require("jdtls").setup_dap({ hotcodereplace = "auto" })
				require("jdtls.dap").setup_dap_main_class_configs()
			end,
		}
		jdtls.start_or_attach(config)
	end,
}
