-- ============================================================================
-- PLUGIN: LSP Configuration
-- PURPOSE: Language Server Protocol setup and management
-- DEPENDENCIES: mason, mason-lspconfig, mason-tool-installer, blink.cmp, neoconf
-- ============================================================================

return {
	"neovim/nvim-lspconfig",
	dependencies = {
		-- Automatically install LSPs and related tools to stdpath for Neovim
		{ "williamboman/mason.nvim", config = true }, -- NOTE: Must be loaded before dependants
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"saghen/blink.cmp",

		{
			"folke/neoconf.nvim",
			cmd = "Neoconf",
			opts = {},
		},
		-- Useful status updates for LSP.
		-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
		-- Artifact its GONE
		-- { "j-hui/fidget.nvim", opts = {} },

		-- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
		-- used for completion, annotations and signatures of Neovim apis
	},
	config = function()
		-- Brief aside: **What is LSP?**
		--
		-- LSP is an initialism you've probably heard, but might not understand what it is.
		--
		-- LSP stands for Language Server Protocol. It's a protocol that helps editors
		-- and language tooling communicate in a standardized fashion.
		--
		-- In general, you have a "server" which is some tool built to understand a particular
		-- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
		-- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
		-- processes that communicate with some "client" - in this case, Neovim!
		--
		-- LSP provides Neovim with features like:
		--  - Go to definition
		--  - Find references
		--  - Autocompletion
		--  - Symbol Search
		--  - and more!
		--
		-- Thus, Language Servers are external tools that must be installed separately from
		-- Neovim. This is where `mason` and related plugins come into play.
		--
		-- If you're wondering about lsp vs treesitter, you can check out the wonderfully
		-- and elegantly composed help section, `:help lsp-vs-treesitter`

		--  This function gets run when an LSP attaches to a particular buffer.
		--    That is to say, every time a new file is opened that is associated with
		--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
		--    function will be executed to configure the current buffer
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
			callback = function(event)
				-- NOTE: Remember that Lua is a real programming language, and as such it is possible
				-- to define small helper and utility functions so you don't have to repeat yourself.
				--
				-- In this case, we create a function that lets us more easily define mappings specific
				-- for LSP related items. It sets the mode, buffer and description for us each time.
				local map = function(keys, func, desc)
					vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end
				local xXmap = function(keys, func, desc, mode)
					vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end

				map("<leader>rN", function()
					vim.lsp.buf.rename()
				end, "[R]e[n]ame (project)")

				map("<leader>rn", function()
					vim.lsp.buf.rename()
				end, "[R]e[n]ame")

				map("<leader>p", function()
					Snacks.picker.lsp_definitions()
				end, "[P]eek definition")

				map("<leader>P", function()
					Snacks.picker.lsp_type_definitions()
				end, "[P]eek TYPE definition")

				-- Workspace diagnostics
				map("<leader>wd", function()
					Snacks.picker.diagnostics()
				end, "[W]orkspace [D]iagnostics")

				-- Call hierarchy
				map("<leader>ci", function()
					vim.lsp.buf.incoming_calls()
				end, "[C]all [I]ncoming")

				map("<leader>co", function()
					vim.lsp.buf.outgoing_calls()
				end, "[C]all [O]utgoing")

				-- Workspace Symbols (definitions, references, implementations)
				map("<leader>ws", function()
					Snacks.picker.lsp_symbols()
				end, "[W]orkspace [S]ymbols")
				-- Execute a code action, usually your cursor needs to be on top of an error
				-- or a suggestion from your LSP for this to activate.
				map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
				xXmap("<M-Enter>", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "v", "i" })

				-- Opens a popup that displays documentation about the word under your cursor
				--  See `:help K` for why this keymap.
				map("K", vim.lsp.buf.hover, "Hover Documentation")
				map("<c-s-k>", function()
					Snacks.picker.lsp_definitions()
				end, "Hover Definition")

				-- WARN: This is not Goto Definition, this is Goto Declaration.
				--  For example, in C this would take you to the header.
				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

				-- The following two autocommands are used to highlight references of the
				-- word under your cursor when your cursor rests there for a little while.
				--    See `:help CursorHold` for information about when this is executed
				--
				-- When you move your cursor, the highlights will be cleared (the second autocommand).
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if client and client.server_capabilities.documentHighlightProvider then
					local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.document_highlight,
					})

					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.clear_references,
					})

					vim.api.nvim_create_autocmd("LspDetach", {
						group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
						callback = function(event2)
							vim.lsp.buf.clear_references()
							vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
						end,
					})
				end
				--

				-- trigger codelens refresh
				vim.api.nvim_exec_autocmds("User", { pattern = "LspAttached" })

				-- The following autocommand is used to enable inlay hints in your
				-- code, if the language server you are using supports them
				--
				-- This may be unwanted, since they displace some of your code
				if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
					map("<leader>th", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
					end, "[T]oggle Inlay [H]ints")
				end

				-- Manual signature help keymap
				vim.keymap.set(
					"i",
					"<C-s>",
					vim.lsp.buf.signature_help,
					{ buffer = event.buf, desc = "LSP: Signature Help" }
				)
			end,
		})

		-- LSP servers and clients are able to communicate to each other what features they support.
		--  By default, Neovim doesn't support everything that is in the LSP specification.
		--  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
		--  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
		local capabilities = vim.lsp.protocol.make_client_capabilities()

		-- Add folding range capability for better folding support
		capabilities.textDocument.foldingRange = {
			dynamicRegistration = false,
			lineFoldingOnly = true,
		}

		-- Enable the following language servers
		--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
		--
		--  Add any additional override configuration in the following tables. Available keys are:
		--  - cmd (table): Override the default command used to start the server
		--  - filetypes (table): Override the default list of associated filetypes for the server
		--  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
		--  - settings (table): Override the default settings passed when initializing the server.
		--        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
		require("neoconf").setup({ -- override any of the default settings here
		})
		local servers = {
			jdtls = {
				root_markers = { ".git", "pom.xml", "build.gradle" },
			},
			sqls = {
				cmd = { "sqls", "-log-to-stderr" },
				filetypes = { "sql", "mysql", "plsql" },
				root_dir = function(fname)
					return vim.fs.root(fname, { ".git", "Makefile", "package.json" }) or vim.fn.getcwd()
				end,
			},
			pyright = {
				python = {
					analysis = {
						autoSearchPaths = true,
						diagnosticMode = "openFilesOnly",
						useLibraryCodeForTypes = true,
					},
				},
			},
			-- nil_ls = { cmd = { "nil", "--stdio" }, flake = { autoArchive = "true", }, },
			pylsp = {
				plugins = {
					pycodestyle = {
						ignore = { "W391" },
						maxLineLength = 100,
					},
					mypy = {
						enabled = true,
					},
					isort = {
						enabled = true,
					},
					flake8 = {
						enabled = true,
						executable = ".venv/bin/flake8",
					},
					black = {
						enabled = true,
						executable = vim.fn.stdpath("data") .. "/mason/bin/black",
					},
				},
			},
			-- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
			--
			-- Some languages (like typescript) have entire language plugins that can be useful:
			--    https://github.com/pmizio/typescript-tools.nvim
			--
			-- But for many setups, the LSP (`tsserver`) will work just fine
			-- tsserver = {},
			--

			-- TypeScript/JavaScript
			ts_ls = {
				settings = {
					typescript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayParameterNameHintsWhenArgumentMatchesName = false,
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = true,
						},
					},
					javascript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayParameterNameHintsWhenArgumentMatchesName = false,
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = true,
						},
					},
				},
			},
			-- Rust (though you have rustaceanvim, this provides fallback)
			rust_analyzer = {},
			-- C/C++
			clangd = {
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--header-insertion=iwyu",
					"--completion-style=detailed",
					"--function-arg-placeholders",
					"--fallback-style=llvm",
				},
				init_options = {
					usePlaceholders = true,
					completeUnimported = true,
					clangdFileStatus = true,
				},
			},
			-- Go
			gopls = {
				settings = {
					gopls = {
						gofumpt = true,
						codelenses = {
							gc_details = false,
							generate = true,
							regenerate_cgo = true,
							run_govulncheck = true,
							test = true,
							tidy = true,
							upgrade_dependency = true,
							vendor = true,
						},
						hints = {
							assignVariableTypes = true,
							compositeLiteralFields = true,
							compositeLiteralTypes = true,
							constantValues = true,
							functionTypeParameters = true,
							parameterNames = true,
							rangeVariableTypes = true,
						},
						analyses = {
							nilness = true,
							unusedparams = true,
							unusedwrite = true,
							useany = true,
						},
						usePlaceholders = true,
						completeUnimported = true,
						staticcheck = true,
						directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
						semanticTokens = true,
					},
				},
			},
			-- Additional useful servers
			marksman = {
				filetypes = { "markdown" },  -- Only attach to markdown files
				root_dir = function(fname)
					if type(fname) ~= "string" then return vim.fn.getcwd() end
					local util = require("lspconfig.util")
					return util.find_git_ancestor(fname) or util.path.dirname(fname) or vim.fn.getcwd()
				end,
				settings = {
					marksman = {
						core = {
							title_from_heading = true,  -- Treat # headings as titles
						},
						completion = {
							wiki = {
								style = "title-slug",  -- Preferred for Obsidian wiki links
							},
						},
					},
				},
			},
		}

		-- Workaround for gopls semantic tokens issue
		-- https://github.com/golang/go/issues/54531#issuecomment-1464982242
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("gopls-semantic-tokens-workaround", { clear = true }),
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if client and client.name == "gopls" then
					if not client.server_capabilities.semanticTokensProvider then
						local semantic = client.config.capabilities.textDocument.semanticTokens
						if semantic then
							client.server_capabilities.semanticTokensProvider = {
								full = true,
								legend = {
									tokenTypes = semantic.tokenTypes,
									tokenModifiers = semantic.tokenModifiers,
								},
								range = true,
							}
						end
					end
				end
			end,
		})

		for server, config in pairs(servers) do
			-- passing config.capabilities to blink.cmp merges with the capabilities in your
			-- `opts[server].capabilities, if you've defined it
			config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)

			-- Add error handling for LSP setup
			local success, err = pcall(function()
				vim.lsp.config(server, config)
				vim.lsp.enable(server, true)
			end)

			if not success then
				vim.notify("Failed to setup LSP server '" .. server .. "': " .. err, vim.log.levels.ERROR)
			end
		end

		-- Ensure the servers and tools above are installed
		--  To check the current status of installed tools and/or manually install
		--  other tools, you can run
		--    :Mason
		--
		--  You can press `g?` for help in this menu.

		local v = {
			cmd = { "vectorcode-server" },
			root_dir = vim.fs.root(0, { ".vectorcode", ".git" }),
			settings = {},
		}
		-- vim.lsp.enable("VectorCode")
		vim.lsp.config("VectorCode", v)

		vim.lsp.config("nixd", {
			cmd = { "nixd" },
			filetypes = { "nix" },
			settings = {
				nixd = {
					nixpkgs = {
						expr = "import <nixpkgs> { }",
					},
					formatting = {
						command = { "nixpkgs-fmt" },
					},
					options = {
						home_manager = {
							expr = '(builtins.getFlake "~/.config/nixpkgs/").homeConfigurations."prm".options',
						},
					},
				},
			},
		})
		require("mason").setup()
		-- You can add other tools here that you want Mason to install
		-- for you, so that they are available from within Neovim.
		local ensure_installed = vim.tbl_keys(servers or {})
		vim.list_extend(ensure_installed, {
			"lua_ls", -- Lua LSP server
			"stylua", -- Used to format Lua code
			"prettier", -- Code formatter
			"eslint_d", -- Fast ESLint
			"shellcheck", -- Shell script linting
			"shfmt", -- Shell script formatting
			-- Go development tools
			"goimports", -- Go import management
			"gofumpt", -- Stricter Go formatting
			"gomodifytags", -- Go struct tag generator
			"impl", -- Go interface implementation generator
			"golangci-lint", -- Go linter
			"delve", -- Go debugger
		})
		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

		require("mason-lspconfig").setup({
			automatic_installation = false,
			handlers = {
				function(server_name)
					local server = servers[server_name] or {}
					-- This handles overriding only values explicitly passed
					-- by the server configuration above. Useful when disabling
					-- certain features of an LSP (for example, turning off formatting for tsserver)
					server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
					-- require("lspconfig")[server_name].setup(server)
					vim.lsp.config(server_name, server)
				end,
			},
		})
	end,
}
