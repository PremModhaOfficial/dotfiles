local M = {}
local cached_bg = nil

local function get_hl(name, fallback)
	return vim.api.nvim_get_hl(0, { name = name }).fg or fallback
end

function M.blend(fg, bg, a)
	if type(fg) ~= "number" or type(bg) ~= "number" then return fg end
	local fr, fg2, fb = bit.rshift(fg, 16), bit.band(bit.rshift(fg, 8), 0xff), bit.band(fg, 0xff)
	local br, bg2, bb = bit.rshift(bg, 16), bit.band(bit.rshift(bg, 8), 0xff), bit.band(bg, 0xff)
	return bit.bor(
		bit.lshift(math.floor(fr * a + br * (1 - a)), 16),
		bit.lshift(math.floor(fg2 * a + bg2 * (1 - a)), 8),
		math.floor(fb * a + bb * (1 - a))
	)
end

local function set_hls(tbl)
	for name, opts in pairs(tbl) do
		local resolved = {}
		for k, v in pairs(opts) do
			resolved[k] = type(v) == "function" and v() or v
		end
		vim.api.nvim_set_hl(0, name, resolved)
	end
end

local function get_colors()
	local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
	local bg = normal.bg or cached_bg or 0x1a1b26
	cached_bg = bg
	local float = vim.api.nvim_get_hl(0, { name = "NormalFloat" }).bg
	local pmenu = vim.api.nvim_get_hl(0, { name = "Pmenu" }).bg
	local ba = float or pmenu or bg
	if ba == bg or not ba then ba = M.blend(bg, 0x000000, 0.85) end
	return {
		bg = bg, ba = ba,
		b = get_hl("Function", 0x61afef), g = get_hl("String", 0x98c379),
		c = get_hl("Special", 0x56b6c2), m = get_hl("Statement", 0xc678dd),
		p = get_hl("Number", 0xc678dd), pu = get_hl("Constant", 0xc678dd),
		o = get_hl("WarningMsg", 0xe5c07b), f = normal.fg or 0xabb2bf,
		gr = get_hl("Comment", 0x5c6370),
	}
end

-- Kind color map for BlinkCmp
local kind_colors = {
	Text = "g", Method = "b", Function = "b", Constructor = "pu",
	Field = "g", Variable = "o", Property = "c", Class = "b",
	Interface = "b", Struct = "b", Module = "b", Unit = "o",
	Value = "o", Enum = "o", EnumMember = "o", Keyword = "m",
	Constant = "p", Snippet = "g", Color = "g", File = "g",
	Reference = "g", Folder = "g", Event = "g", Operator = "m",
	TypeParameter = "p",
}

function M.apply()
	local t = get_colors()
	local sel = M.blend(t.ba, t.b, 0.85)
	local hl = {
		-- Floats
		NormalFloat = { bg = t.ba }, FloatBorder = { fg = t.ba, bg = t.ba },
		FloatTitle = { bg = t.b, fg = t.ba, bold = true }, FloatFooter = { bg = t.ba, fg = t.gr },
		Pmenu = { bg = t.ba }, PmenuSel = { bg = sel }, PmenuSbar = { bg = t.ba }, PmenuThumb = { bg = t.gr },
		-- Telescope
		TelescopeBorder = { fg = t.ba, bg = t.ba }, TelescopeNormal = { bg = t.ba },
		TelescopePreviewBorder = { fg = t.ba, bg = t.ba }, TelescopePreviewNormal = { bg = t.ba },
		TelescopePreviewTitle = { fg = t.ba, bg = t.g, bold = true },
		TelescopeResultsBorder = { fg = t.ba, bg = t.ba }, TelescopeResultsNormal = { bg = t.ba },
		TelescopePromptBorder = { fg = t.ba, bg = t.ba }, TelescopePromptNormal = { bg = t.ba },
		TelescopePromptPrefix = { fg = t.b, bg = t.ba }, TelescopePromptCounter = { fg = t.c, bg = t.ba },
		TelescopePromptTitle = { fg = t.ba, bg = t.b, bold = true },
		TelescopeResultsTitle = { fg = t.b, bg = t.ba, bold = true },
		TelescopeSelection = { bg = t.bg }, TelescopeMatching = { fg = t.c },
		-- Snacks Picker
		SnacksPickerBorder = { fg = t.ba, bg = t.ba }, SnacksPickerNormal = { bg = t.ba },
		SnacksPickerBox = { bg = t.ba }, SnacksPickerList = { bg = t.ba },
		SnacksPickerInput = { bg = t.ba }, SnacksPickerPreview = { bg = t.ba },
		SnacksPickerBoxTitle = { fg = t.ba, bg = t.b },
		SnacksPickerPreviewTitle = { fg = t.ba, bg = t.g },
		SnacksPickerListTitle = { fg = t.ba, bg = t.m },
		SnacksPickerInputTitle = { fg = t.ba, bg = t.c },
		SnacksPickerMatch = { fg = t.c }, SnacksPickerTotals = { fg = t.c, bold = true },
		SnacksPickerPrompt = { fg = t.b, bold = true }, SnacksPickerDir = { fg = t.gr },
		-- Statusline
		StatusLine = { bg = "NONE" }, StatusLineNC = { bg = "NONE" },
		-- Lazy
		LazyBackdrop = { bg = "NONE" }, LazyButton = { bg = t.ba, fg = t.f },
		LazyButtonActive = { bg = t.b, fg = t.ba, bold = true },
		LazyH1 = { bg = t.b, fg = t.ba, bold = true }, LazyH2 = { fg = t.b, bold = true },
	}
	-- BlinkCmp (bulk)
	for _, lv in ipairs({ "Info", "Warn", "Error", "Debug", "Trace" }) do
		hl["SnacksNotifier" .. lv] = { bg = t.ba }
		hl["SnacksNotifierBorder" .. lv] = { fg = t.ba, bg = t.ba }
	end
	hl.SnacksNotifierHistory = { bg = t.ba }
	for _, v in ipairs({
		"Menu", "MenuBorder", "MenuSelection", "Label", "LabelDeprecated", "LabelMatch",
		"Doc", "DocBorder", "DocCursorLine", "SignatureHelp", "SignatureHelpBorder",
		"Source", "GhostText", "ScrollBarThumb", "ScrollBarGutter",
	}) do
		hl["BlinkCmp" .. v] = { bg = t.ba }
	end
	hl.BlinkCmpLabelDeprecated = { fg = t.gr, bg = t.ba, strikethrough = true }
	hl.BlinkCmpLabelMatch = { fg = t.c, bg = t.ba }
	hl.BlinkCmpSignatureHelpActiveParameter = { fg = t.c, bold = true }
	hl.BlinkCmpGhostText = { fg = t.gr }
	-- BlinkCmp kinds via loop
	for kind, color_key in pairs(kind_colors) do
		hl["BlinkCmpKind" .. kind] = { fg = t[color_key], bg = t.ba }
	end
	set_hls(hl)
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
