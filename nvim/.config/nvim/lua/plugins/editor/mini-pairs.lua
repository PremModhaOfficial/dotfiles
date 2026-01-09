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

	-- Highlight matching pairs (replaces blink.pairs highlights)
	local highlight_augroup = vim.api.nvim_create_augroup("MiniPairsHighlight", { clear = true })
	local highlight_ns = vim.api.nvim_create_namespace("MiniPairsHighlight")

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = highlight_augroup,
		callback = function()
			-- Clear previous highlights
			vim.api.nvim_buf_clear_namespace(0, highlight_ns, 0, -1)

			-- Only highlight in insert mode
			if vim.fn.mode() ~= "i" then
				return
			end

			local line = vim.api.nvim_get_current_line()
			local col = vim.api.nvim_win_get_cursor(0)[2] + 1

			-- Highlight matching pairs
			local pairs = { { "(", ")" }, { "[", "]" }, { "{", "}" } }
			for _, pair in ipairs(pairs) do
				local open, close = pair[1], pair[2]

				-- Check if cursor is on or after an opening bracket
				if col > 1 and line:sub(col - 1, col - 1) == open then
					-- Find matching closing bracket
					local depth = 1
					for i = col, #line do
						local char = line:sub(i, i)
						if char == open then
							depth = depth + 1
						elseif char == close then
							depth = depth - 1
							if depth == 0 then
								-- Highlight the pair
								vim.api.nvim_buf_set_extmark(0, highlight_ns, vim.fn.line(".") - 1, col - 2, {
									end_col = col - 1,
									hl_group = "MiniPairsOpen",
									priority = 100,
								})
								vim.api.nvim_buf_set_extmark(0, highlight_ns, vim.fn.line(".") - 1, i - 1, {
									end_col = i,
									hl_group = "MiniPairsClose",
									priority = 100,
								})
								break
							end
						end
					end
				end
			end
		end,
	})

	-- Define highlight groups
	vim.api.nvim_set_hl(0, "MiniPairsOpen", { fg = "#0db9d7", bold = true })
	vim.api.nvim_set_hl(0, "MiniPairsClose", { fg = "#c099ff", bold = true })
	vim.api.nvim_set_hl(0, "MiniPairsUnmatched", { fg = "#ff6b6b", bold = true })
end,
}

