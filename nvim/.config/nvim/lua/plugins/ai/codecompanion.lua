-- ============================================================================
-- PLUGIN: Code Companion
-- PURPOSE: AI-powered code assistant and chat interface
-- DEPENDENCIES: plenary, mini.diff
-- ============================================================================

return {
	"olimorris/codecompanion.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-mini/mini.diff" },
	},
	---@module "codecompanion"
	opts = {
		opts = {
			log_level = "TRACE",
		},
		display = {
			diff = {
				enabled = true,
				window = {
					width = function()
						return math.min(120, vim.o.columns - 10)
					end,
					height = function()
						return vim.o.lines - 4
					end,
				},
				word_highlights = {
					additions = true,
					deletions = true,
				},
			},
		},
		interactions = {
			chat = {
				adapter = "copilot",
			},
			inline = {
				adapter = "copilot",
			},
			cmd = {
				adapter = "copilot",
			},
		},
		adapters = {
			acp = {
				opts = {
					show_presets = false,
				},
			},
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

