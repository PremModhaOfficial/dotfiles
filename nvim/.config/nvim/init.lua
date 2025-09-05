local function makeNone()
	local Normal = vim.api.nvim_get_hl(0, { name = "Normal" })
	local NormalNC = vim.api.nvim_get_hl(0, { name = "NormalNC" })
	local NormalFloat = vim.api.nvim_get_hl(0, { name = "NormalFloat" })

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

	return function()
		vim.api.nvim_set_hl(0, "Normal", { bg = Normal.bg })
		vim.api.nvim_set_hl(0, "NormalNC", { bg = NormalNC.bg })
		vim.api.nvim_set_hl(0, "NormalFloat", { bg = NormalFloat.bg })
	end
end

function ColorschemeWithTransprancy(color, transparentByDefault, callback)
	if not callback then
		color = color or "tokyonight-night"
		vim.cmd.colorscheme(color)
	else
		callback()
		vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
	end
	if not transparentByDefault then
		return makeNone()
	end
end

function DefaultColors(col)
	if not col then
		ColorschemeWithTransprancy("fluoromachine", false)
		return
	end
	ColorschemeWithTransprancy(col, false)
end

--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?
Kickstart.nvim is *not* a distribution.
  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html


Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>
    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest

  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua


    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]
--

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true
-- Disable conceal globally to prevent treesitter conflicts
vim.opt.conceallevel = 0
vim.opt.concealcursor = ""
vim.opt.cursorcolumn = false

-- vim.api.nvim_set_hl(0, "SpellBad", { cterm = { undercurl = true }, undercurl = true })

-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!

vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.opt.clipboard = "unnamedplus"

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300
-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
-- vim.opt.listchars = { tab = "»·", trail = "·", nbsp = "␣", extends = "…", precedes = "…" }
vim.opt.listchars = { tab = "  ", trail = "·", nbsp = "␣", extends = "…", precedes = "…" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 19
-- for fat cursur
-- guicursur = "block"

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>fs", "<cmd>:w<CR>")
vim.keymap.set("n", "<M-1>", "<cmd>Exp<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>od", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Enable conceal only for markdown files to preserve decorations
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.conceallevel = 2
		vim.opt_local.concealcursor = "nc"
	end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
local function border(hl_name)
	return {
		{ "┌", hl_name },
		{ "─", hl_name },
		{ "┐", hl_name },
		{ "│", hl_name },
		{ "┘", hl_name },
		{ "─", hl_name },
		{ "└", hl_name },
		{ "│", hl_name },
	}
end

-- NOTE: Here is where you install your plugins.
require("lazy").setup({
	rocks = {
		hererocks = true, -- you should enable this to get hererocks support
	},
	spec = {
		-- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
		"tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically

		-- NOTE: Plugins can also be added by using a table,
		-- with the first argument being the link and the following
		-- keys can be used to configure plugin behavior/loading/etc.
		--
		-- Use `opts = {}` to force a plugin to be loaded.
		--
		--  This is equivalent to:
		--    require('Comment').setup({})

		-- "gc" to comment visual regions/lines
		{ "numToStr/Comment.nvim", opts = {} },
		{
			-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
			-- used for completion, annotations and signatures of Neovim apis
			"folke/lazydev.nvim",
			ft = "lua",
			cmd = "LazyDev",
			opts = {
				library = {
					-- Load luvit types when the `vim.uv` word is found
					{ path = "luvit-meta/library", words = { "vim%.uv" } },
					{ path = "LazyVim", words = { "LazyVim" } },
					{ path = "snacks.nvim", words = { "Snacks" } },
					{ path = "lazy.nvim", words = { "LazyVim" } },
				},
			},
		},
		{ "Bilal2453/luvit-meta", lazy = true },
		-- Here is a more advanced example where we pass configuration
		-- options to `gitsigns.nvim`. This is equivalent to the following Lua:
		--    require('gitsigns').setup({ ... })
		--
		-- See `:help gitsigns` to understand what the configuration keys do
		{ -- Adds git related signs to the gutter, as well as utilities for managing changes
			"lewis6991/gitsigns.nvim",
			opts = {
				signs = {
					add = { text = "+" },
					change = { text = "~" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
				},
			},
		},

		-- NOTE: Plugins can also be configured to run Lua code when they are loaded.
		--
		-- This is often very useful to both group configuration, as well as handle
		-- lazy loading plugins that don't need to be loaded immediately at startup.
		--
		-- For example, in the following configuration, we use:
		--  event = 'VimEnter'
		--
		-- which loads which-key before all the UI elements are loaded. Events can be
		-- normal autocommands events (`:help autocmd-events`).
		--
		-- Then, because we use the `config` key, the configuration only runs
		-- after the plugin has been loaded:
		--  config = function() ... end

		{ -- Useful plugin to show you pending keybinds.
			"folke/which-key.nvim",
			event = "VimEnter", -- Sets the loading event to 'VimEnter'
			config = function() -- This is the function that runs, AFTER loading
				require("which-key").setup({
					win = { border = border("WhichKeyBorder") },
				})

				-- Document existing key chains
				require("which-key").add({
					{ "<leader>c", "[C]ode" },
					{ "<leader>d", "[D]ocument" },
					{ "<leader>r", "[R]ename" },
					{ "<leader>s", "[S]earch" },
					{ "<leader>w", "[W]orkspace" },
					{ "<leader>t", "[T]oggle" },
					-- { "<leader>h", "Git [H]unk", mode = { "n", "v" } },

					-- LSP specific keymaps
					{ "<leader>ca", "[C]ode [A]ction" },
					{ "<leader>ci", "[C]all [I]ncoming" },
					{ "<leader>co", "[C]all [O]utgoing" },

					{ "<leader>ff", "[F]inder" },
					{ "<leader>P", "[P]eek type definition" },
					{ "<leader>rn", "[R]e[n]ame" },
					{ "<leader>rN", "[R]e[n]ame project" },
					{ "<leader>th", "[T]oggle inlay [H]ints" },
					{ "<leader>wd", "[W]orkspace [D]iagnostics" },
				})
			end,
		},

		-- NOTE: Plugins can specify dependencies.
		--
		-- The dependencies are proper plugin specifications as well - anything
		-- you do for a plugin at the top level, you can do for a dependency.
		--
		-- Use the `dependencies` key to specify the dependencies of a particular plugin

		{ -- Autoformat
			"stevearc/conform.nvim",
			lazy = false,
			keys = {
				{
					"<leader>DF",
					function()
						require("conform").format({ async = true, lsp_fallback = true })
					end,
					mode = "",
					desc = "[F]ormat buffer",
				},
			},
			opts = {
				notify_on_error = true,
				format_on_save = function(bufnr)
					-- Disable "format_on_save lsp_fallback" for languages that don't
					-- have a well standardized coding style. You can add additional
					-- languages here or re-enable it for the disabled ones.
					local disable_filetypes = { c = true, cpp = true, rust = true }
					return {
						timeout_ms = 500,
						lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
					}
				end,
				formatters_by_ft = {
					lua = { "stylua" },
					-- Conform can also run multiple formatters sequentially
					python = { "isort", "black" },
					--
					-- You can use a sub-list to tell conform to run *until* a formatter
					-- is found.
					javascript = { "eslint", "prettierd", "prettier", stop_after_first = true },
					typrscript = { "prettierd", "prettier", "eslint", stop_after_first = true },
				},
			},
		},

		-- Highlight todo, notes, etc in comments
		{
			"folke/todo-comments.nvim",
			event = "VimEnter",
			dependencies = {
				"nvim-lua/plenary.nvim",
			},
			---@module "todo-comments"
			---@type TodoConfig
			opts = { signs = false },
		},

		-- neovide

		-- The following two comments only work if you have downloaded the kickstart repo, not just copy pasted the
		-- init.lua. If you want these files, they are in the repository, so you can just download them and
		-- place them in the correct locations.

		-- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
		--
		--  Here are some example plugins that I've included in the Kickstart repository.
		--  Uncomment any of the lines below to enable them (you will need to restart nvim).
		--
		-- require 'kickstart.plugins.debug',
		-- require 'kickstart.plugins.indent_line',
		-- require 'kickstart.plugins.lint',
		-- require 'kickstart.plugins.autopairs',
		-- require 'kickstart.plugins.neo-tree',
		-- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

		-- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
		--    This is the easiest way to modularize your config.
		--
		--  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
		--    For additional information, see `:help lazy.nvim-lazy.nvim-structuring-your-plugins`
		{ import = "custom.plugins" },
		{ import = "custom.colors" },
		{ import = "custom.ai" },
		{ import = "custom.editor" },
		-- { import = "custom.ui" },
		-- { import = "custom.ui_plugs" },
	},
}, {
	ui = { -- If you are using a Nerd Font: set icons to an empty table which will use the
		-- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
--
-- make nvim transparent
vim.filetype.add({
	pattern = { [".*/hypr/.*%.conf"] = "hyprlang" },
})
-- Hyprlang LSP
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = { "*.hl", "hypr*.conf" },
	callback = function(event)
		print(string.format("starting hyprls for %s", vim.inspect(event)))
		vim.lsp.start({
			name = "hyprlang",
			cmd = { "hyprls" },
			root_dir = vim.fn.getcwd(),
		})
	end,
})
if vim.g.neovide then
	vim.o.guifont = "JetBrainsMono NF:h18" -- text below applies for VimScript
end
-- vim.cmd([[
--   highlight Pmenu guibg=NONE ctermbg=NONE
--   " highlight PmenuSel guibg= ctermbg=NONE
-- ]])

vim.api.nvim_set_keymap("n", "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<M-a>", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<M-a>", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })

-- Expand 'cc' into 'CodeCompanion' in the command line
vim.cmd([[cab cc CodeCompanion]])
vim.opt.termguicolors = true

-- vim.cmd("colorscheme bluloco")
-- ColorschemeWithTransprancy("neon-netrunner-night", false)
-- ColorschemeWithTransprancy("catppuccin", false)
-- ("aurora", false)
-- ("material", false)
local resetColors = ColorschemeWithTransprancy("fluoromachine", false)

vim.keymap.set("n", "<leader>cd", function()
	resetColors()
end)
-- ("randomhue", true)
-- ColorschemeWithTransprancy("gruvbox", false)
-- ("andromeda", false)
require("config.undercurl").setup()

-- Snacks.toggle.inlay_hints()
