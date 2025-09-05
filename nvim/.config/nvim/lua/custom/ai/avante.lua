return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	lazy = false,
	dependencies = {
		"ravitemer/mcphub.nvim", -- Explicit dependency on MCPHub
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
	---@module "avante"
	---@type avante.Config
	opts = {

		file_selector = {
			provider = "snacks",
			provider_opts = {},
		},
		provider = "copilot",
		-- providers = {
		-- 	copilot = {
		-- 		__inherited_from = "openai",
		-- 		endpoint = "https://api.github.com/copilot_internal/v2",
		-- 		model = "claude-3.5-sonnet",
		-- 		api_key_name = "GITHUB_TOKEN",
		-- 		extra_request_body = {
		-- 			temperature = 0,
		-- 			max_tokens = 4096,
		-- 		},
		-- 	},
		-- },
		-- Add MCP system prompt
		system_prompt = function()
			local hub = require("mcphub").get_hub_instance()
			return hub and hub:get_active_servers_prompt() or ""
		end,

		-- Add MCP tools
		custom_tools = function()
			return {
				require("mcphub.extensions.avante").mcp_tool(),
			}
		end,

		-- Disable conflicting built-in tools to avoid duplication with MCP Neovim server
		disabled_tools = {
			"list_files", -- Use MCP Neovim server instead
			"search_files",
			"read_file",
			"create_file",
			"rename_file",
			"delete_file",
			"create_dir",
			"rename_dir",
			"delete_dir",
			"bash", -- Use MCP terminal access
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
	init = function()
		-- Ensure MCPHub is initialized before Avante loads
		vim.defer_fn(function()
			local ok, mcphub = pcall(require, "mcphub")
			if ok then
				-- Trigger MCPHub extensions setup for Avante
				local hub = mcphub.get_hub_instance()
				if hub then
					-- Force initialization of Avante slash commands
					pcall(require, "mcphub.extensions.avante")
				end
			end
		end, 100) -- Small delay to ensure proper loading order
	end,
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
