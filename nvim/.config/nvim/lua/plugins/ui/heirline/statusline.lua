local utils = require("heirline.utils")
local conditions = require("heirline.conditions")

--------------------------------------------------------------------------------
-- UTILS: HEX COLOR DIMMER
--------------------------------------------------------------------------------
local function dim_hex(hex, factor)
	if type(hex) == "number" then
		hex = string.format("#%06x", hex)
	end
	if not hex or type(hex) ~= "string" or hex == "NONE" or hex:sub(1, 1) ~= "#" then
		return hex
	end
	local r = tonumber(hex:sub(2, 3), 16) or 255
	local g = tonumber(hex:sub(4, 5), 16) or 255
	local b = tonumber(hex:sub(6, 7), 16) or 255
	r = math.floor(r * factor)
	g = math.floor(g * factor)
	b = math.floor(b * factor)
	return string.format("#%02x%02x%02x", r, g, b)
end

--------------------------------------------------------------------------------
-- UTILS: 1D NOISE (Organic animation driver)
--------------------------------------------------------------------------------
local function noise1d(x)
	local i = math.floor(x)
	local f = x - i
	local u = f * f * (3 - 2 * f) -- smoothstep interpolation
	local function hash(n)
		return math.fmod(math.sin(n) * 43758.5453, 1)
	end
	return math.abs((1 - u) * hash(i) + u * hash(i + 1))
end

--------------------------------------------------------------------------------
-- PERFORMANCE CORE
--------------------------------------------------------------------------------

local Core = {
	state = {
		last_act = vim.uv.now(), -- Activity timestamp
		is_dimmed = false,

		mode = { name = "NORMAL", color = "#ffffff", char = "n" },
		git = { branch = "main", added = 0, changed = 0, removed = 0, exists = false },
		diagnostics = { errors = 0, warnings = 0, has_any = false },

		-- LSP State with Boot Sequence
		lsp = {
			active = false,
			servers = {}, -- list of names
			boot = {}, -- table { "lua_ls" = 0..100 }
			progress = false,
		},

		-- Search with spring-driven roller
		search = {
			count = 0,
			total = 0,
			active = false,
			display_count = 0,
			display_total = 0,
			velocity_count = 0, -- Spring velocity
			velocity_total = 0,
			_last_recompute = 0, -- Explicit timestamp for recompute cadence
		},

		macro = { recording = false, reg = "", buffer = {} },

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

-- Pre-computed nixie bar strings (avoids string.rep per render)
local nixie_bars = {}
for i = 0, 9 do
	nixie_bars[i] = string.rep("▓", i) .. string.rep("░", 9 - i)
end

-- AOD / Wireframe Logic: Swaps FG/BG on idle
function Core.get_hl(name, attr)
	local key = name .. "_" .. attr .. (Core.state.is_dimmed and "_dim" or "")
	if Core.hl_cache[key] then
		return Core.hl_cache[key]
	end

	local hl = utils.get_highlight(name)
	local result = hl and hl[attr] or (attr == "fg" and "#ffffff" or "#000000")

	-- AOD MODE: Invert colors instead of just dimming
	if Core.state.is_dimmed then
		-- In Wireframe mode, usually we want the colored BG to become the colored FG
		-- and the FG (usually white/black) to become transparent/black.
		if attr == "fg" then
			-- If asking for FG, give them the dim version of the original BG (if colorful)
			local bg_orig = hl and hl.bg
			if bg_orig and bg_orig ~= "NONE" then
				result = dim_hex(bg_orig, 0.7) -- Use dimmed BG color as new FG
			else
				result = dim_hex(result, 0.5) -- Just dim the existing FG
			end
		elseif attr == "bg" then
			-- If asking for BG, return Normal BG (effectively transparent/black)
			result = utils.get_highlight("Normal").bg
		end
	end

	Core.hl_cache[key] = result
	return result
end

-- Clear cache on theme change
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		Core.hl_cache = {}
	end,
})

--------------------------------------------------------------------------------
-- CONTROLLER: EVENT LISTENERS
--------------------------------------------------------------------------------

-- 0. Activity Tracker (Focus Breather)
local function interact()
	Core.state.last_act = vim.uv.now()
	if Core.state.is_dimmed then
		Core.state.is_dimmed = false
		Core.hl_cache = {} -- Clear cache to restore brightness
		vim.cmd("redrawstatus")
	end
end
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter", "TextChanged", "CmdlineEnter" }, {
	callback = interact,
})

-- 1. Mode Listener
local ModeNames = {
	n = "NORMAL",
	i = "INSERT",
	v = "VISUAL",
	V = "VISUAL",
	["\22"] = "VISUAL",
	c = "COMMAND",
	s = "SELECT",
	S = "SELECT",
	["\19"] = "SELECT",
	R = "REPLACE",
	r = "...",
	["!"] = "!",
	t = "TERM",
}

-- Hoisted to module level: avoids table allocation on every ModeChanged event
local ModeColorMap = {
	n = "Function",
	i = "String",
	v = "Constant",
	V = "Constant",
	["\22"] = "Constant",
	c = "Statement",
	s = "Type",
	S = "Type",
	["\19"] = "Type",
	R = "String",
	["!"] = "Error",
	t = "Error",
}

local function update_mode()
	local m = vim.fn.mode(1)
	local char = m:sub(1, 1)
	Core.state.mode.char = char
	Core.state.mode.name = ModeNames[m] or ModeNames[char] or "NORMAL"
	Core.state.mode.color = Core.get_hl(ModeColorMap[char] or "Normal", "fg")
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
	local counts = vim.diagnostic.count(0)
	local err = counts[vim.diagnostic.severity.ERROR] or 0
	local warn = counts[vim.diagnostic.severity.WARN] or 0
	Core.state.diagnostics.errors = err
	Core.state.diagnostics.warnings = warn
	Core.state.diagnostics.has_any = (err + warn) > 0
end
vim.api.nvim_create_autocmd("DiagnosticChanged", { callback = update_diagnostics })

-- 4. LSP Listener (With Boot Detection)
vim.api.nvim_create_autocmd({ "LspProgress", "LspAttach", "LspDetach" }, {
	callback = function()
		local clients = vim.lsp.get_clients({ bufnr = 0 })
		local names = {}
		local is_progress = false

		for _, client in ipairs(clients) do
			table.insert(names, client.name)
			-- Init boot state if new
			if not Core.state.lsp.boot[client.name] then
				Core.state.lsp.boot[client.name] = 0
			end

			if vim.lsp.status() ~= "" then
				is_progress = true
			end
		end

		Core.state.lsp.active = (#names > 0)
		Core.state.lsp.servers = names
		Core.state.lsp.progress = is_progress
		if is_progress then
			vim.cmd("redrawstatus")
		end
	end,
})

-- 5. Harpoon Listener
local function update_harpoon()
	if not package.loaded["harpoon"] then
		return
	end
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

-- 6. Macro Recording Listener
-- Use a namespace to prevent duplicate listeners on reload
local macro_ns = vim.api.nvim_create_namespace("heirline_macro")
vim.on_key(nil, macro_ns) -- Clear previous listener

vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
	callback = function()
		local reg = vim.fn.reg_recording()
		Core.state.macro.recording = (reg ~= "")
		Core.state.macro.reg = reg
		if reg ~= "" then
			Core.state.macro.buffer = {}
		end
		vim.cmd("redrawstatus")
	end,
})

vim.on_key(function(key)
	if Core.state.macro.recording then
		local k = vim.fn.keytrans(key)
		if k == "<Ignore>" then
			return
		end

		table.insert(Core.state.macro.buffer, k)
		if #Core.state.macro.buffer > 12 then -- Match display width
			table.remove(Core.state.macro.buffer, 1)
		end
		vim.schedule(function()
			vim.cmd("redrawstatus")
		end)
	end
end, macro_ns)

--------------------------------------------------------------------------------
-- ANIMATION SYSTEM (PHYSICS ENGINE)
--------------------------------------------------------------------------------

local Animation = {
	timer = vim.uv.new_timer(),
	density = { " ", "░", "▒", "▓", "█" },
}

-- Critically Damped Spring: smooth convergence without overshoot
-- Handles target changes mid-flight gracefully (unlike Zeno's paradox)
local function spring_step(current, target, velocity, dt, frequency)
	local offset = current - target
	local decay = math.exp(-frequency * dt)
	local new_pos = (velocity * dt + offset * (frequency * dt + 1)) * decay + target
	local new_vel = (velocity - frequency * dt * (offset * frequency + velocity)) * decay
	return new_pos, new_vel
end

Animation.timer:start(
	0,
	80,
	vim.schedule_wrap(function()
		local now = vim.uv.now()
		local s = Core.state.nixie
		local d = Core.state.diagnostics
		local lsp = Core.state.lsp
		local search = Core.state.search
		local dirty = false

		-- A. FOCUS BREATHER (Dimming Check)
		if not Core.state.is_dimmed and (now - Core.state.last_act > 5000) then
			Core.state.is_dimmed = true
			Core.hl_cache = {} -- Clear cache to force dim colors
			dirty = true
		end

		-- B. SEARCH STATE (Spring-Driven Roller)
		if vim.v.hlsearch == 1 and vim.fn.searchcount then
			-- Explicit timestamp cadence instead of fragile now%500<80
			if now - search._last_recompute > 500 then
				search._last_recompute = now
				local res = vim.fn.searchcount({ recompute = 1, maxcount = 999 })
				if res.total > 0 then
					search.active = true
					search.count = res.current
					search.total = res.total
				else
					search.active = false
				end
			end
		else
			search.active = false
		end

		-- B2. MACRO POLLING (Fallback for missed events)
		local rec_reg = vim.fn.reg_recording()
		if (rec_reg ~= "") ~= Core.state.macro.recording then
			Core.state.macro.recording = (rec_reg ~= "")
			Core.state.macro.reg = rec_reg
			dirty = true
		end

		if search.active then
			-- Spring-driven number roller (replaces Zeno's slide)
			local dt = 0.08 -- 80ms in seconds
			local frequency = 10 -- Tuning: higher = faster convergence

			-- Roll display_count towards count
			if math.abs(search.display_count - search.count) > 0.5 then
				local new_pos, new_vel =
					spring_step(search.display_count, search.count, search.velocity_count, dt, frequency)
				search.display_count = math.floor(new_pos + 0.5)
				search.velocity_count = new_vel
				dirty = true
			else
				search.display_count = search.count
				search.velocity_count = 0
			end

			-- Roll display_total towards total
			if math.abs(search.display_total - search.total) > 0.5 then
				local new_pos, new_vel =
					spring_step(search.display_total, search.total, search.velocity_total, dt, frequency)
				search.display_total = math.floor(new_pos + 0.5)
				search.velocity_total = new_vel
				dirty = true
			else
				search.display_total = search.total
				search.velocity_total = 0
			end
		end

		-- C. LSP BOOT SEQUENCE (Staggered Typewriter Fill)
		if lsp.active then
			for name, progress in pairs(lsp.boot) do
				if progress < 100 then
					-- Ease-out cubic: fast start, smooth deceleration
					local remaining = 100 - progress
					local step = math.max(1, math.floor(remaining * 0.08))
					lsp.boot[name] = math.min(100, progress + step)
					dirty = true
				end
			end
		end

		-- D. HARPOON POLLING (Throttled — only check every ~2s, autocmds handle the rest)
		if package.loaded["harpoon"] and now % 2000 < 80 then
			local h_count = require("harpoon"):list():length()
			if h_count ~= Core.state.harpoon.count then
				update_harpoon()
				dirty = true
			end
		end

		-- E. MAIN NIXIE STATE
		if search.active then
			s.mode = "SEARCH"
			s.color = "#00ff00"
			local ratio = search.display_count / math.max(1, search.display_total)
			s.segments = math.min(9, math.floor(ratio * 9))
			s.label = string.format(" %d/%d", search.display_count, search.display_total)
		elseif Core.state.macro.recording then
			s.mode = "MACRO"
			s.color = "#ff5555"
			s.label = " REC @" .. Core.state.macro.reg
			-- Tape Reel Animation: Cycling 1-9
			s.segments = (math.floor(now / 100) % 9) + 1
		elseif lsp.progress then
			s.mode = "LSP"
			s.color = "#bb00ff"
			s.label = " LSP"
			-- Liquid Metal Shader (table.concat instead of string concat)
			local t = now / 300
			local chars = {}
			for i = 1, 10 do
				local y = math.sin(t + (i * 0.4)) + math.sin(t * 1.7 + (i * 0.2))
				local idx = math.floor((y + 2) / 4 * 5) + 1
				idx = math.max(1, math.min(5, idx))
				chars[i] = Animation.density[idx]
			end
			s.wave_pattern = table.concat(chars)
			dirty = true
		elseif d.has_any then
			s.mode = "DIAGNOSTIC"
			-- Elastic breathing: triple-pulse decay cycle instead of binary toggle
			local cycle = 2000
			local t = (now % cycle) / cycle
			local pulse = math.abs(math.sin(t * math.pi * 3)) * math.exp(-t * 2)
			local base = math.min(9, math.floor(((d.errors + d.warnings) / 5) * 9))
			s.segments = math.max(1, math.min(9, math.floor(base + pulse * 3)))
			s.color = (d.errors > 0) and "#ff0000" or "#ffaa00"
			s.label = string.format(" E%d W%d", d.errors, d.warnings)
		elseif vim.bo.modified then
			s.mode = "MODIFIED"
			-- Heat Gauge: intensity correlates with how much the buffer changed
			local tick = vim.b.changedtick or 0
			local heat = math.min(1, tick / 50)
			local color_r = math.floor(255 * math.max(0.5, heat))
			local color_g = math.floor(136 * (1 - heat))
			s.color = string.format("#%02x%02x00", color_r, color_g)
			s.segments = math.max(1, math.floor(heat * 9))
			s.label = " *"
		else
			s.mode = "IDLE"
			-- Perlin Noise Drift: organic ambient breathing (replaces linear sweep)
			local drift = noise1d(now / 3000) -- Slow organic float 0..1
			local secondary = noise1d(now / 1700 + 100) -- Second layer for variation
			local combined = drift * 0.7 + secondary * 0.3
			local new_segments = math.floor(combined * 4) -- Gentle 0-3 range
			if new_segments ~= s.segments then
				dirty = true
			end
			s.segments = new_segments
			s.color = Core.get_hl("Comment", "fg")
			s.label = ""
		end

		if dirty or s.mode ~= "IDLE" then
			vim.cmd("redrawstatus")
		end

		-- ADAPTIVE TICK RATE: slow down when idle, speed up when animating
		if s.mode == "IDLE" and not dirty and Core.state.is_dimmed then
			Animation.timer:set_repeat(500) -- 2 FPS when fully idle + dimmed
		elseif s.mode == "IDLE" and not dirty then
			Animation.timer:set_repeat(200) -- 5 FPS when idle but active
		else
			Animation.timer:set_repeat(80) -- 12.5 FPS during animations
		end
	end)
)

-- Cleanup timer on exit to prevent ghost timers on :source or config reload
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		Animation.timer:stop()
		Animation.timer:close()
	end,
})

--------------------------------------------------------------------------------
-- COMPONENTS (THE VIEW)
--------------------------------------------------------------------------------

local VimMode = {
	init = function(self)
		self.mode = Core.state.mode
	end,
	-- Nixie Tube Rounded: ░  NORMAL  ░┣
	-- 1. Left glow halo (warm cathode emission)
	{
		provider = function()
			return Core.state.is_dimmed and "" or " ░"
		end,
		hl = function(self)
			if Core.state.is_dimmed then return {} end
			return { fg = dim_hex(self.mode.color, 0.3) }
		end,
	},
	-- 2. Pill left cap (rounded glass edge)
	{
		provider = function()
			return Core.state.is_dimmed and " 󰬅 " or ""
		end,
		hl = function(self)
			if Core.state.is_dimmed then
				return { fg = dim_hex(self.mode.color, 0.7), bold = true }
			end
			return { fg = self.mode.color }
		end,
	},
	-- 3. Mode filament (glowing text inside the tube)
	{
		provider = function(self)
			if Core.state.is_dimmed then
				return self.mode.name:sub(1, 3)
			end
			return " " .. self.mode.name .. " "
		end,
		hl = function(self)
			if Core.state.is_dimmed then
				return { fg = dim_hex(self.mode.color, 0.7), bold = true }
			end
			return { fg = Core.get_hl("Normal", "bg"), bg = self.mode.color, bold = true }
		end,
	},
	-- 4. Pill right cap (rounded glass edge)
	{
		provider = function()
			return Core.state.is_dimmed and "" or ""
		end,
		hl = function(self)
			if Core.state.is_dimmed then return {} end
			return { fg = self.mode.color }
		end,
	},
	-- 5. Right glow halo
	{
		provider = function()
			return Core.state.is_dimmed and "" or "░"
		end,
		hl = function(self)
			if Core.state.is_dimmed then return {} end
			return { fg = dim_hex(self.mode.color, 0.3) }
		end,
	},
	-- 6. Connector to nixie bar
	{
		provider = function()
			return Core.state.is_dimmed and " " or "┣"
		end,
		hl = function(self)
			if Core.state.is_dimmed then return {} end
			return { fg = self.mode.color }
		end,
	},
}

local Nixie = {
	provider = function()
		local s = Core.state.nixie
		if s.mode == "MACRO" then
			local b = Core.state.macro.buffer
			local tape = table.concat(b, "")
			local display = tape:sub(-12)
			local pad = string.rep(" ", math.max(0, 12 - #display))
			return "┣" .. pad .. display .. "┫" .. s.label .. " "
		elseif s.mode == "LSP" then
			return "┣" .. s.wave_pattern .. "┫" .. s.label .. " "
		else
			if Core.state.is_dimmed then
				-- Minimalist Bar in AOD
				return " " .. string.rep("·", 9) .. " "
			else
				-- Use pre-computed bar strings
				return "┣" .. (nixie_bars[s.segments] or nixie_bars[0]) .. "┫" .. (s.label or "") .. " "
			end
		end
	end,
	hl = function()
		local c = Core.state.nixie.color
		if Core.state.is_dimmed then
			c = dim_hex(c, 0.4)
		end
		return { fg = c }
	end,
}

local Git = {
	condition = function()
		return Core.state.git.exists
	end,
	{
		provider = function()
			return (Core.state.is_dimmed and "   " or "┫  ") .. Core.state.git.branch .. " "
		end,
		-- Dynamic hl function: updates on colorscheme change (was static table)
		hl = function()
			return { fg = Core.get_hl("Comment", "fg") }
		end,
		on_click = {
			callback = function()
				Snacks.picker.git_branches()
			end,
			name = "sl_git",
		},
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
		-- Dynamic hl function: updates on colorscheme change (was static table)
		hl = function()
			return { fg = Core.get_hl("diffAdded", "fg") }
		end,
	},
}

local File = {
	init = function(self)
		self.filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
		self.ft = vim.bo.filetype
		-- Cache icon + color once in init (was called twice: provider + hl)
		self.icon, self.icon_color = require("nvim-web-devicons").get_icon_color(self.filename, self.ft)
	end,
	{
		provider = function(self)
			return (Core.state.is_dimmed and " " or "┣ ") .. (self.icon or "") .. " "
		end,
		hl = function(self)
			local color = self.icon_color
			if Core.state.is_dimmed and color then
				color = dim_hex(color, 0.4)
			end
			return {
				fg = color or "#ff8800",
			}
		end,
	},
	{
		provider = function(self)
			return self.filename .. (Core.state.is_dimmed and " " or " ┫ ")
		end,
		-- Dynamic hl function: updates on colorscheme change (was static table)
		hl = function()
			return { fg = Core.get_hl("Directory", "fg") }
		end,
	},
}

local Ruler = {
	provider = function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local total = vim.api.nvim_buf_line_count(0)

		if Core.state.is_dimmed then
			-- AOD: Simple numbers
			return string.format(" %d:%d ", line, total)
		else
			-- Normal: Full Dial
			local ratio = line / total
			local dial_pos = math.floor(ratio * 8 + 0.5)
			local left = string.rep("═", dial_pos)
			local right = string.rep("═", 8 - dial_pos)
			return string.format("[%d:%d] %s╣%s═", line, total, left, right)
		end
	end,
	hl = function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local total = vim.api.nvim_buf_line_count(0)
		local r = line / total
		local c = (r < 0.33) and "#ffaa00" or ((r < 0.67) and "#ff6600" or "#ff0000")
		if Core.state.is_dimmed then
			c = dim_hex(c, 0.4)
		end
		return { fg = c, bold = true }
	end,
	on_click = {
		callback = function()
			local l = vim.api.nvim_win_get_cursor(0)[1]
			local t = vim.api.nvim_buf_line_count(0)
			vim.cmd((l / t > 0.5) and "normal! gg" or "normal! G")
		end,
		name = "sl_ruler",
	},
}

local LspInfo = {
	condition = function()
		return Core.state.lsp.active
	end,
	provider = function()
		local out = {}
		local bar_chars = { "░", "▒", "▓", "█" }
		for _, name in ipairs(Core.state.lsp.servers) do
			local prog = Core.state.lsp.boot[name] or 100
			if prog < 100 then
				-- Staggered typewriter fill: each segment transitions ░→▒→▓→█
				local chars = {}
				for i = 1, 5 do
					local char_prog = math.max(0, math.min(1, (prog - (i - 1) * 20) / 20))
					local idx = math.floor(char_prog * 3) + 1
					chars[i] = bar_chars[idx]
				end
				table.insert(out, "[" .. table.concat(chars) .. "]")
			else
				table.insert(out, name)
			end
		end
		return (Core.state.is_dimmed and " " or "┣ ")
			.. table.concat(out, "+")
			.. (Core.state.is_dimmed and " " or " ┫ ")
	end,
	hl = function()
		local c = "#00d7ff"
		if Core.state.is_dimmed then
			c = dim_hex(c, 0.4)
		end
		return { fg = c, bold = true }
	end,
	on_click = {
		callback = function()
			vim.cmd("checkhealth vim.lsp")
		end,
		name = "sl_lsp_info",
	},
}

local LazyUpdates = {
	condition = function()
		return require("lazy.status").has_updates()
	end,
	provider = function()
		return (Core.state.is_dimmed and " 󰮯 " or "┣ 󰮯 ")
			.. require("lazy.status").updates()
			.. (Core.state.is_dimmed and " " or " ┫ ")
	end,
	hl = { fg = "#ff00ff", bold = true },
}

local Harpoon = {
	condition = function()
		return Core.state.harpoon.active
	end,
	provider = function()
		local s = Core.state.harpoon.string
		if Core.state.is_dimmed then
			return s:gsub("┣", " "):gsub("┫", " ")
		end
		return s
	end,
	hl = function()
		local c = "#00d7ff"
		if Core.state.is_dimmed then
			c = dim_hex(c, 0.4)
		end
		return { fg = c, bold = true }
	end,
}

local SacredSymbols = {
	-- provider = " ॐ  卐 ",
	provider = "卐",
	hl = { fg = "#ffaa00", bold = true },
}

--------------------------------------------------------------------------------
-- ASSEMBLY
--------------------------------------------------------------------------------
local statusline = {
	static = {
		disabled_ft = { "^git.*", "fugitive", "alpha", "dashboard", "neo-tree", "toggleterm", "^k8s_" },
	},
	condition = function(self)
		return not conditions.buffer_matches({ filetype = self.disabled_ft })
	end,
	{
		-- SacredSymbols,
		VimMode,
		Nixie,
		Git,
		Harpoon,
		File,
		{ provider = "%=" }, -- Spacer
		LazyUpdates,
		LspInfo,
		Ruler,
	},
}

return statusline
