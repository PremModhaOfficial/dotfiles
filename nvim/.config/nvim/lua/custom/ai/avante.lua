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
		provider = "openrouter",
		providers = {
			openrouter = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				model = "qwen/qwen3-coder:free",
				api_key_name = "OPENROUTER_API_KEY",
				extra_request_body = {
					temperature = 0,
					max_tokens = 4096,
				},
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
