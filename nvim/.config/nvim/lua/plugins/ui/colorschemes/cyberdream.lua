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
				bg = "#191724",
				bg_alt = "#1f1d2e",
				bg_highlight = "#26233a",
				fg = "#e0def4",
				grey = "#6e6a86",
				red = "#eb6f92",
				orange = "#f6c177",
				yellow = "#f6c177",
				green = "#31748f",
				cyan = "#9ccfd8",
				blue = "#31748f",
				magenta = "#c4a7e7",
				pink = "#ebbcba",
				purple = "#c4a7e7",
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
