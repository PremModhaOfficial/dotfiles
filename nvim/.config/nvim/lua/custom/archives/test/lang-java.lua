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

		-- Build config
		local function get_jdtls_config()
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

			return {
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
						project = {
							referencedLibraries = {
								"/usr/lib/jvm/openjdk-21/lib/**/*.jar",
							},
						},
						import = {
							gradle = { enabled = true },
							maven = { enabled = true },
						},
						contentProvider = { preferred = "fernflower" }, -- enables decompiled view
						configuration = {
							runtimes = {
								{
									name = "JavaSE-21",
									path = "/usr/lib/jvm/openjdk-21",
									default = true,
								},
							},
						},
						sources = {
							attach = { "/usr/lib/jvm/openjdk-21/src.zip" },
						},
					},
				},
				init_options = {
					bundles = bundles,
					extendedClientCapabilities = jdtls.extendedClientCapabilities,
				},
				on_attach = function(client, bufnr)
					local java_runner = require("config.custom-java")

					-- Keymaps
					vim.keymap.set("n", "<F6>", java_runner.run_main_class_picker, {
						desc = "Run Java Main Class (Picker)",
						buffer = bufnr,
					})
					vim.keymap.set("n", "<F9>", java_runner.run_main_class_auto, {
						desc = "Run Java Main Class (Auto)",
						buffer = bufnr,
					})
					vim.keymap.set("n", "<leader>jf", java_runner.configure_runtime_flags, {
						desc = "Configure Java Runtime Flags",
						buffer = bufnr,
					})
					vim.keymap.set("n", "<F10>", java_runner.run_current_main, {
						desc = "Run current file's main()",
						buffer = bufnr,
					})

					-- Context-aware run main()
					local function is_main_method_context()
						local current_line = vim.api.nvim_get_current_line()
						local line_num = vim.api.nvim_win_get_cursor(0)[1]
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

					vim.keymap.set("n", "<leader>rm", function()
						if is_main_method_context() then
							java_runner.run_main_class_picker()
						else
							vim.notify("Place cursor on/near a main method to run", vim.log.levels.WARN)
						end
					end, { desc = "Run main() context-aware", buffer = bufnr })

					-- DAP integration
					require("jdtls").setup_dap({ hotcodereplace = "auto" })
					require("jdtls.dap").setup_dap_main_class_configs()
				end,
			}
		end

		-- Autocmd to attach for both Java + jdt:// buffers
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "java", "jdtls" },
			callback = function()
				jdtls.start_or_attach(get_jdtls_config())
			end,
		})
	end,
}
