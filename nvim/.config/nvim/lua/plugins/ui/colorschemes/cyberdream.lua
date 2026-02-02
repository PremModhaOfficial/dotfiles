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
				bg = "#0c1014",
				bg_alt = "#11151c",
				bg_highlight = "#0a3749",
				fg = "#d3ebe9",
				grey = "#599cab",
				red = "#c23127",
				orange = "#d26937",
				yellow = "#edb443",
				green = "#2aa889",
				cyan = "#33859E",
				blue = "#195466",
				magenta = "#888ca6",
				pink = "#888ca6",
				purple = "#4e5166",
			},

			highlights = {
				Comment = { fg = "#696969", bg = "NONE", italic = true },
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
		require("lib.utils").set_transparent_special_chars()
	end,
}
