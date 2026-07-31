return {
	"marko-cerovac/material.nvim",
	config = function()
		require("material").setup({
			contrast = {
				terminal = true,
				sidebars = true,
				floating_windows = true,
				cursor_line = true,
				lsp_virtual_text = true,
				non_current_windows = true,
				filetypes = {},
			},
			styles = {
				comments = {},
				strings = {},
				keywords = {},
				functions = {},
				variables = {},
				operators = {},
				types = {},
			},

			plugins = {
				"blink",
				"dap",
				"gitsigns",
				"harpoon",
				"mini",
				"noice",
				"nvim-web-devicons",
				"rainbow-delimiters",
				"which-key",
			},

			disable = {
				colored_cursor = true,
				borders = false,
				background = true,
				term_colors = false,
				eob_lines = false,
			},

			high_visibility = {
				lighter = false,
				darker = true,
			},

			lualine_style = "stealth",

			async_loading = true,

			custom_colors = nil,

			custom_highlights = {},
		})
	end,
}
