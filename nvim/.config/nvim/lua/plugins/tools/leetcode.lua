return {
	"kawre/leetcode.nvim",
	-- build = ":TSUpdate html", -- if you have `nvim-treesitter` installed
	lazy = false, -- Load immediately to ensure commands are available
	dependencies = {
		-- "ibhagwan/fzf-lua",
		"folke/snacks.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
	},
	---@module 'leetcode'
	opts = {
		picker = {
			provider = nil,
		},
		storage = {
			home = "~/projects/unsortedProjects/DSA/leetcode/",
			cache = "~/projects/unsortedProjects/DSA/leetcode/cache/",
		},
	},
}
