return {
	"scottmckendry/cyberdream.nvim",
	lazy = false,
	enabled = true,
	priority = 1000,
	config = function()
		require("cyberdream").setup({
			variant = "auto",
			transparent = true,
			saturation = 1,
			italic_comments = false,
			hide_fillchars = true,
			borderless_pickers = true,
			terminal_colors = true,
			cache = false,

			colors = {
				-- Rose Pine color palette
				bg = "#191724",       -- Base
				bg_alt = "#1f1d2e",   -- Surface
				bg_highlight = "#26233a", -- Overlay
				fg = "#e0def4",       -- Text
				grey = "#6e6a86",     -- Muted
				red = "#eb6f92",      -- Love
				orange = "#f6c177",   -- Gold
				yellow = "#f6c177",   -- Gold
				green = "#31748f",    -- Pine
				cyan = "#9ccfd8",     -- Iris
				blue = "#31748f",     -- Pine
				magenta = "#c4a7e7",  -- Foam
				pink = "#ebbcba",     -- Rose
				purple = "#c4a7e7",   -- Foam
			},

			highlights = {
				Comment = { fg = "#6e6a86", bg = "NONE", italic = true },
				Whitespace = { fg = "#191724", bg = "#191724" },
				NonText = { fg = "#191724", bg = "#191724" },
				EndOfBuffer = { fg = "#191724", bg = "#191724" },
			},

			extensions = {
				blinkcmp = true,
				dapui = true,
				dashboard = true,
				gitsigns = true,
				grugfar = true,
				heirline = true,
				indentblankline = true,
				lazy = true,
				markdown = true,
				markview = true,
				mini = true,
				noice = true,
				neogit = true,
				rainbow_delimiters = true,
				snacks = true,
				treesitter = true,
				whichkey = true,
			},
		})

		vim.cmd("colorscheme cyberdream")

		local bg = "#191724"
		vim.api.nvim_set_hl(0, "Whitespace", { fg = bg, bg = bg })
		vim.api.nvim_set_hl(0, "NonText", { fg = bg, bg = bg })
		vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = bg, bg = bg })
	end,
}

-- =============================================================================
-- Previous Cyberdream config (commented out for rollback):
-- =============================================================================
-- return {
-- 	"scottmckendry/cyberdream.nvim",
-- 	lazy = false,
-- 	enabled = true,
-- 	priority = 1000,
-- 	config = function()
-- 		require("cyberdream").setup({
-- 			variant = "auto",
-- 			transparent = true,
-- 			saturation = 1,
-- 			italic_comments = false,
-- 			hide_fillchars = true,
-- 			borderless_pickers = true,
-- 			terminal_colors = true,
-- 			cache = false,
--
-- 			colors = {
-- 				bg = "#0c1014",
-- 				bg_alt = "#11151c",
-- 				bg_highlight = "#0a3749",
-- 				fg = "#d3ebe9",
-- 				grey = "#599cab",
-- 				red = "#c23127",
-- 				orange = "#d26937",
-- 				yellow = "#edb443",
-- 				green = "#2aa889",
-- 				cyan = "#33859E",
-- 				blue = "#195466",
-- 				magenta = "#888ca6",
-- 				pink = "#888ca6",
-- 				purple = "#4e5166",
-- 			},
--
-- 			highlights = {
-- 				Comment = { fg = "#696969", bg = "NONE", italic = true },
-- 				Whitespace = { fg = "#0c1014", bg = "#0c1014" },
-- 				NonText = { fg = "#0c1014", bg = "#0c1014" },
-- 				EndOfBuffer = { fg = "#0c1014", bg = "#0c1014" },
-- 			},
--
-- 			extensions = {
-- 				blinkcmp = true,
-- 				dapui = true,
-- 				dashboard = true,
-- 				gitsigns = true,
-- 				grugfar = true,
-- 				heirline = true,
-- 				indentblankline = true,
-- 				lazy = true,
-- 				markdown = true,
-- 				markview = true,
-- 				mini = true,
-- 				noice = true,
-- 				neogit = true,
-- 				rainbow_delimiters = true,
-- 				snacks = true,
-- 				treesitter = true,
-- 				whichkey = true,
-- 			},
-- 		})
--
-- 		vim.cmd("colorscheme cyberdream")
--
-- 		local bg = "#0c1014"
-- 		vim.api.nvim_set_hl(0, "Whitespace", { fg = bg, bg = bg })
-- 		vim.api.nvim_set_hl(0, "NonText", { fg = bg, bg = bg })
-- 		vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = bg, bg = bg })
-- 	end,
-- }
