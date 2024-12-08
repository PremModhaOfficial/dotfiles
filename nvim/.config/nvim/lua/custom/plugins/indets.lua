return {
	"echasnovski/mini.indentscope",
	version = false,
	-- No need to copy this inside `setup()`. Will be used automatically.
	---@type mini.MiniIndentscope.Config
	opts = {
		-- Draw options
		symbol = "│",
		draw = {
			-- Delay (in ms) between event and start of drawing scope indicator
			delay = 100,
			-- Animation rule for scope's first drawing. A function which, given
			-- next and total step numbers, returns wait time (in ms). See
			-- |MiniIndentscope.gen_animation| for builtin options. To disable
			-- animation, use `require('mini.indentscope').gen_animation.none()`.

			-- Symbol priority. Increase to display on top of more symbols.
		},

		-- Module mappings. Use `''` (empty string) to disable one.
		mappings = {
			-- Textobjects
			object_scope = "ii",
			object_scope_with_border = "ai",

			-- Motions (jump to respective border line; if not present - body line)
			goto_top = "[i",
			goto_bottom = "]i",
		},

		-- Options which control scope computation
		options = {
			-- Type of scope's border: which line(s) with smaller indent to
			-- categorize as border. Can be one of: 'both', 'top', 'bottom', 'none'.
			border = "both",

			-- Whether to use cursor column when computing reference indent.
			-- Useful to see incremental scopes with horizontal cursor movements.
			indent_at_cursor = true,

			-- Whether to first check input line to be a border of adjacent scope.
			-- Use it if you want to place cursor on function header to get scope of
			-- its body.
			try_as_border = false,
		},

		-- Which character to use for drawing scope indicator
	},
	config = function()
		require("mini.indentscope").setup()
	end,
}

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
-- }
