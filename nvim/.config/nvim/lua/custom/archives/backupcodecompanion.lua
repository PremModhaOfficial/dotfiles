return {
	"olimorris/codecompanion.nvim",
	event = "VeryLazy",
	-- enabled = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		-- { "nvim-telescope/telescope.nvim", cmd = "Telescope" },
		{ "echasnovski/mini.diff" },
		-- "Saghen/blink.cmp", -- Ensure blink.cmp is listed here
		"j-hui/fidget.nvim",
	},
	config = true,
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
			copilot = function()
				return require("codecompanion.adapters").extend("copilot", {
					schema = {
						model = {
							order = 1,
							mapping = "parameters",
							type = "enum",
							desc = "ID of the model to use. See the model endpoint compatibility table for details on which models work with the Chat API.",
							---@type string|fun(): string
							default = "claude-3.7-sonnet",
							choices = {
								["o3-mini-2025-01-31"] = { opts = { can_reason = true } },
								["o1-2024-12-17"] = { opts = { can_reason = true } },
								["o1-mini-2024-09-12"] = { opts = { can_reason = true } },
								"claude-3.5-sonnet",
								"claude-3.7-sonnet",
								"claude-3.7-sonnet-thought",
								"gpt-4o-2024-08-06",
								"gemini-2.0-flash-001",
							},
						},
					},
				})
			end,
			olamma_deepseek = function()
				return require("codecompanion.adapters").extend("ollama", {
					name = "olamma_deepseek",
					schema = {
						model = {
							default = "deepseek-r1:1.5b",
							num_ctx = {
								default = 131072,
							},
							num_predict = {
								default = -1,
							},
						},
					},
				})
			end,
			-- openai_compatible = function()
			-- 	return require("codecompanion.adapters").extend("openai_compatible", {
			-- 		env = {
			-- 			url = "https://glhf.chat",
			-- 			api_key = "GLHF_API_KEY",
			-- 			chat_url = "/api/openai/v1/chat/completions",
			-- 		},
			-- 		schema = {
			-- 			model = {
			-- 				-- default = "hf:meta-llama/Meta-Llama-3.1-405B-Instruct",
			-- 				-- default = "hf:Qwen/Qwen2.5-Coder-32B-Instruct",
			-- 				default = "hf:deepseek-ai/DeepSeek-V3",
			-- 			},
			-- 			num_ctx = {
			-- 				default = 327680,
			-- 			},
			-- 		},
			-- 	})
			-- end,
		},
	},
	-- init = function()
	-- 	-- Attach blink.cmp explicitly to codecompanion's chat buffer
	-- 	local cmp = require("cmp")
	-- 	cmp.setup.buffer({
	-- 		sources = cmp.config.sources({
	-- 			{ name = "blink" },
	-- 		}),
	-- 	})
	init = function()
		require("custom.code.codecompanion_ui.fid"):init()
	end, -- end,
}
