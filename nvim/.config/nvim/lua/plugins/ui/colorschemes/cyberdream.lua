return {
	"scottmckendry/cyberdream.nvim",
	lazy = false,
	enabled = false,
	priority = 1000,
	config = function()
		require("cyberdream").setup({
			-- Set light or dark variant
			variant = "auto",
			-- use "light" for the light variant. Also accepts "auto" to set dark or light colors based on the current value of `vim.o.background` Enable transparent background
			transparent = true,
			-- Reduce the overall saturation of colours for a more muted look
			-- accepts a value between 0 and 1. 0 will be fully desaturated (greyscale) and 1 will be the full color (default) Enable italics comments
			saturation = 0.5,
			italic_comments = false, -- Replace all fillchars with ' ' for the ultimate clean look
			hide_fillchars = true, -- Apply a modern borderless look to pickers like Telescope, Snacks Picker & Fzf-Lua
			borderless_pickers = true, -- Set terminal colors used in `:terminal`
			terminal_colors = true,

			-- Improve start up time by caching highlights. Generate cache with :CyberdreamBuildCache and clear with :CyberdreamClearCache
			cache = false,

			-- Override highlight groups with your own colour values
			highlights = {
				Comment = { fg = "#696969", bg = "NONE", italic = true },

				BlinkCmpMenu = { bg = "#16181a" },
				BlinkCmpMenuBorder = { bg = "#16181a", fg = "#00d9ff" },
				BlinkCmpDoc = { bg = "#16181a" },
				BlinkCmpDocBorder = { bg = "#16181a", fg = "#00d9ff" },
				BlinkCmpSignatureHelp = { bg = "#16181a" },
				BlinkCmpSignatureHelpBorder = { bg = "#16181a", fg = "#00d9ff" },
			},

			-- Disable or enable colorscheme extensions
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

		-- Set the colorscheme
		vim.cmd("colorscheme cyberdream")

		local get_hl = vim.api.nvim_get_hl
		local set_hl = vim.api.nvim_set_hl

		local menu_bg = get_hl(0, { name = "BlinkCmpMenu" }).bg or "#16181a"
		local primary_color = "#00d9ff"

		set_hl(0, "BlinkCmpMenuBorder", { bg = menu_bg, fg = primary_color })
		set_hl(0, "BlinkCmpDocBorder", { bg = menu_bg, fg = primary_color })
		set_hl(0, "BlinkCmpSignatureHelpBorder", { bg = menu_bg, fg = primary_color })
	end,
}
