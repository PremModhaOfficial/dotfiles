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
				adapter = "openrouter",
				picker = "snacks", -- Specify telescope explicitly for `/file` picker

				diff = {
					provider = "mini_diff",
				},
			},
			inline = {
				adapter = "openrouter",
			},
			agent = {
				adapter = "openrouter",
			},
		},
		adapters = {
			http = {
				openrouter = function()
					return require("codecompanion.adapters").extend("openai", {
						env = {
							api_key = "OPENROUTER_API_KEY",
						},
						url = "https://openrouter.ai/api/v1",
						schema = {
							model = {
								default = "qwen/qwen3-coder:free",
							},
						},
					})
				end,
			},
		},
	},
	init = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "codecompanion",
			callback = function()
				require("blink.cmp").setup.buffer({
					sources = {
						default = { "lsp", "path", "snippets", "buffer" },
					},
				})
			end,
		})
	end,
}
