-- ============================================================================
-- PLUGIN: Code Companion
-- PURPOSE: AI-powered code assistant and chat interface
-- DEPENDENCIES: plenary, treesitter, mini.diff
-- ============================================================================

return {
	"olimorris/codecompanion.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		-- { "nvim-telescope/telescope.nvim", cmd = "Telescope" },
		{ "nvim-mini/mini.diff" },
		-- "Saghen/blink.cmp", -- Ensure blink.cmp is listed here
		-- "j-hui/fidget.nvim",
	},
	---@module "codecompanion"
	opts = {
		opts = {
			log_level = "TRACE",
		},
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
		interactions = {
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
		extensions = {},
		prompt_library = {},
	},
	init = function()
		-- ╭─────────────────────────────────────────────────────────────────────╮
		-- │ Blink.cmp Integration                                               │
		-- │ CodeCompanion source is configured in blink.lua with:               │
		-- │   - Conditional enabling for codecompanion filetypes                │
		-- │   - <M-x> keymap to show CodeCompanion completions only             │
		-- │   - <C-a> keymap to show all AI providers                           │
		-- ╰─────────────────────────────────────────────────────────────────────╯
		-- NOTE: vim.g.codecompanion_disable_blink is NOT set, allowing native integration
	end,
}

