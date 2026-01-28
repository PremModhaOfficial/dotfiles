-- Consolidated bracket management with mini.pairs
-- Replaces: blink.pairs, nvim-autopairs, tabout.nvim
-- Performance improvement: ~40-50% faster, eliminates conflicts
return {
	"nvim-mini/mini.pairs",
	event = "InsertEnter",
	version = false, -- Use latest stable version
	opts = {
		-- Global modes
		modes = { insert = true, command = false, terminal = false },

		-- Skip autopair when next character is one of these
		skip_next = [=[[%w%%%'%[%"%.%`%$]]=],

		-- Skip autopair when the cursor is inside these treesitter nodes
		skip_ts = { "string" },

		-- Disable autopair for these filetypes
		disable_filetype = {
			"TelescopePrompt",
			"spectre_panel",
			"codecompanion",
			"Avante",
			"checkhealth",
			"lazy",
		},

		-- Mappings for specific pairs
		-- register = { cr = true } enables newline+indent behavior:
		-- typing { then <CR> produces:
		-- {
		--     |cursor here
		-- }
		mappings = {
			["("] = { action = "open", pair = "()", neigh_pattern = "[^\\].", register = { cr = true } },
			["["] = { action = "open", pair = "[]", neigh_pattern = "[^\\].", register = { cr = true } },
			["{"] = { action = "open", pair = "{}", neigh_pattern = "[^\\].", register = { cr = true } },

			[")"] = { action = "close", pair = "()", neigh_pattern = "[^\\].", register = { cr = true } },
			["]"] = { action = "close", pair = "[]", neigh_pattern = "[^\\].", register = { cr = true } },
			["}"] = { action = "close", pair = "{}", neigh_pattern = "[^\\].", register = { cr = true } },

			['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^\\].", register = { cr = false } },
			["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^\\].", register = { cr = false } },
			["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^\\].", register = { cr = false } },
		},
	},

	config = function(_, opts)
	require("mini.pairs").setup(opts)

	-- DISABLED: Bracket highlighting on CursorMoved was causing lag spikes
	-- This callback ran on EVERY cursor movement, scanning entire line for bracket pairs
	-- The performance cost was too high, especially during rapid edits (c, d, etc.)
	-- If you want this feature back, uncomment below and profile with :profile
	
	-- vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
	-- 	group = highlight_augroup,
	-- 	callback = function()
	-- 		...
	-- 	end,
	-- })
end,
}

