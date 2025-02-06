return {
	"nvimdev/lspsaga.nvim",
	---@module "lspsaga"
	---@type LspsagaConfig
	opts = {
		callhierarchy = {
			layout = "float",
		},

		beacon = {
			enable = true,
		},
		ui = { border = "rounded", code_action = "" },
	},
	-- add your config value here
	dependencies = {
		"nvim-treesitter/nvim-treesitter", -- optional
		"nvim-tree/nvim-web-devicons", -- optional
	},
}
