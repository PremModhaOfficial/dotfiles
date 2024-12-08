return {
	"nvimdev/lspsaga.nvim",
	opts = {
		ui = {
			beacon = {
				enable = true,
				devicon = true,
			},
		},
	},
	-- add your config value here
	dependencies = {
		"nvim-treesitter/nvim-treesitter", -- optional
		"nvim-tree/nvim-web-devicons", -- optional
	},
}
