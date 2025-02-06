return {
	{
		"echasnovski/mini.indentscope",
		version = false,
		-- enabled = false,
		-- No need to copy this inside `setup()`. Will be used automatically.
		---@module "mini.indentscope"
		opts = {
			-- Draw options
			draw = { delay = 100 },
			-- Module mappings. Use `''` (empty string) to disable one.
			mappings = {
				-- Textobjects
				object_scope = "ii",
				object_scope_with_border = "ai",
				-- Motions (jump to respective border line; if not present - body line)
				goto_top = "[i",
				goto_bottom = "]i",
			},

			options = {
				border = "both", -- categorize as border. Can be one of: 'both', 'top', 'bottom', 'none'.
				indent_at_cursor = true,
				try_as_border = false,
			},
			symbol = "│",
		},
		-- config = function()
		-- 	require("mini.indentscope").setup()
		-- end,
	},
	{ -- Collection of various small independent plugins/modules
		"echasnovski/mini.nvim",
		config = function()
			-- Better Around/Inside textobjects
			--
			-- Examples:
			--  - va)  - [V]isually select [A]round [)]paren
			--  - yinq - [Y]ank [I]nside [N]ext [']quote
			--  - ci'  - [C]hange [I]nside [']quote
			require("mini.ai").setup({ n_lines = 500 })

			-- Add/delete/replace surroundings (brackets, quotes, etc.)
			--
			-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
			-- - sd'   - [S]urround [D]elete [']quotes
			-- - sr)'  - [S]urround [R]eplace [)] [']
			require("mini.surround").setup()

			-- Simple and easy statusline.
			--  You could remove this setup call if you don't like it,
			--  and try some other statusline plugin

			--TODO: STATUSLINE
			-- local statusline = require("mini.statusline")
			-- statusline.setup({ use_icons = vim.g.have_nerd_font })
			-- ---@diagnostic disable-next-line: duplicate-set-field
			-- statusline.section_location = function() return "%2l:%-2v" end

			-- ... and there is more!
			--  Check out: https://github.com/echasnovski/mini.nvim
		end,
	},
}
-- }
--
--
-- return {
-- 	"lukas-reineke/indent-blankline.nvim",
-- 	main = "ibl",
-- 	---@module "ibl"
-- 	---@type ibl.config
--
-- 	config = function()
-- 		local ibl = require("ibl")
-- 		-- create the highlight groups in the highlight setup hook, so they are reset
-- 		-- every time the colorscheme changes
--
-- 		---@type ibl.config
-- 		ibl.config = {
-- 			enabled = true,
-- 			-- indent = { char = "", },
-- 			---@type ibl.config.scope
-- 			scope = {
-- 				enabled = true,
-- 				char = "│",
-- 				-- char = "",
-- 				show_exact_scope = true,
-- 				-- highlight = highlight,
-- 			},
-- 		}
--
-- 		ibl.setup(ibl.config)
-- 	end,
--
-- },
--
