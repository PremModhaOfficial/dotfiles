-- ============================================================================
-- BORDERLESS UI MODULE
-- Applies consistent borderless styling across all floating UI elements
-- Inspired by cyberdream.nvim's borderless_pickers implementation
-- ============================================================================

local M = {}

-- Default colors (will be overridden by colorscheme detection)
local function get_colors()
	local ok, colors = pcall(function()
		-- Try to get colors from current colorscheme
		local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
		local comment = vim.api.nvim_get_hl(0, { name = "Comment" })
		local func = vim.api.nvim_get_hl(0, { name = "Function" })
		local string_hl = vim.api.nvim_get_hl(0, { name = "String" })
		local keyword = vim.api.nvim_get_hl(0, { name = "Keyword" })
		local type_hl = vim.api.nvim_get_hl(0, { name = "Type" })
		local constant = vim.api.nvim_get_hl(0, { name = "Constant" })
		local special = vim.api.nvim_get_hl(0, { name = "Special" })
		local error_hl = vim.api.nvim_get_hl(0, { name = "Error" })
		local warning_hl = vim.api.nvim_get_hl(0, { name = "WarningMsg" })

		local bg = normal.bg and string.format("#%06x", normal.bg) or "#191724"
		local fg = normal.fg and string.format("#%06x", normal.fg) or "#e0def4"

		-- Calculate bg_alt (slightly lighter than bg)
		local function lighten(hex, amount)
			if not hex or hex:sub(1, 1) ~= "#" then return hex end
			local r = tonumber(hex:sub(2, 3), 16) or 0
			local g = tonumber(hex:sub(4, 5), 16) or 0
			local b = tonumber(hex:sub(6, 7), 16) or 0
			r = math.min(255, math.floor(r + (255 - r) * amount))
			g = math.min(255, math.floor(g + (255 - g) * amount))
			b = math.min(255, math.floor(b + (255 - b) * amount))
			return string.format("#%02x%02x%02x", r, g, b)
		end

		return {
			bg = bg,
			bg_alt = lighten(bg, 0.08),
			fg = fg,
			grey = comment.fg and string.format("#%06x", comment.fg) or "#6e6a86",
			blue = func.fg and string.format("#%06x", func.fg) or "#31748f",
			green = string_hl.fg and string.format("#%06x", string_hl.fg) or "#9ccfd8",
			cyan = type_hl.fg and string.format("#%06x", type_hl.fg) or "#9ccfd8",
			magenta = keyword.fg and string.format("#%06x", keyword.fg) or "#c4a7e7",
			purple = keyword.fg and string.format("#%06x", keyword.fg) or "#c4a7e7",
			orange = constant.fg and string.format("#%06x", constant.fg) or "#f6c177",
			yellow = constant.fg and string.format("#%06x", constant.fg) or "#f6c177",
			red = error_hl.fg and string.format("#%06x", error_hl.fg) or "#eb6f92",
			pink = special.fg and string.format("#%06x", special.fg) or "#ebbcba",
		}
	end)

	if not ok then
		-- Fallback Rose Pine colors
		return {
			bg = "#191724",
			bg_alt = "#1f1d2e",
			fg = "#e0def4",
			grey = "#6e6a86",
			blue = "#31748f",
			green = "#9ccfd8",
			cyan = "#9ccfd8",
			magenta = "#c4a7e7",
			purple = "#c4a7e7",
			orange = "#f6c177",
			yellow = "#f6c177",
			red = "#eb6f92",
			pink = "#ebbcba",
		}
	end

	return colors
end

-- Blink.cmp completion menu borderless styling
local function blink_cmp(colors)
	return {
		-- Menu window
		BlinkCmpMenu = { bg = colors.bg_alt, fg = colors.fg },
		BlinkCmpMenuBorder = { bg = colors.bg_alt, fg = colors.bg_alt },
		BlinkCmpMenuSelection = { bg = colors.blue, fg = colors.bg },

		-- Scrollbar
		BlinkCmpScrollBarThumb = { bg = colors.grey },
		BlinkCmpScrollBarGutter = { bg = colors.bg_alt },

		-- Labels
		BlinkCmpLabel = { bg = colors.bg_alt, fg = colors.fg },
		BlinkCmpLabelDeprecated = { bg = colors.bg_alt, fg = colors.grey, strikethrough = true },
		BlinkCmpLabelMatch = { bg = colors.bg_alt, fg = colors.cyan, bold = true },
		BlinkCmpLabelDetail = { bg = colors.bg_alt, fg = colors.grey },
		BlinkCmpLabelDescription = { bg = colors.bg_alt, fg = colors.grey },

		-- Kind icons
		BlinkCmpKind = { bg = colors.bg_alt, fg = colors.blue },
		BlinkCmpKindText = { bg = colors.bg_alt, fg = colors.fg },
		BlinkCmpKindMethod = { bg = colors.bg_alt, fg = colors.magenta },
		BlinkCmpKindFunction = { bg = colors.bg_alt, fg = colors.magenta },
		BlinkCmpKindConstructor = { bg = colors.bg_alt, fg = colors.magenta },
		BlinkCmpKindField = { bg = colors.bg_alt, fg = colors.cyan },
		BlinkCmpKindVariable = { bg = colors.bg_alt, fg = colors.cyan },
		BlinkCmpKindClass = { bg = colors.bg_alt, fg = colors.yellow },
		BlinkCmpKindInterface = { bg = colors.bg_alt, fg = colors.yellow },
		BlinkCmpKindModule = { bg = colors.bg_alt, fg = colors.yellow },
		BlinkCmpKindProperty = { bg = colors.bg_alt, fg = colors.cyan },
		BlinkCmpKindUnit = { bg = colors.bg_alt, fg = colors.orange },
		BlinkCmpKindValue = { bg = colors.bg_alt, fg = colors.orange },
		BlinkCmpKindEnum = { bg = colors.bg_alt, fg = colors.yellow },
		BlinkCmpKindKeyword = { bg = colors.bg_alt, fg = colors.purple },
		BlinkCmpKindSnippet = { bg = colors.bg_alt, fg = colors.green },
		BlinkCmpKindColor = { bg = colors.bg_alt, fg = colors.pink },
		BlinkCmpKindFile = { bg = colors.bg_alt, fg = colors.fg },
		BlinkCmpKindReference = { bg = colors.bg_alt, fg = colors.red },
		BlinkCmpKindFolder = { bg = colors.bg_alt, fg = colors.yellow },
		BlinkCmpKindEnumMember = { bg = colors.bg_alt, fg = colors.cyan },
		BlinkCmpKindConstant = { bg = colors.bg_alt, fg = colors.orange },
		BlinkCmpKindStruct = { bg = colors.bg_alt, fg = colors.yellow },
		BlinkCmpKindEvent = { bg = colors.bg_alt, fg = colors.magenta },
		BlinkCmpKindOperator = { bg = colors.bg_alt, fg = colors.fg },
		BlinkCmpKindTypeParameter = { bg = colors.bg_alt, fg = colors.cyan },
		BlinkCmpKindCopilot = { bg = colors.bg_alt, fg = colors.green },

		-- Source
		BlinkCmpSource = { bg = colors.bg_alt, fg = colors.grey },

		-- Ghost text
		BlinkCmpGhostText = { fg = colors.grey, italic = true },

		-- Documentation window
		BlinkCmpDoc = { bg = colors.bg_alt, fg = colors.fg },
		BlinkCmpDocBorder = { bg = colors.bg_alt, fg = colors.bg_alt },
		BlinkCmpDocSeparator = { bg = colors.bg_alt, fg = colors.grey },
		BlinkCmpDocCursorLine = { bg = colors.blue, fg = colors.bg },

		-- Signature help
		BlinkCmpSignatureHelp = { bg = colors.bg_alt, fg = colors.fg },
		BlinkCmpSignatureHelpBorder = { bg = colors.bg_alt, fg = colors.bg_alt },
		BlinkCmpSignatureHelpActiveParameter = { fg = colors.cyan, bold = true },
	}
end

-- Telescope and Snacks picker borderless styling
local function pickers(colors)
	return {
		-- Telescope borderless styling
		TelescopeBorder = { fg = colors.bg_alt, bg = colors.bg_alt },
		TelescopeNormal = { bg = colors.bg_alt },
		TelescopePreviewBorder = { fg = colors.bg_alt, bg = colors.bg_alt },
		TelescopePreviewNormal = { bg = colors.bg_alt },
		TelescopePreviewTitle = { fg = colors.bg_alt, bg = colors.green, bold = true },
		TelescopePromptBorder = { fg = colors.bg_alt, bg = colors.bg_alt },
		TelescopePromptNormal = { bg = colors.bg_alt },
		TelescopePromptTitle = { fg = colors.bg_alt, bg = colors.blue, bold = true },
		TelescopeResultsBorder = { fg = colors.bg_alt, bg = colors.bg_alt },
		TelescopeResultsNormal = { bg = colors.bg_alt },
		TelescopeResultsTitle = { fg = colors.bg_alt, bg = colors.cyan, bold = true },

		-- Snacks picker borderless styling
		SnacksPicker = { bg = colors.bg_alt },
		SnacksPickerBorder = { fg = colors.bg_alt, bg = colors.bg_alt },
		SnacksPickerNormal = { bg = colors.bg_alt },
		SnacksPickerInput = { bg = colors.bg_alt },
		SnacksPickerInputBorder = { fg = colors.bg_alt, bg = colors.bg_alt },
		SnacksPickerInputTitle = { fg = colors.bg_alt, bg = colors.blue, bold = true },
		SnacksPickerList = { bg = colors.bg_alt },
		SnacksPickerListBorder = { fg = colors.bg_alt, bg = colors.bg_alt },
		SnacksPickerListTitle = { fg = colors.bg_alt, bg = colors.cyan, bold = true },
		SnacksPickerPreview = { bg = colors.bg_alt },
		SnacksPickerPreviewBorder = { fg = colors.bg_alt, bg = colors.bg_alt },
		SnacksPickerPreviewTitle = { fg = colors.bg_alt, bg = colors.green, bold = true },
		SnacksPickerPrompt = { fg = colors.magenta, bg = colors.bg_alt },
		SnacksPickerBox = { bg = colors.bg_alt },
	}
end

-- Plugin UI borderless styling (Lazy, Mason, Noice, WhichKey)
local function plugins(colors)
	return {
		-- General floating windows
		NormalFloat = { bg = colors.bg_alt },
		FloatBorder = { bg = colors.bg_alt, fg = colors.bg_alt },
		FloatTitle = { bg = colors.blue, fg = colors.bg_alt, bold = true },
		Pmenu = { bg = colors.bg_alt, fg = colors.fg },
		PmenuBorder = { bg = colors.bg_alt, fg = colors.bg_alt },
		PmenuSel = { bg = colors.blue, fg = colors.bg },
		PmenuSbar = { bg = colors.bg_alt },
		PmenuThumb = { bg = colors.grey },

		-- Lazy.nvim
		LazyNormal = { bg = colors.bg_alt, fg = colors.fg },
		LazyBorder = { bg = colors.bg_alt, fg = colors.bg_alt },
		LazyButton = { bg = colors.bg, fg = colors.fg },
		LazyButtonActive = { bg = colors.blue, fg = colors.bg, bold = true },
		LazyH1 = { bg = colors.blue, fg = colors.bg, bold = true },
		LazyH2 = { fg = colors.blue, bold = true },
		LazySpecial = { fg = colors.cyan },
		LazyCommit = { fg = colors.green },
		LazyCommitType = { fg = colors.magenta },
		LazyReasonPlugin = { fg = colors.cyan },
		LazyReasonEvent = { fg = colors.magenta },
		LazyReasonKeys = { fg = colors.green },
		LazyReasonCmd = { fg = colors.blue },
		LazyReasonFt = { fg = colors.cyan },
		LazyReasonSource = { fg = colors.grey },

		-- Mason.nvim
		MasonNormal = { bg = colors.bg_alt, fg = colors.fg },
		MasonBorder = { bg = colors.bg_alt, fg = colors.bg_alt },
		MasonHeader = { bg = colors.blue, fg = colors.bg, bold = true },
		MasonHeaderSecondary = { bg = colors.cyan, fg = colors.bg, bold = true },
		MasonHighlight = { fg = colors.cyan },
		MasonHighlightBlock = { bg = colors.cyan, fg = colors.bg },
		MasonHighlightBlockBold = { bg = colors.cyan, fg = colors.bg, bold = true },
		MasonHighlightSecondary = { fg = colors.magenta },
		MasonHighlightBlockSecondary = { bg = colors.magenta, fg = colors.bg },
		MasonMuted = { fg = colors.grey },
		MasonMutedBlock = { bg = colors.grey, fg = colors.bg },

		-- Noice
		NoiceCmdline = { bg = colors.bg_alt, fg = colors.fg },
		NoiceCmdlinePopup = { bg = colors.bg_alt, fg = colors.fg },
		NoiceCmdlinePopupBorder = { bg = colors.bg_alt, fg = colors.bg_alt },
		NoiceCmdlinePopupTitle = { bg = colors.blue, fg = colors.bg_alt, bold = true },
		NoiceCmdlineIcon = { fg = colors.cyan },
		NoicePopup = { bg = colors.bg_alt, fg = colors.fg },
		NoicePopupBorder = { bg = colors.bg_alt, fg = colors.bg_alt },
		NoicePopupmenu = { bg = colors.bg_alt, fg = colors.fg },
		NoicePopupmenuBorder = { bg = colors.bg_alt, fg = colors.bg_alt },
		NoicePopupmenuSelected = { bg = colors.blue, fg = colors.bg },
		NoiceConfirm = { bg = colors.bg_alt },
		NoiceConfirmBorder = { bg = colors.bg_alt, fg = colors.bg_alt },
		NoiceMini = { bg = colors.bg_alt },
		NoiceFormatProgressDone = { bg = colors.green, fg = colors.bg },
		NoiceFormatProgressTodo = { bg = colors.grey, fg = colors.fg },
		NoiceLspProgressTitle = { fg = colors.fg },
		NoiceLspProgressClient = { fg = colors.cyan },
		NoiceLspProgressSpinner = { fg = colors.blue },

		-- WhichKey
		WhichKey = { fg = colors.cyan },
		WhichKeyFloat = { bg = colors.bg_alt },
		WhichKeyBorder = { bg = colors.bg_alt, fg = colors.bg_alt },
		WhichKeyGroup = { fg = colors.blue },
		WhichKeyDesc = { fg = colors.fg },
		WhichKeySeparator = { fg = colors.grey },
		WhichKeyValue = { fg = colors.grey },
		WhichKeyIcon = { fg = colors.magenta },
		WhichKeyIconAzure = { fg = colors.cyan },
		WhichKeyIconBlue = { fg = colors.blue },
		WhichKeyIconCyan = { fg = colors.cyan },
		WhichKeyIconGreen = { fg = colors.green },
		WhichKeyIconGrey = { fg = colors.grey },
		WhichKeyIconOrange = { fg = colors.orange },
		WhichKeyIconPurple = { fg = colors.magenta },
		WhichKeyIconRed = { fg = colors.red },
		WhichKeyIconYellow = { fg = colors.yellow },
	}
end

-- Statusline transparent styling
local function statusline()
	return {
		StatusLine = { bg = "NONE" },
		StatusLineNC = { bg = "NONE" },
	}
end

-- Apply all highlights
local function apply_highlights(highlights)
	for group, opts in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end

-- Main setup function
function M.setup()
	-- Apply on colorscheme change
	vim.api.nvim_create_autocmd("ColorScheme", {
		pattern = "*",
		callback = function()
			vim.schedule(function()
				local colors = get_colors()
				apply_highlights(blink_cmp(colors))
				apply_highlights(pickers(colors))
				apply_highlights(plugins(colors))
				apply_highlights(statusline())
			end)
		end,
	})

	-- Apply immediately
	vim.schedule(function()
		local colors = get_colors()
		apply_highlights(blink_cmp(colors))
		apply_highlights(pickers(colors))
		apply_highlights(plugins(colors))
		apply_highlights(statusline())
	end)
end

return M
