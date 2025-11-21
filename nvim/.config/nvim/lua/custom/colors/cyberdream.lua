return {
	"scottmckendry/cyberdream.nvim",
	lazy = false,
	enabled = false,
	priority = 1000,
	config = function()
		vim.cmd([[ set background=dark ]])
		require("cyberdream").setup({
			-- Set light or dark variant
			variant = "default", -- use "light" for the light variant. Also accepts "auto" to set dark or light colors based on the current value of `vim.o.background`

			-- Enable transparent background
			transparent = true,

			-- Reduce the overall saturation of colours for a more muted look
			saturation = 1, -- accepts a value between 0 and 1. 0 will be fully desaturated (greyscale) and 1 will be the full color (default)

			-- Enable italics comments
			italic_comments = true,

			-- Replace all fillchars with ' ' for the ultimate clean look
			hide_fillchars = true,

			-- Apply a modern borderless look to pickers like Telescope, Snacks Picker & Fzf-Lua
			borderless_pickers = true,

			-- Set terminal colors used in `:terminal`
			terminal_colors = true,

			-- Improve start up time by caching highlights. Generate cache with :CyberdreamBuildCache and clear with :CyberdreamClearCache
			cache = true,

			-- Override highlight groups with your own colour values
			highlights = {
				-- Highlight groups to override, adding new groups is also possible
				-- See `:h highlight-groups` for a list of highlight groups or run `:hi` to see all groups and their current values

				-- Example:
				-- Comment = { fg = "#696969", bg = "NONE", italic = true },
			},

			-- Override a highlight group entirely using the built-in colour palette

			-- -- Override colors
			-- colors = {
			-- 	-- For a list of colors see `lua/cyberdream/colours.lua`
			--
			-- 	-- Override colors for both light and dark variants
			-- 	bg = "#000000",
			-- 	green = "#00ff00",
			--
			-- 	-- If you want to override colors for light or dark variants only, use the following format:
			-- 	dark = {
			-- 		magenta = "#ff00ff",
			-- 		fg = "#eeeeee",
			-- 	},
			-- 	light = {
			-- 		red = "#ff5c57",
			-- 		cyan = "#5ef1ff",
			-- 	},
			-- },

			-- Disable or enable colorscheme extensions
			extensions = {
				alpha = true,
				blinkcmp = true,
				cmp = false,
				dapui = true,
				dashboard = true,
				fzflua = false,
				gitpad = false,
				gitsigns = true,
				grapple = false,
				grugfar = true,
				heirline = true,
				helpview = false,
				hop = false,
				indentblankline = true,
				kubectl = false,
				lazy = true,
				leap = false,
				markdown = true,
				markview = true,
				mini = true,
				neogit = true,
				noice = true,
				notify = true,
				rainbow_delimiters = true,
				snacks = true,
				telescope = false,
				treesitter = true,
				treesittercontext = true,
				whichkey = true,
			},
		})
	end,
	init = function()
		vim.cmd([[
				colorscheme cyberdream
				]])
	end,
}
