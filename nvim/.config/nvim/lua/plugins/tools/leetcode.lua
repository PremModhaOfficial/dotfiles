return {
	"kawre/leetcode.nvim",
	-- build = ":TSUpdate html", -- if you have `nvim-treesitter` installed
	lazy = false,
	dependencies = {
		"folke/snacks.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
	},
	keys = {
		{ "<leader>lq", "<cmd>Leet<cr>", desc = "LeetCode Menu" },
		{ "<leader>ll", "<cmd>Leet list<cr>", desc = "LeetCode List All" },
		{ "<leader>le", "<cmd>Leet list difficulty=easy<cr>", desc = "LeetCode Easy" },
		{ "<leader>lm", "<cmd>Leet list difficulty=medium<cr>", desc = "LeetCode Medium" },
		{ "<leader>lh", "<cmd>Leet list difficulty=hard<cr>", desc = "LeetCode Hard" },
		{ "<leader>ld", "<cmd>Leet daily<cr>", desc = "LeetCode Daily" },
		{ "<leader>lr", "<cmd>Leet random<cr>", desc = "LeetCode Random" },
		{ "<leader>lc", "<cmd>Leet console<cr>", desc = "LeetCode Console" },
		{ "<leader>li", "<cmd>Leet info<cr>", desc = "LeetCode Info" },
		{ "<leader>ls", "<cmd>Leet submit<cr>", desc = "LeetCode Submit" },
		{ "<leader>lt", "<cmd>Leet run<cr>", desc = "LeetCode Test/Run" },
	},
	config = function(_, opts)
		local home = opts.storage.home
		local cache = opts.storage.cache
		vim.fn.mkdir(home, "p")
		vim.fn.mkdir(cache, "p")
		require("leetcode").setup(opts)
	end,
	---@module 'leetcode'
	opts = {
		lang = "golang",
		picker = {
			provider = nil,
		},
		storage = {
			home = vim.fn.expand("~/projects/unsortedProjects/DSA/leetcode/"),
			cache = vim.fn.expand("~/projects/unsortedProjects/DSA/leetcode/cache/"),
		},
		hooks = {
			["enter"] = {},
			["question_enter"] = {},
		},
	},
}
