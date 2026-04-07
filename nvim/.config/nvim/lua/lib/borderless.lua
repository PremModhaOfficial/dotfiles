local M = {}

local cached_bg = nil

local function get_colors()
	local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
	local bg = normal_hl.bg or cached_bg or 0x1a1b26
	cached_bg = bg

	local float_hl = vim.api.nvim_get_hl(0, { name = "NormalFloat" })
	local pmenu_hl = vim.api.nvim_get_hl(0, { name = "Pmenu" })
	local bg_alt = float_hl.bg or pmenu_hl.bg or bg

	if bg_alt == bg or not bg_alt then
		bg_alt = M.blend(bg, 0x000000, 0.85)
	end

	local blue = vim.api.nvim_get_hl(0, { name = "Function" }).fg
		or vim.api.nvim_get_hl(0, { name = "Type" }).fg
		or 0x61afef
	local green = vim.api.nvim_get_hl(0, { name = "String" }).fg or 0x98c379
	local cyan = vim.api.nvim_get_hl(0, { name = "Special" }).fg
		or vim.api.nvim_get_hl(0, { name = "Identifier" }).fg
		or 0x56b6c2
	local magenta = vim.api.nvim_get_hl(0, { name = "Statement" }).fg
		or vim.api.nvim_get_hl(0, { name = "Keyword" }).fg
		or 0xc678dd
	local pink = vim.api.nvim_get_hl(0, { name = "Number" }).fg or magenta
	local purple = vim.api.nvim_get_hl(0, { name = "Constant" }).fg or magenta
	local orange = vim.api.nvim_get_hl(0, { name = "WarningMsg" }).fg or 0xe5c07b
	local fg = normal_hl.fg or 0xabb2bf
	local grey = vim.api.nvim_get_hl(0, { name = "Comment" }).fg or 0x5c6370

	return {
		bg = bg,
		bg_alt = bg_alt,
		blue = blue,
		green = green,
		cyan = cyan,
		magenta = magenta,
		pink = pink,
		purple = purple,
		orange = orange,
		fg = fg,
		grey = grey,
	}
end

function M.blend(fg_color, bg_color, alpha)
	if type(fg_color) ~= "number" or type(bg_color) ~= "number" then
		return fg_color
	end
	local fg_r, fg_g, fg_b = bit.rshift(fg_color, 16), bit.band(bit.rshift(fg_color, 8), 0xff), bit.band(fg_color, 0xff)
	local bg_r, bg_g, bg_b = bit.rshift(bg_color, 16), bit.band(bit.rshift(bg_color, 8), 0xff), bit.band(bg_color, 0xff)
	local r = math.floor(fg_r * alpha + bg_r * (1 - alpha))
	local g = math.floor(fg_g * alpha + bg_g * (1 - alpha))
	local b = math.floor(fg_b * alpha + bg_b * (1 - alpha))
	return bit.bor(bit.lshift(r, 16), bit.lshift(g, 8), b)
end

local function apply_telescope(t)
	local hl = vim.api.nvim_set_hl
	hl(0, "TelescopeBorder", { fg = t.bg_alt, bg = t.bg_alt })
	hl(0, "TelescopeNormal", { bg = t.bg_alt })
	hl(0, "TelescopePreviewBorder", { fg = t.bg_alt, bg = t.bg_alt })
	hl(0, "TelescopePreviewNormal", { bg = t.bg_alt })
	hl(0, "TelescopePreviewTitle", { fg = t.bg_alt, bg = t.green, bold = true })
	hl(0, "TelescopeResultsBorder", { fg = t.bg_alt, bg = t.bg_alt })
	hl(0, "TelescopeResultsNormal", { bg = t.bg_alt })
	hl(0, "TelescopePromptBorder", { fg = t.bg_alt, bg = t.bg_alt })
	hl(0, "TelescopePromptNormal", { bg = t.bg_alt })
	hl(0, "TelescopePromptPrefix", { fg = t.blue, bg = t.bg_alt })
	hl(0, "TelescopePromptCounter", { fg = t.cyan, bg = t.bg_alt })
	hl(0, "TelescopePromptTitle", { fg = t.bg_alt, bg = t.blue, bold = true })
	hl(0, "TelescopeResultsTitle", { fg = t.blue, bg = t.bg_alt, bold = true })
	hl(0, "TelescopeSelection", { bg = t.bg })
	hl(0, "TelescopeMatching", { fg = t.cyan })
end

local function apply_fzflua(t)
	local hl = vim.api.nvim_set_hl
	hl(0, "FzfLuaNormal", { bg = t.bg_alt })
	hl(0, "FzfLuaPreviewNormal", { bg = t.bg_alt })
	hl(0, "FzfLuaBorder", { fg = t.bg_alt, bg = t.bg_alt })
	hl(0, "FzfLuaTitle", { bg = t.blue, fg = t.bg_alt })
	hl(0, "FzfLuaFzfMatch", { fg = t.cyan })
	hl(0, "FzfLuaFzfQuery", { fg = t.blue })
	hl(0, "FzfLuaFzfPrompt", { fg = t.fg })
	hl(0, "FzfLuaFzfGutter", { bg = t.bg_alt })
	hl(0, "FzfLuaFzfPointer", { fg = t.pink })
	hl(0, "FzfLuaFzfHeader", { fg = t.purple })
	hl(0, "FzfLuaFzfInfo", { fg = t.cyan })
end

local function apply_snacks(t)
	local hl = vim.api.nvim_set_hl
	hl(0, "SnacksPickerBorder", { fg = t.bg_alt, bg = t.bg_alt })
	hl(0, "SnacksPickerNormal", { bg = t.bg_alt })
	hl(0, "SnacksPickerBox", { bg = t.bg_alt })
	hl(0, "SnacksPickerList", { bg = t.bg_alt })
	hl(0, "SnacksPickerInput", { bg = t.bg_alt })
	hl(0, "SnacksPickerPreview", { bg = t.bg_alt })
	hl(0, "SnacksPickerBoxTitle", { fg = t.bg_alt, bg = t.blue })
	hl(0, "SnacksPickerPreviewTitle", { fg = t.bg_alt, bg = t.green })
	hl(0, "SnacksPickerListTitle", { fg = t.bg_alt, bg = t.magenta })
	hl(0, "SnacksPickerInputTitle", { fg = t.bg_alt, bg = t.cyan })
	hl(0, "SnacksPickerMatch", { fg = t.cyan })
	hl(0, "SnacksPickerTotals", { fg = t.cyan, bold = true })
	hl(0, "SnacksPickerPrompt", { fg = t.blue, bold = true })
	hl(0, "SnacksPickerDir", { fg = t.grey })
end

local function apply_blink(t)
	local hl = vim.api.nvim_set_hl
	-- Selection: subtle highlight using the main bg (slightly lighter than bg_alt)
	local selection_bg = M.blend(t.bg_alt, t.blue, 0.85)
	hl(0, "BlinkCmpMenu", { bg = t.bg_alt })
	hl(0, "BlinkCmpMenuBorder", { fg = t.bg_alt, bg = t.bg_alt })
	hl(0, "BlinkCmpMenuSelection", { bg = selection_bg })
	hl(0, "BlinkCmpLabel", { fg = t.fg, bg = t.bg_alt })
	hl(0, "BlinkCmpLabelDeprecated", { fg = t.grey, bg = t.bg_alt, strikethrough = true })
	hl(0, "BlinkCmpLabelMatch", { fg = t.cyan, bg = t.bg_alt })
	hl(0, "BlinkCmpDoc", { bg = t.bg_alt })
	hl(0, "BlinkCmpDocBorder", { fg = t.bg_alt, bg = t.bg_alt })
	hl(0, "BlinkCmpDocCursorLine", { bg = selection_bg })
	hl(0, "BlinkCmpSignatureHelp", { bg = t.bg_alt })
	hl(0, "BlinkCmpSignatureHelpBorder", { fg = t.bg_alt, bg = t.bg_alt })
	hl(0, "BlinkCmpSignatureHelpActiveParameter", { fg = t.cyan, bold = true })
	hl(0, "BlinkCmpSource", { fg = t.grey, bg = t.bg_alt })
	hl(0, "BlinkCmpGhostText", { fg = t.grey })
	hl(0, "BlinkCmpScrollBarThumb", { bg = t.grey })
	hl(0, "BlinkCmpScrollBarGutter", { bg = t.bg_alt })
	hl(0, "BlinkCmpKindText", { fg = t.green, bg = t.bg_alt })
	hl(0, "BlinkCmpKindMethod", { fg = t.blue, bg = t.bg_alt })
	hl(0, "BlinkCmpKindFunction", { fg = t.blue, bg = t.bg_alt })
	hl(0, "BlinkCmpKindConstructor", { fg = t.purple, bg = t.bg_alt })
	hl(0, "BlinkCmpKindField", { fg = t.green, bg = t.bg_alt })
	hl(0, "BlinkCmpKindVariable", { fg = t.orange, bg = t.bg_alt })
	hl(0, "BlinkCmpKindProperty", { fg = t.cyan, bg = t.bg_alt })
	hl(0, "BlinkCmpKindClass", { fg = t.blue, bg = t.bg_alt })
	hl(0, "BlinkCmpKindInterface", { fg = t.blue, bg = t.bg_alt })
	hl(0, "BlinkCmpKindStruct", { fg = t.blue, bg = t.bg_alt })
	hl(0, "BlinkCmpKindModule", { fg = t.blue, bg = t.bg_alt })
	hl(0, "BlinkCmpKindUnit", { fg = t.orange, bg = t.bg_alt })
	hl(0, "BlinkCmpKindValue", { fg = t.orange, bg = t.bg_alt })
	hl(0, "BlinkCmpKindEnum", { fg = t.orange, bg = t.bg_alt })
	hl(0, "BlinkCmpKindEnumMember", { fg = t.orange, bg = t.bg_alt })
	hl(0, "BlinkCmpKindKeyword", { fg = t.magenta, bg = t.bg_alt })
	hl(0, "BlinkCmpKindConstant", { fg = t.pink, bg = t.bg_alt })
	hl(0, "BlinkCmpKindSnippet", { fg = t.green, bg = t.bg_alt })
	hl(0, "BlinkCmpKindColor", { fg = t.green, bg = t.bg_alt })
	hl(0, "BlinkCmpKindFile", { fg = t.green, bg = t.bg_alt })
	hl(0, "BlinkCmpKindReference", { fg = t.green, bg = t.bg_alt })
	hl(0, "BlinkCmpKindFolder", { fg = t.green, bg = t.bg_alt })
	hl(0, "BlinkCmpKindEvent", { fg = t.green, bg = t.bg_alt })
	hl(0, "BlinkCmpKindOperator", { fg = t.magenta, bg = t.bg_alt })
	hl(0, "BlinkCmpKindTypeParameter", { fg = t.pink, bg = t.bg_alt })
end

local function apply_statusline()
	local hl = vim.api.nvim_set_hl
	hl(0, "StatusLine", { bg = "NONE" })
	hl(0, "StatusLineNC", { bg = "NONE" })
end

local function apply_floats(t)
	local hl = vim.api.nvim_set_hl
	-- Universal float highlights - most plugins inherit from these
	hl(0, "NormalFloat", { bg = t.bg_alt })
	hl(0, "FloatBorder", { bg = t.bg_alt, fg = t.bg_alt })
	hl(0, "FloatTitle", { bg = t.blue, fg = t.bg_alt, bold = true })
	hl(0, "FloatFooter", { bg = t.bg_alt, fg = t.grey })
	-- Pmenu (completion, wildmenu)
	hl(0, "Pmenu", { bg = t.bg_alt })
	hl(0, "PmenuSel", { bg = M.blend(t.bg_alt, t.blue, 0.85) })
	hl(0, "PmenuSbar", { bg = t.bg_alt })
	hl(0, "PmenuThumb", { bg = t.grey })
end

local function apply_lazy(t)
	local hl = vim.api.nvim_set_hl
	hl(0, "LazyBackdrop", { bg = "NONE" })
	hl(0, "LazyButton", { bg = t.bg_alt, fg = t.fg })
	hl(0, "LazyButtonActive", { bg = t.blue, fg = t.bg_alt, bold = true })
	hl(0, "LazyH1", { bg = t.blue, fg = t.bg_alt, bold = true })
	hl(0, "LazyH2", { fg = t.blue, bold = true })
end

local function apply_notifier(t)
	local hl = vim.api.nvim_set_hl
	local levels = { "Info", "Warn", "Error", "Debug", "Trace" }
	for _, level in ipairs(levels) do
		hl(0, "SnacksNotifier" .. level, { bg = t.bg_alt })
		hl(0, "SnacksNotifierBorder" .. level, { bg = t.bg_alt, fg = t.bg_alt })
	end
	hl(0, "SnacksNotifierHistory", { bg = t.bg_alt })
end

function M.apply()
	local t = get_colors()
	apply_floats(t)
	apply_telescope(t)
	apply_fzflua(t)
	apply_snacks(t)
	apply_blink(t)
	apply_statusline()
	apply_lazy(t)
	apply_notifier(t)
end

function M.setup()
	M.apply()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("BorderlessPickers", { clear = true }),
		callback = function()
			cached_bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
			vim.defer_fn(M.apply, 10)
		end,
	})
end

return M
