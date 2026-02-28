local opt = vim.opt
local g = vim.g

g.mapleader = " "
g.maplocalleader = " "
g.lazyvim_check_order = false
g.have_nerd_font = true

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.cursorcolumn = false
opt.signcolumn = "yes"
opt.showmode = false
opt.ruler = false
opt.showcmd = false
opt.termguicolors = true
opt.conceallevel = 0
opt.concealcursor = ""

opt.mouse = "a"
opt.clipboard = "unnamedplus"
-- if vim.fn.has("wayland") == 1 or vim.env.WAYLAND_DISPLAY then
-- 	vim.g.clipboard = {
-- 		name = "wl-copy",
-- 		copy = {
-- 			["+"] = "wl-copy",
-- 			["*"] = "wl-copy",
-- 		},
-- 		paste = {
-- 			["+"] = "wl-paste",
-- 			["*"] = "wl-paste",
-- 		},
-- 		cache_enabled = 0,
-- 	}
-- end
-- OSC 52 fallback for reliable global clipboard
if vim.fn.has("nvim-0.10") == 1 then
	vim.api.nvim_create_autocmd("TextYankPost", {
		callback = function()
			if vim.v.event.operator == "y" and vim.v.event.regname == "+" then
				require("vim.ui.clipboard.osc52").copy("+")(vim.v.event.regcontents)
			end
		end,
	})
end
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.breakindent = true
opt.undofile = true
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true

opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 3

opt.updatetime = 250
opt.timeoutlen = 300

opt.list = true
opt.listchars = { tab = "  ", trail = "·", nbsp = "␣", extends = "…", precedes = "…" }
opt.inccommand = "split"

if g.neovide then
	vim.o.guifont = "JetBrainsMono NF:h18"
end
