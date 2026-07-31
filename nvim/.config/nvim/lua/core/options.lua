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
