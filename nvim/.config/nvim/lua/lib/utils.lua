local M = {}

local function make_none()
	local Normal = vim.api.nvim_get_hl(0, { name = "Normal" })
	local NormalNC = vim.api.nvim_get_hl(0, { name = "NormalNC" })
	local NormalFloat = vim.api.nvim_get_hl(0, { name = "NormalFloat" })
	local Whitespace = vim.api.nvim_get_hl(0, { name = "Whitespace" })
	local NonText = vim.api.nvim_get_hl(0, { name = "NonText" })
	local EndOfBuffer = vim.api.nvim_get_hl(0, { name = "EndOfBuffer" })

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "Whitespace", { fg = "none", bg = "none" })
	vim.api.nvim_set_hl(0, "NonText", { fg = "none", bg = "none" })
	vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = "none", bg = "none" })

	return function()
		vim.api.nvim_set_hl(0, "Normal", { bg = Normal.bg })
		vim.api.nvim_set_hl(0, "NormalNC", { bg = NormalNC.bg })
		vim.api.nvim_set_hl(0, "NormalFloat", { bg = NormalFloat.bg })
		vim.api.nvim_set_hl(0, "Whitespace", { fg = Whitespace.fg, bg = Whitespace.bg })
		vim.api.nvim_set_hl(0, "NonText", { fg = NonText.fg, bg = NonText.bg })
		vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = EndOfBuffer.fg, bg = EndOfBuffer.bg })
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
		return make_none()
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
