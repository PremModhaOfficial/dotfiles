return {
	"scottmckendry/cyberdream.nvim",
	lazy = false,
	enabled = false,
	priority = 1000,
	config = function()
		vim.cmd([[ set background=dark ]])
		require("cyberdream").setup({
			transparent = true,
			italic_comments = true,
			hide_fillchars = true,
			borderless_telescope = false,
			terminal_colors = true,
			-- Use caching to improve performance - WARNING: experimental feature - expect the unexpected!
			-- Early testing shows a 60-70% improvement in startup time. YMMV. Disables dynamic light/dark theme switching.
			cache = false,
			-- generate cache with :CyberdreamBuildCache and clear with :CyberdreamClearCache
			theme = {
				variant = "auto",
				-- use "light" for the light variant. Also accepts "auto" to set dark or light colors based on the current value of `vim.o.background`
				highlights = {
					-- Highlight groups to override, adding new groups is also possible
					-- See `:h highlight-groups` for a list of highlight groups or run `:hi` to see all groups and their current values
					-- Example:
					Comment = { fg = "#B00B69", bg = "NONE", italic = true },
					functions = { italic = true },
					constants = { bold = true },
					strings = { italic = true },
					-- Complete list can be found in `lua/cyberdream/theme.lua`
				},
				-- Override a highlight group entirely using the color palette
				-- overrides = function(colors) -- NOTE: This function nullifies the `highlights` option
				--     -- Example:
				--     return {
				--         Comment = { fg = colors.green, bg = "NONE", italic = true },
				--         ["@property"] = { fg = colors.magenta, bold = true },
				--     }
				-- end,
				-- Override a color entirely
				-- 	colors = { -- For a list of colors see `lua/cyberdream/colours.lua` Example: bg = "#000000", green = "#00ff00", magenta = "#ff00ff", },
			},
		})
	end,
	-- init = function()
	-- 	vim.cmd([[
	-- 			colorscheme cyberdream
	-- 			CyberdreamBuildCache
	-- 			]])
	-- end,
}
