return {
	"rose-pine/neovim",
	name = "rose-pine",
	enabled = false,
	config = function()
		require("rose-pine").setup({
			variant = "main",
			dim_inactive_windows = false,
			extend_background_behind_borders = false,

			enable = {
				terminal = true,
				migrations = true,
			},

			styles = {
				transparency = true,
			},

			groups = {
				border = "pine",
				link = "iris",
				panel = "surface",

				error = "love",
				hint = "iris",
				info = "foam",
				note = "pine",
				todo = "rose",
				warn = "gold",

				git_add = "foam",
				git_change = "rose",
				git_delete = "love",
				git_dirty = "rose",
				git_ignore = "muted",
				git_merge = "iris",
				git_rename = "pine",
				git_stage = "iris",
				git_text = "rose",
				git_untracked = "subtle",

				h1 = "iris",
				h2 = "foam",
				h3 = "rose",
				h4 = "gold",
				h5 = "pine",
				h6 = "foam",
			},

			palette = {},

			highlight_groups = {},

			before_highlight = function() end,
		})
	end,
}
