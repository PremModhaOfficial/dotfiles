return {
	"scottmckendry/cyberdream.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("cyberdream").setup({
			transparent = true,
			italic_comments = true,
			hide_fillchars = true,
			borderless_pickers = false, -- We like our industrial borders
			terminal_colors = true,
			cache = true,
			
			-- High Saturation for Cyberpunk Pop
			saturation = 1, 

			-- Override colors for the "Industrial" look
			colors = {
				dark = {
					bg = "#000000", -- Pure black for best transparency contrast
					green = "#00ff87", -- Neon Spring Green
					magenta = "#ff00ff", -- Sharp Magenta
					cyan = "#00d7ff", -- Tech Blue
				},
			},

			highlights = {
				-- Custom glowing tags for our new Blink.cmp source indicators
				BlinkCmpSource = { fg = "#00d7ff", italic = true, bold = true },
				-- Match our statusline components
				HeirlineModeNormal = { fg = "#00d7ff", bold = true },
			},

			extensions = {
				blinkcmp = true,
				gitsigns = true,
				heirline = true,
				lazy = true,
				markdown = true,
				mini = true,
				noice = true,
				notify = true,
				rainbow_delimiters = true,
				snacks = true,
				treesitter = true,
				whichkey = true,
			},
		})
		
		-- Set the colorscheme
		vim.cmd("colorscheme cyberdream")
	end,
}