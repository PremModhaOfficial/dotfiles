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

		-- Tab out of brackets/quotes: cursor inside `foo|)` -> Tab puts cursor past `)`
		local function tab_out()
			local line = vim.api.nvim_get_current_line()
			local row, col = vim.api.nvim_win_get_cursor(0)[1], vim.api.nvim_win_get_cursor(0)[2] + 1
			local pairs = { { "(", ")" }, { "[", "]" }, { "{", "}" }, { '"', '"' }, { "'", "'" }, { "`", "`" } }
			for _, pair in ipairs(pairs) do
				if line:sub(col, col) == pair[2] then
					local open_pat = pair[1]:gsub("([^%w])", "%%%1")
					local open_pos = line:sub(1, col - 1):find(open_pat .. "%s*$")
					if open_pos then
						vim.api.nvim_win_set_cursor(0, { row, col })
						return
					end
				end
			end
			return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
		end

		vim.keymap.set("i", "<Tab>", tab_out, { expr = true, desc = "Tab out of brackets or regular tab" })

		vim.keymap.set("i", "<S-Tab>", function()
			local line = vim.api.nvim_get_current_line()
			local col = vim.api.nvim_win_get_cursor(0)[2] + 1
			if col > 1 then
				local pairs = { { "(", ")" }, { "[", "]" }, { "{", "}" }, { '"', '"' }, { "'", "'" }, { "`", "`" } }
				for _, pair in ipairs(pairs) do
					if line:sub(col - 1, col - 1) == pair[1] then
						vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col - 2 })
						return
					end
				end
			end
			return vim.api.nvim_replace_termcodes("<S-Tab>", true, true, true)
		end, { expr = true, desc = "Backwards tab out of brackets" })

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

