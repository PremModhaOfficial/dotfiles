local utils = require("heirline.utils")
local conditions = require("heirline.conditions")

-- Safe highlight getter
local function safe_hl(name, attr)
	local hl = utils.get_highlight(name)
	return hl and hl[attr] or (attr == "fg" and "#ffffff" or "#000000")
end

-- Visual separators
local LeftSlantStart = {
	provider = "",
	hl = function()
		return {
			fg = safe_hl("Normal", "bg"),
			bg = safe_hl("StatusLine", "bg"),
		}
	end,
}
local LeftSlantEnd = {
	provider = "",
	hl = function()
		return {
			fg = safe_hl("StatusLine", "bg"),
			bg = safe_hl("Normal", "bg"),
		}
	end,
}
local RightSlantStart = {
	provider = "",
	hl = function()
		return {
			fg = safe_hl("StatusLine", "bg"),
			bg = safe_hl("Normal", "bg"),
		}
	end,
}
local RightSlantEnd = {
	provider = "",
	hl = function()
		return {
			fg = safe_hl("Normal", "bg"),
			bg = safe_hl("StatusLine", "bg"),
		}
	end,
}

-- Mode indicator
local VimMode = {
	init = function(self)
		self.mode = vim.fn.mode(1)
		local mode_char = self.mode:sub(1, 1)
		local colors = self.mode_colors()
		self.mode_color = colors[mode_char] or safe_hl("Normal", "fg")
	end,
	update = {
		"ModeChanged",
		pattern = "*:*",
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
			return " %2(" .. self.mode_names[self.mode] .. "%) "
		end,
		hl = function(self)
			return { fg = safe_hl("Normal", "bg"), bg = self.mode_color }
		end,
	},
	{
		provider = "",
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
		LeftSlantStart,
		{
			provider = function(self)
				return "  " .. (self.status_dict.head == "" and "main" or self.status_dict.head) .. " "
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
					bg = safe_hl("StatusLine", "bg"),
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
						bg = safe_hl("StatusLine", "bg"),
					}
				end,
			},
		},
		LeftSlantEnd,
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
		LeftSlantStart,
		{
			provider = function(self)
				local filepath = vim.fn.fnamemodify(self.filename, ":~:.")
				if filepath == "" then
					return " [No Name] "
				end
				-- Smart truncation for long paths
				if #filepath > 50 then
					filepath = "..." .. filepath:sub(-47)
				end
				return " " .. filepath .. " "
			end,
			hl = function()
				return {
					fg = safe_hl("Directory", "fg"),
					bg = safe_hl("StatusLine", "bg"),
				}
			end,
			on_click = {
				callback = function()
					Snacks.picker.files()
				end,
				name = "sl_filepath_click",
			},
		},
		LeftSlantEnd,
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
	update = { "DiagnosticChanged", "BufEnter" },
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
				provider = "",
			},
			{
				provider = function(self)
					local sign = vim.fn.sign_getdefined("DiagnosticSignError")[1]
					return (sign and sign.text or "E") .. self.errors
				end,
			},
			{
				provider = "",
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
				provider = "",
			},
			{
				provider = function(self)
					local sign = vim.fn.sign_getdefined("DiagnosticSignWarn")[1]
					return (sign and sign.text or "W") .. self.warnings
				end,
			},
			{
				provider = "",
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

-- LSP attached indicator
local LspAttached = {
	condition = conditions.lsp_attached,
	static = {
		lsp_attached = false,
		show_lsps = {
			copilot = false,
			efm = false,
		},
	},
	init = function(self)
		for i, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
			if self.show_lsps[server.name] ~= false then
				self.lsp_attached = true
				return
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
			return self.lsp_attached
		end,
		LeftSlantStart,
		{
			provider = "  ",
			hl = function()
				return {
					fg = safe_hl("Comment", "fg"),
					bg = safe_hl("StatusLine", "bg"),
				}
			end,
		},
		LeftSlantEnd,
	},
}

-- Position and ruler
local Ruler = {
	condition = function(self)
		return not conditions.buffer_matches({
			filetype = self.filetypes,
		})
	end,
	{
		provider = "",
		hl = function()
			return {
				fg = safe_hl("Comment", "fg"),
				bg = safe_hl("Normal", "bg"),
			}
		end,
	},
	{
		provider = " %l:%c %P%/%L ",
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
		provider = " ",
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

-- File type and encoding
local FileType = {
	condition = function(self)
		return not conditions.buffer_matches({
			filetype = self.filetypes,
		})
	end,
	RightSlantStart,
	{
		provider = function()
			return " " .. string.lower(vim.bo.filetype) .. " "
		end,
		hl = function()
			return {
				fg = safe_hl("Comment", "fg"),
				bg = safe_hl("StatusLine", "bg"),
			}
		end,
	},
	RightSlantEnd,
}

local FileEncoding = {
	condition = function(self)
		return not conditions.buffer_matches({
			filetype = self.filetypes,
		})
	end,
	RightSlantStart,
	{
		provider = function()
			local enc = (vim.bo.fenc ~= "" and vim.bo.fenc) or vim.o.enc
			return " " .. enc .. " "
		end,
		hl = function()
			return {
				fg = safe_hl("Comment", "fg"),
				bg = safe_hl("StatusLine", "bg"),
			}
		end,
	},
	RightSlantEnd,
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
		GitBranch,
		FilePath,
		LspAttached,
		LspDiagnostics,
		{ provider = "%=" },
		CodeCompanionAgent,
		CodeCompanion,
		FileType,
		FileEncoding,
		Ruler,
	},
}

return statusline

