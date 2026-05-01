return {

	{ -- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			{

				"HiPhish/rainbow-delimiters.nvim",
				-- enabled = false,
			},
		},
		config = function()
			-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
			local ts = require("nvim-treesitter")

			-- Setup install directory (optional, defaults to stdpath('data') .. '/site')
			ts.setup({
				install_dir = vim.fn.stdpath("data") .. "/site",
			})

			-- Install parsers (this is a no-op if already installed)
			ts.install({
				"bash",
				"c",
				"diff",
				"go",
				"gomod",
				"gowork",
				"gosum",
				"haskell",
				"cabal",
				"html",
				"java",
				"lua",
				"luadoc",
				"markdown",
				"vim",
				"vimdoc",
			})

			-- Auto-install parser on FileType if available
			vim.api.nvim_create_autocmd("FileType", {
				callback = function()
					local lang = vim.bo.filetype
					local available = ts.get_available()
					local has_parser = vim.tbl_contains(available, lang)
					if has_parser then
						ts.install(lang)
						pcall(vim.treesitter.start)
					end
				end,
			})

			-- Enable indentation (experimental)
			vim.api.nvim_create_autocmd("FileType", {
				callback = function()
					if vim.bo.filetype ~= "java" then
						vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})

			-----------------------------------------------------
			-- This module contains a number of default definitions
			local rainbow_delimiters = require("rainbow-delimiters")
			---@type rainbow_delimiters.config
			vim.g.rainbow_delimiters = {
				strategy = {
					[""] = rainbow_delimiters.strategy["global"],
					vim = rainbow_delimiters.strategy["local"],
					go = rainbow_delimiters.strategy["global"],
				},
				query = {
					[""] = "rainbow-delimiters",
					lua = "rainbow-blocks",
					go = "rainbow-delimiters",
				},
				priority = {
					[""] = 110,
					lua = 210,
					go = 110,
				},
				highlight = {
					"RainbowDelimiterRed",
					"RainbowDelimiterYellow",
					"RainbowDelimiterBlue",
					"RainbowDelimiterOrange",
					"RainbowDelimiterGreen",
					"RainbowDelimiterViolet",
					"RainbowDelimiterCyan",
				},
			}
			-----------------------------------------------------

			-- There are additional nvim-treesitter modules that you can use to interact
			-- with nvim-treesitter. You should go explore a few and see what interests you:
			--
			--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
			--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
			--
		end,
	},
	--
	-- {
	--
	-- 	"nvim-treesitter/nvim-treesitter-context",
	-- 	config = function()
	-- 		require("treesitter-context").setup({
	-- 			enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
	-- 			max_lines = 5, -- How many lines the window should span. Values <= 0 mean no limit.
	-- 			min_window_height = 15, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
	-- 			line_numbers = true,
	-- 			multiline_threshold = 20, -- Maximum number of lines to show for a single context
	-- 			trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
	-- 			mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
	-- 			-- Separator between context and content. Should be a single character string, like '-'.
	-- 			-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
	-- 			-- separator = "󰥛",
	-- 			separator = "󱑻",
	-- 			zindex = 20, -- The Z-index of the context window
	-- 			on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
	-- 			require("which-key").add({
	-- 				{
	-- 					"[c",
	-- 					function()
	-- 						require("treesitter-context").go_to_context(vim.v.count1)
	-- 					end,
	-- 					desc = "Go to previous context",
	-- 					{ silent = true },
	-- 				},
	-- 			}),
	-- 		})
	-- 		--
	-- 		--
	-- 		--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
	-- 	end,
	-- },
}
