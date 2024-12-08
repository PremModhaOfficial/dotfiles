return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	lazy = false,
	opts = {
		provider = "copilot",
		auto_suggestions_provider = "copilot",
		-- provider = "tabnine",
		-- auto_suggestions_provider = "tabnine",
		openai_compatible = {
			endpoint = "https://glhf.chat/api/openai/v1/chat/completions",
			api_key_name = "GLHF_API_KEY",
			model = "hf:meta-llama/Meta-Llama-3.1-405B-Instruct",
		},

		prompt_size = 20,
		inlay_hint = { enabled = true },
		windows = {
			position = "smart",
			wrap = true, -- similar to vim.o.wrap
			width = 45, -- default % based on available width in vertical layout
			height = 30, -- default % based on available height in horizontal layout
			sidebar_header = {
				enabled = true, -- true, false to enable/disable the header
				align = "center", -- left, center, right for title
				rounded = true,
			},
			ask = {
				floating = true,
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
