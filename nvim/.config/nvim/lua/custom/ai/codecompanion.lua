return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		-- { "nvim-telescope/telescope.nvim", cmd = "Telescope" },
		{ "echasnovski/mini.diff" },
		"Saghen/blink.cmp", -- Ensure blink.cmp is listed here
	},
	config = true,
	opts = {
		log_level = "TRACE",
		send_code = true,
		display = {
			diff = {
				provider = "mini_diff",
			},
		},
		strategies = {
			chat = {
				adapter = "openai_compatible",
				picker = "telescope", -- Specify telescope explicitly for `/file` picker
				diff = {
					provider = "mini_diff",
				},
			},
			inline = {
				adapter = "openai_compatible",
			},
			agent = {
				adapter = "openai_compatible",
			},
		},
		adapters = {
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
			openai_compatible = function()
				return require("codecompanion.adapters").extend("openai_compatible", {
					env = {
						url = "https://glhf.chat",
						api_key = "GLHF_API_KEY",
						chat_url = "/api/openai/v1/chat/completions",
					},
					schema = {
						model = {
							-- default = "hf:meta-llama/Meta-Llama-3.1-405B-Instruct",
							-- default = "hf:Qwen/Qwen2.5-Coder-32B-Instruct",
							default = "hf:deepseek-ai/DeepSeek-V3",
						},
						num_ctx = {
							default = 327680,
						},
					},
				})
			end,
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
	-- end,
}
