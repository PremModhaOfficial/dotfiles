return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	lazy = false,
	---@module "avante"
	---@type avante.Config
	opts = {

		file_selector = {
			provider = "snacks",
			provider_opts = {},
		},
		provider = "gemini_proxy",
		providers = {
			-- 2. Define your custom provider
			gemini_proxy = {
				-- Inherit the base settings from the 'openai' provider
				__inherited_from = "openai",

				-- Override the endpoint to point to your local LiteLLM server
				-- The '/v1' suffix is important as LiteLLM exposes an OpenAI-compatible API
				endpoint = "http://127.0.0.1:4000",

				-- Set the model to the alias you created with LiteLLM
				model = "avante-gemini",

				-- The API key is handled by the LiteLLM process itself,
				-- so you can set a dummy environment variable name here.
				api_key_name = "DUMMY_GEMINI_KEY",
			},
		},
		dual_boost = {
			enabled = false,
			first_provider = "openai",
			second_provider = "openai",
			prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
			timeout = 60000, -- Timeout in milliseconds
		},
		prompt_size = 20,
		inlay_hint = { enabled = false },
		windows = {
			position = "smart",
			wrap = true, -- similar to vim.o.wrap
			width = 50, -- default % based on available width in vertical layout
			height = 30, -- default % based on available height in horizontal layout
			sidebar_header = {
				enabled = true, -- true, false to enable/disable the header
				align = "center", -- left, center, right for title
				rounded = true,
			},
			ask = {
				floating = false,
			},
			chat = {
				floating = false,
			},
		},
	},
	-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
	build = "make",
	-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		--- The below dependencies are optional,
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		"zbirenbaum/copilot.lua", -- for providers='copilot'
		{
			-- support for image pasting
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				-- recommended settings
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
					-- required for Windows users
					-- use_absolute_path = true,
				},
			},
		},
		{
			-- Make sure to set this up properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante", "codecompanion" },
			},
			ft = { "markdown", "Avante" },
		},
	},
}
