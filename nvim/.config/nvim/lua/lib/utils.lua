local M = {}

local transparency_groups = {
	"Normal",
	"NormalNC",
	"NormalFloat",
	"Whitespace",
	"NonText",
	"EndOfBuffer",
	"MatchParen",
	"Delimiter",
	"@punctuation",
	"@punctuation.bracket",
	"@punctuation.delimiter",
	"@punctuation.special",
	"@tag.delimiter",
}

local function clear_bg(name)
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
	if not ok or not hl then return end
	hl.bg = nil
	pcall(vim.api.nvim_set_hl, 0, name, hl)
end

local function apply_transparency()
	for _, name in ipairs(transparency_groups) do
		clear_bg(name)
	end
end

local transparency_enabled = false
local saved_highlights = {}

local function save_highlights()
	saved_highlights = {}
	for _, name in ipairs(transparency_groups) do
		saved_highlights[name] = vim.api.nvim_get_hl(0, { name = name })
	end
end

local function restore_highlights()
	for _, name in ipairs(transparency_groups) do
		if saved_highlights[name] then
			vim.api.nvim_set_hl(0, name, saved_highlights[name])
		end
	end
end

function M.setup_transparency()
	transparency_enabled = true
	save_highlights()
	apply_transparency()
	vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("TransparencyFix", { clear = true }),
		callback = function()
			if transparency_enabled then
				vim.defer_fn(function()
					apply_transparency()
					vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })
				end, 0)
			end
		end,
	})

	return function()
		transparency_enabled = false
		restore_highlights()
	end
end

function M.colorscheme_with_transparency(color, transparent_by_default, callback)
	if not callback then
		color = color or "tokyonight-night"
		vim.cmd.colorscheme(color)
	else
		callback()
		vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })
	end

	if not transparent_by_default then
		return M.setup_transparency()
	end
end

function M.default_colors(col)
	if not col then
		M.colorscheme_with_transparency("fluoromachine", false)
		return
	end
	M.colorscheme_with_transparency(col, false)
end

function M.border(hl_name)
	return {
		{ "┌", hl_name },
		{ "─", hl_name },
		{ "┐", hl_name },
		{ "│", hl_name },
		{ "┘", hl_name },
		{ "─", hl_name },
		{ "└", hl_name },
		{ "│", hl_name },
	}
end

return M
