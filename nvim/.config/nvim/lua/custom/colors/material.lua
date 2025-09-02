return {
	"marko-cerovac/material.nvim",
	config = function()
		vim.g.material_style = "palenight"
		require("material").setup({
			contrast = {
				terminal = true, -- Enable contrast for the built-in terminal
				sidebars = true, -- Enable contrast for sidebar-like windows ( for example Nvim-Tree )
				floating_windows = true, -- Enable contrast for floating windows
				cursor_line = false, -- Enable darker background for the cursor line
				lsp_virtual_text = true, -- Enable contrasted background for lsp virtual text
				non_current_windows = true, -- Enable contrasted background for non-current windows
				filetypes = {}, -- Specify which filetypes get the contrasted (darker) background
			},

			styles = { -- Give comments style such as bold, italic, underline etc.
				comments = { --[[ italic = true ]]
				},
				strings = { --[[ bold = true ]]
				},
				keywords = { --[[ underline = true ]]
				},
				functions = { --[[ bold = true, undercurl = true ]]
				},
				variables = {},
				operators = {},
				types = {},
			},

			plugins = { -- Uncomment the plugins that you use to highlight them
				-- Available plugins:
				"blink",
				-- "coc",
				-- "colorful-winsep",
				"dap",
				-- "dashboard",
				-- "eyeliner",
				-- "fidget",
				-- "flash",
				"gitsigns",
				"harpoon",
				-- "hop",
				-- "illuminate",
				-- "indent-blankline",
				"lspsaga",
				"mini",
				-- "neo-tree",
				"neogit",
				-- "neorg",
				-- "neotest",
				"noice",
				-- "nvim-cmp",
				-- "nvim-navic",
				-- "nvim-notify",
				-- "nvim-tree",
				-- "nvim-web-devicons",
				"rainbow-delimiters",
				-- "sneak",
				-- "telescope",
				"trouble",
				"which-key",
			},

			disable = {
				colored_cursor = false, -- Disable the colored cursor
				borders = false, -- Disable borders between vertically split windows
				background = true, -- Prevent the theme from setting the background (NeoVim then uses your terminal background)
				term_colors = false, -- Prevent the theme from setting terminal colors
				eob_lines = false, -- Hide the end-of-buffer lines
			},

			high_visibility = {
				lighter = false, -- Enable higher contrast text for lighter style
				darker = true, -- Enable higher contrast text for darker style
			},

			lualine_style = "stealth", -- Lualine style ( can be 'stealth' or 'default' )

			async_loading = true, -- Load parts of the theme asynchronously for faster startup (turned on by default)

			custom_colors = nil, -- If you want to override the default colors, set this to a function

			custom_highlights = {}, -- Overwrite highlights with your own
		})
	end,
}
