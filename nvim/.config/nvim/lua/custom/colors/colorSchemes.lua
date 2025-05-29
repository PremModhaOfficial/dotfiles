return { -- You can easily change to a different colorscheme.
	-- Change the name of the colorscheme plugin below, and then
	-- change the command in the config to whatever the name of that colorscheme is.
	--
	-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
	"folke/tokyonight.nvim",
	-- enabled = false,
	priority = 1000, -- Make sure to load this before all the other start plugins.
	---@module "tokyonight"
	---@type tokyonight.Config
	opts = {
		transparent = true,
		styles = {
			sidebars = "transparent",
			floats = "transparent",
		},
		style = "night",
		cache = false,
	},
	-- init = function() vim.cmd.colorscheme("tokyonight-night") -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'. vim.cmd.hi("Comment gui=none guifg=#4f5b66") -- You can configure highlights by doing something like: end,
}
