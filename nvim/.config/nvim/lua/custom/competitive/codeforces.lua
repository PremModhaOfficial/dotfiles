return {
	"yunusey/codeforces-nvim",
	dependencies = { "nvim-lua/plenary.nvim" }, -- optional, used for testing
	config = function()
		vim.keymap.set("n", "<leader>ce", ":EnterContest ", {})
		vim.keymap.set("n", "<leader>ct", "<CMD>TestCurrent<CR>", {})
		vim.keymap.set("n", "<leader>cT", "<CMD>CreateTestCase<CR>", {})

		require("codeforces-nvim").setup({
			use_term_toggle = true,
			cf_path = "/home/prm/projects/competitive_programming/codeforces/",
			timeout = 15000,
			compiler = {
				py = {},
				-- cpp = { "g++", "@.cpp", "-o", "@" },
			},
			run = {
				py = { "python3", "@.py" },
				-- cpp = { "@" },
			},
			notify = function(title, message, type)
				local notify = require("snacks").notifier
				if message == nil then
					notify(title, type, {
						render = "minimal",
					})
				else
					notify(message, type, {
						title = title,
					})
				end
			end,
		})
	end,
}
