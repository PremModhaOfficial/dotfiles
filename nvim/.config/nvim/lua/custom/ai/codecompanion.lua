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
				adapter = "gemini",
				picker = "snacks", -- Specify telescope explicitly for `/file` picker

				diff = {
					provider = "mini_diff",
				},
			},
			inline = {
				adapter = "gemini",
			},
			agent = {
				adapter = "gemini",
			},
		},
		-- adapters = {},
	},
	-- init = function()
	-- 	-- Attach blink.cmp explicitly to codecompanion's chat buffer
	-- 	local cmp = require("cmp")
	-- 	cmp.setup.buffer({
	-- 		sources = cmp.config.sources({
	-- 			{ name = "blink" },
	-- 		}),
	-- 	})
	-- init = function()
	-- require("custom.code.codecompanion_ui.fid"):init()
	-- end, -- end,
}
