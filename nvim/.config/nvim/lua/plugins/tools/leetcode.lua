return {
	"kawre/leetcode.nvim",
	-- build = ":TSUpdate html", -- if you have `nvim-treesitter` installed
	event = "VeryLazy",
	dependencies = {
		{ "nvim-telescope/telescope.nvim" },
		-- "ibhagwan/fzf-lua",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
	},
	---@module 'leetcode'
	opts = {
		picker = {
			provider = "telescope",
		},
		storage = {
			home = "~/projects/unsortedProjects/DSA/leetcode/",
			cache = "~/projects/unsortedProjects/DSA/leetcode/cache/",
		},
	},
}
