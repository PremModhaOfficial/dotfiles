return {
	"olimorris/codecompanion.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		-- { "nvim-telescope/telescope.nvim", cmd = "Telescope" },
		{ "echasnovski/mini.diff" },
		-- "Saghen/blink.cmp", -- Ensure blink.cmp is listed here
		-- "j-hui/fidget.nvim",
	},
	config = true,
	---@module "codecompanion"
	opts = {
		log_level = "TRACE",
		send_code = true,
		display = {
			diff = {
				enabled = true, -- Enable or disable diff functionality
				close_chat_at = 240, -- Close an open chat buffer if the total columns of your display are less than...
				layout = "vertical", -- Controls split direction: vertical|horizontal split for default provider
				opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" }, -- Diff display options and algorithms
				provider = "mini_diff", -- Which diff provider to use: default|mini_diff
			},
		},
		strategies = {
			chat = {
				adapter = "copilot",
				picker = "snacks", -- Specify telescope explicitly for `/file` picker

				diff = {
					provider = "mini_diff",
				},
			},
			inline = {
				adapter = "copilot",
			},
			agent = {
				adapter = "copilot",
			},
		},
		adapters = {
			http = {
				copilot = function()
					return require("codecompanion.adapters").extend("copilot", {
						schema = {
							model = {
								default = "grok-code-fast-1",
							},
						},
					})
				end,
			},
		},
		extensions = {
			vectorcode = {
				---@type VectorCode.CodeCompanion.ExtensionOpts
				opts = {
					tool_group = {
						-- this will register a tool group called `@vectorcode_toolbox` that contains all 3 tools
						enabled = true,
						-- a list of extra tools that you want to include in `@vectorcode_toolbox`.
						-- if you use @vectorcode_vectorise, it'll be very handy to include
						-- `file_search` here.
						extras = {},
						collapse = false, -- whether the individual tools should be shown in the chat
					},
					tool_opts = {
						-- ---@type VectorCode.CodeCompanion.ToolOpts
						-- ["*"] = {},
						---@type VectorCode.CodeCompanion.LsToolOpts
						ls = {},
						---@type VectorCode.CodeCompanion.VectoriseToolOpts
						vectorise = {},
						---@type VectorCode.CodeCompanion.QueryToolOpts
						query = {
							max_num = { chunk = -1, document = -1 },
							default_num = { chunk = 50, document = 10 },
							include_stderr = false,
							use_lsp = true,
							no_duplicate = true,
							chunk_mode = false,
							---@type VectorCode.CodeCompanion.SummariseOpts
							summarise = {
								---@type boolean|(fun(chat: CodeCompanion.Chat, results: VectorCode.QueryResult[]):boolean)|nil
								enabled = false,
								adapter = nil,
								query_augmented = true,
							},
						},
						files_ls = {},
						files_rm = {},
					},
					prompt_library = {},
				},
			},
			mcphub = {
				callback = "mcphub.extensions.codecompanion",
				opts = {
					-- MCP Tools
					make_tools = true, -- Make individual tools (@server__tool) and server groups (@server)
					show_server_tools_in_chat = true, -- Show individual tools in chat completion
					add_mcp_prefix_to_tool_names = true, -- Keep clean tool names
					show_result_in_chat = true, -- Show tool results in chat buffer
					-- MCP Resources
					make_vars = true, -- Convert MCP resources to #variables
					-- MCP Prompts
					make_slash_commands = true, -- Add MCP prompts as /slash commands
				},
			},
		},
	},
	init = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "codecompanion",
			callback = function()
				require("blink.cmp").setup({
					sources = {
						default = { "lsp", "path", "snippets", "buffer" },
					},
				})
			end,
		})
	end,
}
