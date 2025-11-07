local utils = require("heirline.utils")
local conditions = require("heirline.conditions")

-- Optimized safe highlight getter with caching
local hl_cache = {}
local function safe_hl(name, attr)
	local key = name .. "_" .. attr
	if hl_cache[key] then
		return hl_cache[key]
	end

	local hl = utils.get_highlight(name)
	local result = hl and hl[attr] or (attr == "fg" and "#ffffff" or "#000000")
	hl_cache[key] = result
	return result
end

-- Clear cache when colors change
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		hl_cache = {}
	end,
})

-- Simple pattern component for middle section
local MiddlePattern = {
	provider = " ", -- Simple space for performance
	hl = function()
		return {
			fg = safe_hl("Comment", "fg"),
			bg = safe_hl("Normal", "bg"),
		}
	end,
}

-- Nixie tube progress bar (9 segments)
local NixieProgressBar = {
	condition = function(self)
		return not conditions.buffer_matches({
			filetype = self.filetypes,
		})
	end,
	provider = function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local total_lines = vim.api.nvim_buf_line_count(0)
		local ratio = line / total_lines
		local segments = math.floor(ratio * 9 + 0.5)
		local filled = string.rep("▓", segments)
		local empty = string.rep("░", 9 - segments)
		return filled .. empty .. " "
	end,
	hl = function()
		return {
			fg = "#ff8800", -- Warm orange glow
			bg = safe_hl("Normal", "bg"),
		}
	end,
	update = { "CursorMoved", "CursorMovedI" },
}

-- Mode indicator with Nixie tube label
local VimMode = {
	init = function(self)
		self.mode = vim.fn.mode(1)
		local mode_char = self.mode:sub(1, 1)
		local colors = self.mode_colors()
		self.mode_color = colors[mode_char] or safe_hl("Normal", "fg")
	end,
	update = {
		"ModeChanged",
		callback = vim.schedule_wrap(function()
			vim.cmd("redrawstatus")
		end),
	},
	static = {
		mode_names = {
			n = "NORMAL",
			no = "NORMAL",
			nov = "NORMAL",
			noV = "NORMAL",
			["no\22"] = "NORMAL",
			niI = "NORMAL",
			niR = "NORMAL",
			niV = "NORMAL",
			nt = "NORMAL",
			v = "VISUAL",
			vs = "VISUAL",
			V = "VISUAL",
			Vs = "VISUAL",
			["\22"] = "VISUAL",
			["\22s"] = "VISUAL",
			s = "SELECT",
			S = "SELECT",
			["\19"] = "SELECT",
			i = "INSERT",
			ic = "INSERT",
			ix = "INSERT",
			R = "REPLACE",
			Rc = "REPLACE",
			Rx = "REPLACE",
			Rv = "REPLACE",
			Rvc = "REPLACE",
			Rvx = "REPLACE",
			c = "COMMAND",
			cv = "Ex",
			r = "...",
			rm = "M",
			["r?"] = "?",
			["!"] = "!",
			t = "TERM",
		},
		mode_colors = function()
			return {
				n = safe_hl("Function", "fg"),
				i = safe_hl("String", "fg"),
				v = safe_hl("Constant", "fg"),
				V = safe_hl("Constant", "fg"),
				["\22"] = safe_hl("Constant", "fg"),
				c = safe_hl("Statement", "fg"),
				s = safe_hl("Type", "fg"),
				S = safe_hl("Type", "fg"),
				["\19"] = safe_hl("Type", "fg"),
				r = safe_hl("String", "fg"),
				R = safe_hl("String", "fg"),
				["!"] = safe_hl("Error", "fg"),
				t = safe_hl("Error", "fg"),
			}
		end,
	},
	{
		provider = function(self)
			return "┏IN-12┫ " .. self.mode_names[self.mode] .. " "
		end,
		hl = function(self)
			return { fg = safe_hl("Normal", "bg"), bg = self.mode_color }
		end,
	},
	{
		provider = "┣",
		hl = function(self)
			return { fg = self.mode_color, bg = safe_hl("Normal", "bg") }
		end,
	},
}

-- Git branch information
local GitBranch = {
	condition = conditions.is_git_repo,
	init = function(self)
		self.status_dict = vim.b.gitsigns_status_dict
	end,
	{
		condition = function(self)
			return not conditions.buffer_matches({
				filetype = self.filetypes,
			})
		end,
		{
			provider = function(self)
				return "┫  " .. (self.status_dict.head == "" and "main" or self.status_dict.head) .. " "
			end,
			on_click = {
				callback = function()
					Snacks.picker.git_branches()
				end,
				name = "sl_git_click",
			},
			hl = function()
				return {
					fg = safe_hl("Comment", "fg"),
					bg = safe_hl("Normal", "bg"),
				}
			end,
		},
		{
			condition = function(self)
				return self.status_dict.added ~= 0 or self.status_dict.changed ~= 0 or self.status_dict.removed ~= 0
			end,
			{
				provider = function(self)
					local added = self.status_dict.added or 0
					local changed = self.status_dict.changed or 0
					local removed = self.status_dict.removed or 0
					return string.format("+%d ~%d -%d ", added, changed, removed)
				end,
				hl = function()
					return {
						fg = safe_hl("diffAdded", "fg"),
						bg = safe_hl("Normal", "bg"),
					}
				end,
			},
		},
	},
}

-- File path display
local FilePath = {
	condition = function(self)
		return not conditions.buffer_matches({
			filetype = self.filetypes,
		})
	end,
	init = function(self)
		self.filename = vim.api.nvim_buf_get_name(0)
	end,
	{
		{
			provider = function(self)
				local filepath = vim.fn.fnamemodify(self.filename, ":~:.")
				if filepath == "" then
					return "┣[No Name]"
				end
				-- Smart truncation for long paths
				if #filepath > 50 then
					filepath = "..." .. filepath:sub(-47)
				end
				return "┣" .. filepath
			end,
			hl = function()
				return {
					fg = safe_hl("Directory", "fg"),
					bg = safe_hl("Normal", "bg"),
				}
			end,
			on_click = {
				callback = function()
					Snacks.picker.files()
				end,
				name = "sl_filepath_click",
			},
		},
		{
			provider = "┫ ",
			hl = function()
				return {
					fg = safe_hl("Directory", "fg"),
					bg = safe_hl("Normal", "bg"),
				}
			end,
		},
	},
}

-- LSP diagnostics
local LspDiagnostics = {
	condition = conditions.has_diagnostics,
	init = function(self)
		self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
		self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
		self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
		self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
	end,
	on_click = {
		callback = function()
			Snacks.picker.diagnostics()
		end,
		name = "sl_diagnostics_click",
	},
	update = { "DiagnosticChanged" },
	-- Errors
	{
		condition = function(self)
			return self.errors > 0
		end,
		hl = function()
			return {
				fg = safe_hl("Normal", "bg"),
				bg = safe_hl("DiagnosticError", "fg"),
			}
		end,
		{
			{
				provider = "▌",
			},
			{
				provider = function(self)
					local sign = vim.fn.sign_getdefined("DiagnosticSignError")[1]
					return (sign and sign.text or "E") .. self.errors
				end,
			},
			{
				provider = "▐",
				hl = function()
					return {
						fg = safe_hl("DiagnosticError", "fg"),
						bg = safe_hl("Normal", "bg"),
					}
				end,
			},
		},
	},
	-- Warnings
	{
		condition = function(self)
			return self.warnings > 0
		end,
		hl = function()
			return {
				fg = safe_hl("Normal", "bg"),
				bg = safe_hl("DiagnosticWarn", "fg"),
			}
		end,
		{
			{
				provider = "▌",
			},
			{
				provider = function(self)
					local sign = vim.fn.sign_getdefined("DiagnosticSignWarn")[1]
					return (sign and sign.text or "W") .. self.warnings
				end,
			},
			{
				provider = "▐ ",
				hl = function()
					return {
						fg = safe_hl("DiagnosticWarn", "fg"),
						bg = safe_hl("Normal", "bg"),
					}
				end,
			},
		},
	},
}

-- LSP attached indicator with server names
local LspAttached = {
	condition = conditions.lsp_attached,
	static = {
		lsp_attached = false,
		server_names = {},
		show_lsps = {
			copilot = false,
			efm = false,
		},
	},
	init = function(self)
		self.server_names = {}
		for i, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
			if self.show_lsps[server.name] ~= false then
				table.insert(self.server_names, server.name)
				self.lsp_attached = true
			end
		end
	end,
	update = { "LspAttach", "LspDetach" },
	on_click = {
		callback = function()
			vim.defer_fn(function()
				vim.cmd("LspInfo")
			end, 100)
		end,
		name = "sl_lsp_click",
	},
	{
		condition = function(self)
			return self.lsp_attached and #self.server_names > 0
		end,
		{
			provider = function(self)
				local servers = table.concat(self.server_names, ",")
				return "┣" .. servers .. "┫ "
			end,
			hl = function()
				return {
					fg = safe_hl("Comment", "fg"),
					bg = safe_hl("Normal", "bg"),
				}
			end,
		},
	},
}

-- Position and ruler with encoding
local Ruler = {
	condition = function(self)
		return not conditions.buffer_matches({
			filetype = self.filetypes,
		})
	end,
	{
		provider = function()
			local enc = (vim.bo.fenc ~= "" and vim.bo.fenc) or vim.o.enc
			local line = vim.api.nvim_win_get_cursor(0)[1]
			local total_lines = vim.api.nvim_buf_line_count(0)
			local col = vim.api.nvim_win_get_cursor(0)[2] + 1
			
			-- Position indicator
			local pos_indicator
			if total_lines == 1 then
				pos_indicator = "All"
			elseif line == 1 then
				pos_indicator = "Top"
			elseif line == total_lines then
				pos_indicator = "Bot"
			else
				local ratio = line / total_lines
				if ratio < 0.33 then
					pos_indicator = "Top"
				elseif ratio > 0.67 then
					pos_indicator = "Bot"
				else
					pos_indicator = "Mid"
				end
			end
			
			-- Dynamic dial - moves right as you scroll down (9 positions)
			local ratio = line / total_lines
			local dial_pos = math.floor(ratio * 8 + 0.5) -- 0-8 positions
			local dial_left = string.rep("═", dial_pos)
			local dial_right = string.rep("═", 8 - dial_pos)
			local dial = dial_left .. "╣" .. dial_right .. "═"
			
			return string.format("▌%d▐ %s ▌%d:%d▐ %s %s", total_lines, enc, line, col, pos_indicator, dial)
		end,
		hl = function()
			return {
				fg = safe_hl("Normal", "bg"),
				bg = safe_hl("Comment", "fg"),
			}
		end,
		on_click = {
			callback = function()
				local line = vim.api.nvim_win_get_cursor(0)[1]
				local total_lines = vim.api.nvim_buf_line_count(0)

				if math.floor((line / total_lines)) > 0.5 then
					vim.cmd("normal! gg")
				else
					vim.cmd("normal! G")
				end
			end,
			name = "sl_ruler_click",
		},
	},
}

-- AI agents
local CodeCompanion = {
	static = {
		processing = false,
	},
	update = {
		"User",
		pattern = "CodeCompanionRequest*",
		callback = function(self, args)
			if args.match == "CodeCompanionRequestStarted" then
				self.processing = true
			elseif args.match == "CodeCompanionRequestFinished" then
				self.processing = false
			end
			vim.cmd("redrawstatus")
		end,
	},
	{
		condition = function(self)
			return self.processing
		end,
		provider = " ",
		hl = function()
			return { fg = safe_hl("WarningMsg", "fg") }
		end,
	},
}

local CodeCompanionAgent = {
	static = {
		processing = false,
	},
	update = {
		"User",
		pattern = "CodeCompanionAgent*",
		callback = function(self, args)
			if args.match == "CodeCompanionAgentStarted" then
				self.processing = true
			elseif args.match == "CodeCompanionAgentFinished" then
				self.processing = false
			end
			vim.cmd("redrawstatus")
		end,
	},
	{
		condition = function(self)
			return self.processing
		end,
		provider = "󱙺 ",
		hl = function()
			return { fg = safe_hl("diffAdded", "fg") }
		end,
	},
}

-- Macro recording indicator
local MacroRec = {
	condition = function()
		return vim.fn.reg_recording() ~= ""
	end,
	update = {
		"RecordingEnter",
		"RecordingLeave",
	},
	{
		provider = function()
			return "┫ 󱎘 @" .. vim.fn.reg_recording() .. " ┣"
		end,
		hl = function()
			return {
				fg = safe_hl("Comment", "fg"),
				bg = safe_hl("Normal", "bg"),
				bold = true,
			}
		end,
	},
}

-- File type with icons
local FileType = {
	condition = function(self)
		return not conditions.buffer_matches({
			filetype = self.filetypes,
		})
	end,
	static = {
		-- Common filetype icons (warm orange glow theme)
		icons = {
			lua = "󰢱",
			python = "",
			javascript = "",
			typescript = "",
			rust = "",
			go = "",
			java = "",
			c = "",
			cpp = "",
			html = "",
			css = "",
			json = "",
			yaml = "",
			markdown = "",
			vim = "",
			sh = "",
			bash = "",
			zsh = "",
		},
	},
	{
		provider = function(self)
			local ft = string.lower(vim.bo.filetype)
			local icon = self.icons[ft] or "󱙺"
			return "┣" .. icon .. " " .. ft .. "┫ "
		end,
		hl = function()
			return {
				fg = safe_hl("Comment", "fg"),
				bg = safe_hl("Normal", "bg"),
			}
		end,
	},
}

-- Main statusline
local statusline = {
	static = {
		filetypes = {
			"^git.*",
			"fugitive",
			"alpha",
			"^neo--tree$",
			"^neotest--summary$",
			"^neo--tree--popup$",
			"^NvimTree$",
			"snacks_dashboard",
			"^toggleterm$",
		},
		force_inactive_filetypes = {
			"^aerial$",
			"^alpha$",
			"^chatgpt$",
			"^frecency$",
			"^lazy$",
			"^lazyterm$",
			"^netrw$",
			"^TelescopePrompt$",
			"^undotree$",
		},
	},
	condition = function(self)
		return not conditions.buffer_matches({
			filetype = self.force_inactive_filetypes,
		})
	end,
	{
		VimMode,
		NixieProgressBar,
		GitBranch,
		FilePath,
		FileType,
		LspDiagnostics,
		{ provider = "%=" },
		CodeCompanionAgent,
		CodeCompanion,
		MacroRec,
		LspAttached,
		Ruler,
	},
}

return statusline
