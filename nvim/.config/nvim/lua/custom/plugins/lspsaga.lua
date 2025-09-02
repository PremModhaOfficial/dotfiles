return {
	"nvimdev/lspsaga.nvim",
	---@module "lspsaga"
	---@type LspsagaConfig
	opts = {
		callhierarchy = {
			layout = "float",
		},
		symbol_in_winbar = {
			color_mode = true,
			enable = true,
		},
		beacon = {
			enable = false,
		},
		ui = { border = "rounded", code_action = "" },
	},
	-- add your config value here
	dependencies = {
		"nvim-treesitter/nvim-treesitter", -- optional
		"nvim-tree/nvim-web-devicons", -- optional
	},
}
