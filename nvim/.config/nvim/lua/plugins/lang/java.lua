return {
	"mfussenegger/nvim-jdtls",
	event = { "BufReadPre *.java", "BufNewFile *.java" },
	dependencies = {
		"nvim-lua/plenary.nvim",
		"mfussenegger/nvim-dap",
		"mason-org/mason.nvim",
	},
	config = function()
		-- Force disable the generic jdtls config from nvim-lspconfig
		-- to prevent duplicate server instances
		vim.lsp.enable("jdtls", false)

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

		local extendedClientCapabilities = vim.tbl_deep_extend("force", require("jdtls").extendedClientCapabilities, {
			resolveAdditionalTextEditsSupport = true,
			progressReportProvider = false,
		})

		local config = {
			cmd = {
				"java",
				"-Declipse.application=org.eclipse.jdt.ls.core.id1",
				"-Dosgi.bundles.defaultStartLevel=4",
				"-Declipse.product=org.eclipse.jdt.ls.core.product",
				"-Dlog.protocol=true",
				"-Dlog.level=WARNING",
				"-Xms1g",
				"--add-modules=ALL-SYSTEM",
				"--add-opens",
				"java.base/java.util=ALL-UNNAMED",
				"--add-opens",
				"java.base/java.lang=ALL-UNNAMED",
				"-javaagent:" .. home .. "/.local/share/java/lombok.jar",
				"-jar",
				launcher_jar,
				"-configuration",
				jdtls_path .. "/config_linux",
				"-data",
				workspace_dir,
			},
			root_dir = require("jdtls.setup").find_root({ "pom.xml", "build.gradle", "mvnw", "gradlew", ".git" })
				or vim.fn.getcwd(),
			settings = {
				java = {
					import = {
						gradle = {
							enabled = true, -- IMPORT_GRADLE_ENABLED
							wrapper = {
								enabled = true, -- GRADLE_WRAPPER_ENABLED
							},
							offline = {
								enabled = false, -- IMPORT_GRADLE_OFFLINE_ENABLED
							},
						},
						maven = {
							enabled = true, -- IMPORT_MAVEN_ENABLED
							downloadSources = true, -- MAVEN_DOWNLOAD_SOURCES
							updateSnapshots = false, -- MAVEN_UPDATE_SNAPSHOTS
						},
						exclusions = { -- JAVA_IMPORT_EXCLUSIONS_KEY
							"**/node_modules/**",
							"**/.metadata/**",
							"**/archetype-resources/**",
							"**/META-INF/maven/**",
						},
					},
					configuration = {
						annotationProcessing = { enabled = true },
						runtimes = {
							{ name = "JavaSE-24", path = "/usr/lib/jvm/jdk-24.0.2-oracle-x64", default = true },
							{ name = "JavaSE-21", path = "/usr/lib/jvm/java-21-openjdk-amd64", default = false },
						},
						updateBuildConfiguration = "automatic",
					},
					format = { enabled = true, settings = { url = "~/javaFormatMotadata.xml" } },
					codeGeneration = {
						toString = {
							template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
						},
						useBlocks = true,
					},
					completion = {
						enabled = true, -- COMPLETION_ENABLED_KEY
						maxResults = 30, -- JAVA_COMPLETION_MAX_RESULTS_KEY
						overwrite = true, -- JAVA_COMPLETION_OVERWRITE_KEY
						guessMethodArguments = "insertParameterNames", -- JAVA_COMPLETION_GUESS_METHOD_ARGUMENTS_KEY
						postfix = {
							enabled = true, -- POSTFIX_COMPLETION_KEY
						},
						matchCase = "off", -- COMPLETION_MATCH_CASE_MODE_KEY
						lazyResolveTextEdit = {
							enabled = true, -- COMPLETION_LAZY_RESOLVE_TEXT_EDIT_ENABLED_KEY
						},
						chain = {
							enabled = true, -- Enable method chaining completion for fluent APIs
						},
						favoriteStaticMembers = {
							"org.assertj.core.api.Assertions.*",
							"org.junit.Assert.*",
							"org.junit.Assume.*",
							"org.junit.jupiter.api.Assertions.*",
							"org.junit.jupiter.api.Assumptions.*",
							"org.junit.jupiter.api.DynamicContainer.*",
							"org.junit.jupiter.api.DynamicTest.*",
							"org.mockito.Mockito.*",
							"org.mockito.ArgumentMatchers.*",
							"org.mockito.Answers.*",
							"java.util.stream.Collectors.*",
							"java.util.function.Function.*",
							"java.util.function.Predicate.*",
							"java.util.function.Consumer.*",
							"java.util.function.Supplier.*",
							"java.util.Optional.*",
							"java.util.stream.Stream.*",
							"java.util.Arrays.*",
							"java.util.List.*",
							"java.util.Map.*",
							"java.util.Set.*",
						},
						importOrder = {
							"#",
							"java",
							"javax",
							"java.util.function",
							"java.util.stream",
							"java.util",
							"org",
							"com",
						},
						signatureHelp = {
							enabled = true, -- SIGNATURE_HELP_ENABLED_KEY
							description = {
								enabled = true, -- SIGNATURE_HELP_DESCRIPTION_ENABLED_KEY
							},
						},
					},
					contentProvider = { preferred = "fernflower" },
					eclipse = {
						downloadSources = true,
					},
					flags = {
						allow_incremental_sync = true,
						-- TODO: SEE THE `SIDE E F F E C T S` -> SEEMS NOT TO EFFECT THE FUZZZ
						server_side_fuzzy_completion = true,
					},
					implementationsCodeLens = {
						enabled = true, --Don"t automatically show implementations
					},
					inlayHints = {
						parameterNames = { enabled = "all" },
					},
					maven = {
						downloadSources = true,
					},
					referencesCodeLens = {
						enabled = true, --Don"t automatically show references
					},
					references = {
						includeDecompiledSources = true,
					},
					saveActions = {
						organizeImports = true,
					},
					signatureHelp = { enabled = true },
					test = {
						enabled = true,
					},
					sources = {
						organizeImports = {
							starThreshold = 9999,
							staticStarThreshold = 9999,
						},
					},
				},
			},
			init_options = {
				extendedClientCapabilities = extendedClientCapabilities,
				bundles = bundles,
			},
			on_attach = function(client, bufnr)
				local java_runner = require("lib.java_runner")

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
				vim.keymap.set("i", "<M-v>", "var")
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
		-- Start or attach JDTLS with error handling
		local success, err = pcall(function()
			jdtls.start_or_attach(config)
		end)

		if not success then
			vim.notify("Failed to start JDTLS: " .. err, vim.log.levels.ERROR)
		end
	end,
}
