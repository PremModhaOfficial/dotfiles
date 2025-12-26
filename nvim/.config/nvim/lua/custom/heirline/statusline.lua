local utils = require("heirline.utils")
local conditions = require("heirline.conditions")

--------------------------------------------------------------------------------
-- UTILS: HEX COLOR DIMMER
--------------------------------------------------------------------------------
local function dim_hex(hex, factor)
	if type(hex) == "number" then
		hex = string.format("#%06x", hex)
	end
	if not hex or type(hex) ~= "string" or hex == "NONE" or hex:sub(1,1) ~= "#" then return hex end
	local r = tonumber(hex:sub(2, 3), 16) or 255
	local g = tonumber(hex:sub(4, 5), 16) or 255
	local b = tonumber(hex:sub(6, 7), 16) or 255
	r = math.floor(r * factor)
	g = math.floor(g * factor)
	b = math.floor(b * factor)
	return string.format("#%02x%02x%02x", r, g, b)
end

--------------------------------------------------------------------------------
-- PERFORMANCE CORE
--------------------------------------------------------------------------------

local Core = {
	state = {
		last_act = vim.loop.now(), -- Activity timestamp
		is_dimmed = false,
		
		mode = { name = "NORMAL", color = "#ffffff", char = "n" },
		git = { branch = "main", added = 0, changed = 0, removed = 0, exists = false },
		diagnostics = { errors = 0, warnings = 0, has_any = false },
		
		-- LSP State with Boot Sequence
		lsp = { 
			active = false, 
			servers = {}, -- list of names
			boot = {}, -- table { "lua_ls" = 0..100 }
			progress = false 
		},
		
		-- Search with "Roller" effect
		search = { 
			count = 0, total = 0, active = false,
			display_count = 0, display_total = 0 -- For animation
		},
		
		harpoon = { count = 0, string = "", active = false },
		
		nixie = {
			mode = "IDLE", 
			segments = 0,
			color = "#555555",
			label = "",
			wave_pattern = "⎯⎯⎯⎯⎯⎯⎯",
		},
	},
	hl_cache = {},
}

-- Optimized & Dimmable Highlight Getter
function Core.get_hl(name, attr)
	local key = name .. "_" .. attr .. (Core.state.is_dimmed and "_dim" or "")
	if Core.hl_cache[key] then return Core.hl_cache[key] end
	
	local hl = utils.get_highlight(name)
	local result = hl and hl[attr] or (attr == "fg" and "#ffffff" or "#000000")
	
	-- Apply dimming if active
	if Core.state.is_dimmed and attr == "fg" then
		result = dim_hex(result, 0.4) -- Dim to 40% brightness
	end
	
	Core.hl_cache[key] = result
	return result
end

-- Clear cache on theme change
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function() Core.hl_cache = {} end,
})

--------------------------------------------------------------------------------
-- CONTROLLER: EVENT LISTENERS
--------------------------------------------------------------------------------

-- 0. Activity Tracker (Focus Breather)
local function interact()
	Core.state.last_act = vim.loop.now()
	if Core.state.is_dimmed then
		Core.state.is_dimmed = false
		Core.hl_cache = {} -- Clear cache to restore brightness
		vim.cmd("redrawstatus")
	end
end
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter", "TextChanged", "CmdlineEnter" }, { 
	callback = interact 
})

-- 1. Mode Listener
local ModeNames = {
	n = "NORMAL", i = "INSERT", v = "VISUAL", V = "VISUAL", ["\22"] = "VISUAL",
	c = "COMMAND", s = "SELECT", S = "SELECT", ["\19"] = "SELECT",
	R = "REPLACE", r = "...", ["!"] = "!", t = "TERM",
}
local function update_mode()
	local m = vim.fn.mode(1)
	local char = m:sub(1, 1)
	Core.state.mode.char = char
	Core.state.mode.name = ModeNames[m] or ModeNames[char] or "NORMAL"
	local color_map = {
		n = "Function", i = "String", v = "Constant", V = "Constant", ["\22"] = "Constant",
		c = "Statement", s = "Type", S = "Type", ["\19"] = "Type", R = "String", ["!"] = "Error", t = "Error"
	}
	Core.state.mode.color = Core.get_hl(color_map[char] or "Normal", "fg")
end
vim.api.nvim_create_autocmd("ModeChanged", { callback = update_mode })
update_mode()

-- 2. Git Listener
vim.api.nvim_create_autocmd("User", {
	pattern = "GitSignsUpdate",
	callback = function()
		local dict = vim.b.gitsigns_status_dict
		if dict then
			Core.state.git.exists = true
			Core.state.git.branch = (dict.head == "" and "main" or dict.head)
			Core.state.git.added = dict.added or 0
			Core.state.git.changed = dict.changed or 0
			Core.state.git.removed = dict.removed or 0
		else
			Core.state.git.exists = false
		end
		vim.cmd("redrawstatus")
	end,
})

-- 3. Diagnostic Listener
local function update_diagnostics()
	local err = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
	local warn = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
	Core.state.diagnostics.errors = err
	Core.state.diagnostics.warnings = warn
	Core.state.diagnostics.has_any = (err + warn) > 0
end
vim.api.nvim_create_autocmd("DiagnosticChanged", { callback = update_diagnostics })

-- 4. LSP Listener (With Boot Detection)
vim.api.nvim_create_autocmd({ "LspProgress", "LspAttach", "LspDetach" }, {
	callback = function(args)
		local clients = vim.lsp.get_clients({ bufnr = 0 })
		local names = {}
		local is_progress = false
		
		for _, client in ipairs(clients) do
			table.insert(names, client.name)
			-- Init boot state if new
			if not Core.state.lsp.boot[client.name] then
				Core.state.lsp.boot[client.name] = 0
			end
			
			if client.progress and client.progress.pending and next(client.progress.pending) then
				is_progress = true
			end
		end
		
		Core.state.lsp.active = (#names > 0)
		Core.state.lsp.servers = names
		Core.state.lsp.progress = is_progress
		if is_progress then vim.cmd("redrawstatus") end
	end
})

-- 5. Harpoon Listener
local function update_harpoon()
	if not package.loaded["harpoon"] then return end
	local list = require("harpoon"):list()
	local count = list:length()
	local labels = { "J", "K", "L", ";" }
	local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
	local out = ""
	
	for i, item in ipairs(list.items) do
		local label = labels[i] or tostring(i)
		if item.value == current then
			out = out .. "[" .. label .. "]"
		else
			out = out .. label
		end
	end
	
	Core.state.harpoon.count = count
	Core.state.harpoon.string = "┣󰛢" .. out .. "┫"
	Core.state.harpoon.active = (count > 0)
end
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, { callback = update_harpoon })


--------------------------------------------------------------------------------
-- ANIMATION SYSTEM (PHYSICS ENGINE)
--------------------------------------------------------------------------------

local Animation = {
	timer = vim.loop.new_timer(),
	density = { " ", "░", "▒", "▓", "█" },
}

Animation.timer:start(0, 80, vim.schedule_wrap(function()
	local now = vim.loop.now()
	local s = Core.state.nixie
	local d = Core.state.diagnostics
	local lsp = Core.state.lsp
	local dirty = false
	
	-- A. FOCUS BREATHER (Dimming Check)
	if not Core.state.is_dimmed and (now - Core.state.last_act > 5000) then
		Core.state.is_dimmed = true
		Core.hl_cache = {} -- Clear cache to force dim colors
		dirty = true
	end

	-- B. SEARCH STATE (Combination Lock Roll)
	if vim.v.hlsearch == 1 and vim.fn.searchcount then
		if now % 500 < 80 then 
			local res = vim.fn.searchcount({ recompute = 1, maxcount = 999 })
			if res.total > 0 then
				Core.state.search.active = true
				Core.state.search.count = res.current
				Core.state.search.total = res.total
			else
				Core.state.search.active = false
			end
		end
	else
		Core.state.search.active = false
	end
	
	if Core.state.search.active then
		-- Roll the numbers towards target
		local cur = Core.state.search.display_count
		local tgt = Core.state.search.count
		if cur ~= tgt then
			-- Step size proportional to difference (Zeno's slide)
			local step = math.ceil(math.abs(tgt - cur) * 0.2)
			if cur < tgt then cur = cur + step else cur = cur - step end
			Core.state.search.display_count = cur
			dirty = true
		end
		
		-- Also roll total
		local t_cur = Core.state.search.display_total
		local t_tgt = Core.state.search.total
		if t_cur ~= t_tgt then
			local step = math.ceil(math.abs(t_tgt - t_cur) * 0.2)
			if t_cur < t_tgt then t_cur = t_cur + step else t_cur = t_cur - step end
			Core.state.search.display_total = t_cur
			dirty = true
		end
	end

	-- C. LSP BOOT SEQUENCE
	if lsp.active then
		for name, progress in pairs(lsp.boot) do
			if progress < 100 then
				-- Increment boot progress
				lsp.boot[name] = math.min(100, progress + 4) -- +4% per 80ms (~2s boot)
				dirty = true
			end
		end
	end
	
	-- D. HARPOON POLLING
	if package.loaded["harpoon"] then
		local h_count = require("harpoon"):list():length()
		if h_count ~= Core.state.harpoon.count then
			update_harpoon()
			dirty = true
		end
	end

	-- E. MAIN NIXIE STATE
	if Core.state.search.active then
		s.mode = "SEARCH"
		s.color = "#00ff00"
		local ratio = Core.state.search.display_count / math.max(1, Core.state.search.display_total)
		s.segments = math.min(9, math.floor(ratio * 9))
		s.label = string.format(" %d/%d", Core.state.search.display_count, Core.state.search.display_total)

	elseif lsp.progress then
		s.mode = "LSP"
		s.color = "#bb00ff"
		s.label = " LSP"
		-- Liquid Metal Shader
		local t = now / 300
		local p = ""
		for i = 1, 10 do
			local y = math.sin(t + (i * 0.4)) + math.sin(t * 1.7 + (i * 0.2)) 
			local idx = math.floor((y + 2) / 4 * 5) + 1
			idx = math.max(1, math.min(5, idx))
			p = p .. Animation.density[idx]
		end
		s.wave_pattern = p
		dirty = true

	elseif d.has_any then
		s.mode = "DIAGNOSTIC"
		local pulse = (d.errors > 0) and (math.floor(now / 150) % 2) or 0
		local base = math.min(9, math.floor(((d.errors + d.warnings) / 5) * 9))
		s.segments = math.max(1, base + pulse)
		s.color = (d.errors > 0) and "#ff0000" or "#ffaa00"
		s.label = string.format(" E%d W%d", d.errors, d.warnings)

	elseif vim.bo.modified then
		s.mode = "MODIFIED"
		local pulse = math.floor(math.abs(math.sin(now / 400)) * 2)
		local tick = math.min(9, math.floor((vim.b.changedtick or 0) / 10))
		s.segments = math.min(9, tick + pulse)
		s.color = "#ff8800"
		s.label = " *"

	else
		s.mode = "IDLE"
		-- Heartbeat Capacitor
		local cycle = 3000
		local t = now % cycle
		if t < 1000 then
			local pos = math.floor((t / 1000) * 9) + 1
			s.segments = pos
			dirty = true
		else
			if s.segments ~= 0 then dirty = true end
			s.segments = 0
		end
		s.color = Core.get_hl("Comment", "fg")
		s.label = ""
	end
	
	if dirty or s.mode ~= "IDLE" then
		vim.cmd("redrawstatus")
	end
end))


--------------------------------------------------------------------------------
-- COMPONENTS (THE VIEW)
--------------------------------------------------------------------------------

local VimMode = {
	init = function(self) self.mode = Core.state.mode end,
	{
		provider = "<|●|>",
		hl = function(self) return { fg = self.mode.color, bg = Core.get_hl("Normal", "bg"), bold = true } end,
	},
	{
		provider = "",
		hl = function(self) return { fg = self.mode.color, bg = Core.get_hl("Normal", "bg") } end,
	},
	{
		provider = function(self) return " " .. self.mode.name .. " " end,
		hl = function(self) return { fg = Core.get_hl("Normal", "bg"), bg = self.mode.color } end,
	},
	{
		provider = "┣",
		hl = function(self) return { fg = self.mode.color, bg = Core.get_hl("Normal", "bg") } end,
	},
}

local Nixie = {
	provider = function()
		local s = Core.state.nixie
		if s.mode == "LSP" then
			return "┣" .. s.wave_pattern .. "┫" .. s.label .. " "
		else
			local filled = string.rep("▓", s.segments)
			local empty = string.rep("░", 9 - s.segments)
			return "┣" .. filled .. empty .. "┫" .. s.label .. " "
		end
	end,
	hl = function()
		-- Apply dimming manually here since component uses direct hex
		local c = Core.state.nixie.color
		if Core.state.is_dimmed then c = dim_hex(c, 0.4) end
		return { fg = c, bg = Core.get_hl("Normal", "bg") }
	end
}

local Git = {
	condition = function() return Core.state.git.exists end,
	{
		provider = function() return "┫  " .. Core.state.git.branch .. " " end,
		hl = { fg = Core.get_hl("Comment", "fg") },
		on_click = { callback = function() Snacks.picker.git_branches() end, name = "sl_git" },
	},
	{
		condition = function() 
			local g = Core.state.git
			return g.added ~= 0 or g.changed ~= 0 or g.removed ~= 0 
		end,
		provider = function()
			local g = Core.state.git
			return string.format("+%d ~%d -%d ", g.added, g.changed, g.removed)
		end,
		hl = { fg = Core.get_hl("diffAdded", "fg") }
	}
}

local File = {
	init = function(self)
		self.filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
		self.ft = vim.bo.filetype
	end,
	{
		provider = function(self)
			local icon, color = require("nvim-web-devicons").get_icon_color(self.filename, self.ft)
			-- Apply dimming to devicon color
			if Core.state.is_dimmed and color then color = dim_hex(color, 0.4) end
			return "┣ " .. (icon or "󰈔") .. " "
		end,
		hl = function(self)
			local _, color = require("nvim-web-devicons").get_icon_color(self.filename, self.ft)
			if Core.state.is_dimmed and color then color = dim_hex(color, 0.4) end
			return { fg = color or "#ff8800", bg = Core.get_hl("Normal", "bg") }
		end,
	},
	{
		provider = function(self) return self.filename .. " ┫ " end,
		hl = { fg = Core.get_hl("Directory", "fg"), bg = Core.get_hl("Normal", "bg") },
	}
}

local Ruler = {
	provider = function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local total = vim.api.nvim_buf_line_count(0)
		local ratio = line / total
		local dial_pos = math.floor(ratio * 8 + 0.5)
		local left = string.rep("═", dial_pos)
		local right = string.rep("═", 8 - dial_pos)
		return string.format("[%d:%d] %s╣%s═", line, total, left, right)
	end,
	hl = function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local total = vim.api.nvim_buf_line_count(0)
		local r = line / total
		local c = (r < 0.33) and "#ffaa00" or ((r < 0.67) and "#ff6600" or "#ff0000")
		if Core.state.is_dimmed then c = dim_hex(c, 0.4) end
		return { fg = c, bold = true }
	end,
	on_click = {
		callback = function()
			local l = vim.api.nvim_win_get_cursor(0)[1]
			local t = vim.api.nvim_buf_line_count(0)
			vim.cmd((l/t > 0.5) and "normal! gg" or "normal! G")
		end,
		name = "sl_ruler"
	}
}

-- UPDATED: LSP INFO WITH BOOT BARS
local LspInfo = {
	condition = function() return Core.state.lsp.active end,
	provider = function() 
		local out = {}
		for _, name in ipairs(Core.state.lsp.servers) do
			local prog = Core.state.lsp.boot[name] or 100
			if prog < 100 then
				-- Render Boot Bar
				local len = math.floor(prog / 20) -- 0 to 5
				local bar = string.rep("▓", len) .. string.rep("░", 5 - len)
				table.insert(out, "[" .. bar .. "]")
			else
				table.insert(out, name)
			end
		end
		return "┣ " .. table.concat(out, "+") .. " ┫ " 
	end,
	hl = function()
		local c = "#00d7ff"
		if Core.state.is_dimmed then c = dim_hex(c, 0.4) end
		return { fg = c, bold = true }
	end,
	on_click = { callback = function() vim.cmd("LspInfo") end, name = "sl_lsp_info" }
}

local LazyUpdates = {
	condition = function() return require("lazy.status").has_updates() end,
	provider = function() return "┣ 󰮯 " .. require("lazy.status").updates() .. " ┫ " end,
	hl = { fg = "#ff00ff", bold = true },
}

local Harpoon = {
	condition = function() return Core.state.harpoon.active end,
	provider = function() return Core.state.harpoon.string end,
	hl = function()
		local c = "#00d7ff"
		if Core.state.is_dimmed then c = dim_hex(c, 0.4) end
		return { fg = c, bold = true }
	end
}

--------------------------------------------------------------------------------
-- ASSEMBLY
--------------------------------------------------------------------------------
local statusline = {
	static = {
		disabled_ft = { "^git.*", "fugitive", "alpha", "dashboard", "neo-tree", "toggleterm" }
	},
	condition = function(self)
		return not conditions.buffer_matches({ filetype = self.disabled_ft })
	end,
	{
		VimMode,
		Nixie,
		Git,
		Harpoon,
		File,
		{ provider = "%=" }, -- Spacer
		LazyUpdates,
		LspInfo,
		Ruler
	}
}

return statusline
