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
						env = {
							token = "GITHUB_TOKEN",
						},
						schema = {
							model = {
								default = "claude-3.5-sonnet",
								choices = {
									"claude-3.5-sonnet",
									"claude-3-haiku",
									"gpt-4o",
									"gpt-4",
									"gpt-3.5-turbo",
								},
							},
						},
					})
				end,
			},
		},
		extensions = {
			mcphub = {
				callback = "mcphub.extensions.codecompanion",
				opts = {
					-- MCP Tools 
					make_tools = true,              -- Make individual tools (@server__tool) and server groups (@server)
					show_server_tools_in_chat = true, -- Show individual tools in chat completion
					add_mcp_prefix_to_tool_names = false, -- Keep clean tool names
					show_result_in_chat = true,      -- Show tool results in chat buffer
					-- MCP Resources
					make_vars = true,                -- Convert MCP resources to #variables
					-- MCP Prompts 
					make_slash_commands = true,      -- Add MCP prompts as /slash commands
				}
			}
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
