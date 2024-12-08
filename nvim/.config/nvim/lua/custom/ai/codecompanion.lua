return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		{ "nvim-telescope/telescope.nvim", cmd = "Telescope" },
		{ "echasnovski/mini.diff" },
	},
	config = true,
	opts = {
		send_code = true,
		display = {
			diff = {
				provider = "mini_diff",
			},
		},
		strategies = {
			chat = {
				adapter = "openai_compatible",
			},
			inline = {
				adapter = "openai_compatible",
			},
			agent = {
				adapter = "openai_compatible",
			},
		},
		adapters = {
			openai_compatible = function()
				return require("codecompanion.adapters").extend("openai_compatible", {
					env = {
						-- URL for the OpenAI API
						url = "https://glhf.chat",
						-- API key for the OpenAI API
						api_key = "GLHF_API_KEY",
						-- URL for chat completions
						chat_url = "/api/openai/v1/chat/completions",
					},
					schema = {
						model = {
							default = "hf:meta-llama/Meta-Llama-3.1-405B-Instruct",
						},
						num_ctx = {
							default = 32768,
						},
					},
				})
			end,
		},
	},
}
