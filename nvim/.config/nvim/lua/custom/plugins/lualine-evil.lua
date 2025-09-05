return {
	"nvim-lualine/lualine.nvim",
	enabled = false,
	dependencies = { "nvim-tree/nvim-web-devicons" },

	config = function()
		-- Eviline config for lualine
		-- Author: shadmansaleh
		-- Credit: glepnir
		local lualine = require("lualine")

		-- Spacemacs-inspired color scheme
		-- stylua: ignore
		local colors = {
			-- Spacemacs-inspired colors
			bg       = '#292b2e',  -- Dark background
			fg       = '#b2b2b2',  -- Light foreground
			yellow   = '#b58900',  -- Solarized yellow
			cyan     = '#2aa198',  -- Solarized cyan
			darkblue = '#073642',  -- Solarized base02
			green    = '#859900',  -- Solarized green
			orange   = '#cb4b16',  -- Solarized orange
			violet   = '#6c71c4',  -- Solarized violet
			magenta  = '#d33682',  -- Solarized magenta
			blue     = '#268bd2',  -- Solarized blue
			red      = '#dc322f',  -- Solarized red
			-- Additional colors for better contrast
			light_bg = '#3c3f41',
			dark_fg  = '#657b83',
		}

		local conditions = {
			buffer_not_empty = function()
				return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
			end,
			hide_in_width = function()
				return vim.fn.winwidth(0) > 80
			end,
			check_git_workspace = function()
				local filepath = vim.fn.expand("%:p:h")
				local gitdir = vim.fn.finddir(".git", filepath .. ";")
				return gitdir and #gitdir > 0 and #gitdir < #filepath
			end,
		}

		-- Spacemacs-inspired config
		local config = {
			options = {
				-- Spacemacs-style separators
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				theme = {
					-- Spacemacs-inspired theme
					normal = {
						a = { fg = colors.bg, bg = colors.blue, gui = "bold" },
						b = { fg = colors.fg, bg = colors.light_bg },
						c = { fg = colors.fg, bg = colors.bg },
					},
					insert = {
						a = { fg = colors.bg, bg = colors.green, gui = "bold" },
						b = { fg = colors.fg, bg = colors.light_bg },
						c = { fg = colors.fg, bg = colors.bg },
					},
					visual = {
						a = { fg = colors.bg, bg = colors.magenta, gui = "bold" },
						b = { fg = colors.fg, bg = colors.light_bg },
						c = { fg = colors.fg, bg = colors.bg },
					},
					replace = {
						a = { fg = colors.bg, bg = colors.red, gui = "bold" },
						b = { fg = colors.fg, bg = colors.light_bg },
						c = { fg = colors.fg, bg = colors.bg },
					},
					command = {
						a = { fg = colors.bg, bg = colors.yellow, gui = "bold" },
						b = { fg = colors.fg, bg = colors.light_bg },
						c = { fg = colors.fg, bg = colors.bg },
					},
					inactive = {
						a = { fg = colors.dark_fg, bg = colors.bg, gui = "bold" },
						b = { fg = colors.dark_fg, bg = colors.bg },
						c = { fg = colors.dark_fg, bg = colors.bg },
					},
				},
				globalstatus = false,
			},
			sections = {
				-- Spacemacs-style sections
				lualine_a = {},
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},
		}

		-- Spacemacs-style component insertion functions
		local function ins_a(component)
			table.insert(config.sections.lualine_a, component)
		end

		local function ins_b(component)
			table.insert(config.sections.lualine_b, component)
		end

		local function ins_c(component)
			table.insert(config.sections.lualine_c, component)
		end

		local function ins_x(component)
			table.insert(config.sections.lualine_x, component)
		end

		local function ins_y(component)
			table.insert(config.sections.lualine_y, component)
		end

		local function ins_z(component)
			table.insert(config.sections.lualine_z, component)
		end

		-- Section C: Additional components
		ins_c({
			"searchcount",
			color = { fg = colors.cyan },
		})

		ins_c({
			"selectioncount",
			color = { fg = colors.orange },
		})

		-- Section B: File information
		ins_b({
			"filetype",
			icon_only = true,
			padding = { left = 1, right = 0 },
		})

		ins_b({
			"filename",
			cond = conditions.buffer_not_empty,
			color = { fg = colors.fg, gui = "bold" },
			padding = { left = 0, right = 1 },
		})

		ins_b({
			"filesize",
			cond = conditions.buffer_not_empty,
		})

		ins_b({
			"filetype",
			icon_only = true,
			padding = { left = 1, right = 0 },
		})

		ins_c({
			function()
				local clients = vim.lsp.get_clients({ bufnr = 0 })
				if #clients > 0 then
					local names = {}
					for _, client in ipairs(clients) do
						table.insert(names, client.name)
					end
					return table.concat(names, ", ")
				end
				return ""
			end,
			icon = "",
			color = { fg = colors.blue },
			cond = function()
				return #vim.lsp.get_clients({ bufnr = 0 }) > 0
			end,
		})

		ins_z({ "location" })

		-- Section C: Diagnostics and additional info
		ins_c({
			"diagnostics",
			sources = { "nvim_lsp" },
			sections = { "error", "warn", "info", "hint" },
			symbols = {
				error = "✗ ",
				warn = "⚠ ",
				info = "ℹ ",
				hint = "💡 ",
			},
			diagnostics_color = {
				error = { fg = colors.red },
				warn = { fg = colors.yellow },
				info = { fg = colors.cyan },
				hint = { fg = colors.blue },
			},
			colored = true,
			update_in_insert = false,
			always_visible = false,
		})

		ins_c({
			function()
				local clients = vim.lsp.get_clients({ bufnr = 0 })
				if #clients > 0 then
					local names = {}
					for _, client in ipairs(clients) do
						table.insert(names, client.name)
					end
					return table.concat(names, ", ")
				end
				return ""
			end,
			icon = "",
			color = { fg = colors.blue },
			cond = function()
				return #vim.lsp.get_clients({ bufnr = 0 }) > 0
			end,
		})

		-- Insert mid section. You can make any number of sections in neovim :)
		-- for lualine it's any number greater then 2
		-- Section A: Mode (Spacemacs style)
		ins_a({
			-- mode component with Spacemacs-style icons
			function()
				local mode_icons = {
					n = "NORMAL",
					i = "INSERT",
					v = "VISUAL",
					[""] = "V-BLOCK",
					V = "V-LINE",
					c = "COMMAND",
					no = "NORMAL",
					s = "SELECT",
					S = "S-LINE",
					[""] = "S-BLOCK",
					ic = "I-COMP",
					R = "REPLACE",
					Rv = "V-REPLACE",
					cv = "VIM-EX",
					ce = "EX",
					r = "PROMPT",
					rm = "MORE",
					["r?"] = "CONFIRM",
					["!"] = "SHELL",
					t = "TERMINAL",
				}
				return mode_icons[vim.fn.mode()] or "UNKNOWN"
			end,
			padding = { left = 1, right = 1 },
		})

		-- Section X: File encoding and format
		ins_x({
			"fileformat",
			fmt = string.upper,
			icons_enabled = true,
			color = { fg = colors.green },
			cond = conditions.hide_in_width,
		})

		ins_x({
			"o:encoding",
			fmt = string.upper,
			color = { fg = colors.green },
			cond = conditions.hide_in_width,
		})

		-- Section Z: Position and CodeCompanion
		ins_z({
			"location",
			color = { fg = colors.fg },
		})

		ins_z({
			"progress",
			color = { fg = colors.fg },
		})

		ins_z({
			function()
				if package.loaded["codecompanion"] then
					local ok, status = pcall(require("codecompanion").status)
					return ok and status or ""
				end
				return ""
			end,
			cond = function()
				return package.loaded["codecompanion"] ~= nil
			end,
			color = { fg = colors.blue },
		})

		ins_z({
			function()
				local ok, result = pcall(require, "custom.code.codecompanion_ui.lualine")
				return ok and result or ""
			end,
			cond = function()
				return pcall(require, "custom.code.codecompanion_ui.lualine")
			end,
		})
		-- Section Y: Git information
		ins_y({
			"branch",
			icon = "",
			color = { fg = colors.violet },
			cond = conditions.hide_in_width,
		})

		ins_y({
			"diff",
			symbols = { added = "+", modified = "~", removed = "-" },
			diff_color = {
				added = { fg = colors.green },
				modified = { fg = colors.orange },
				removed = { fg = colors.red },
			},
			cond = conditions.hide_in_width,
		})

		ins_z({
			function()
				return ""
			end,
			color = { fg = colors.blue },
			padding = { left = 0 },
		})

		-- Now don't forget to initialize lualine
		lualine.setup(config)
	end,
}
