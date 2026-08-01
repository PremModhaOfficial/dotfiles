return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	keys = {
		{
			"<leader>e",
			function()
				require("harpoon"):list():add()
			end,
			desc = "harpoon add",
		},
		{
			"<C-e>",
			function()
				local harpoon = require("harpoon")
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end,
			desc = "harpoon quick menu",
		},
		{
			"<M-j>",
			function()
				require("harpoon"):list():select(1)
			end,
			desc = "harpoon select 1",
		},
		{
			"<M-k>",
			function()
				require("harpoon"):list():select(2)
			end,
			desc = "harpoon select 2",
		},
		{
			"<M-l>",
			function()
				require("harpoon"):list():select(3)
			end,
			desc = "harpoon select 3",
		},
		{
			"<M-h>",
			function()
				require("harpoon"):list():select(4)
			end,
			desc = "harpoon select 4",
		},
		{
			"<C-M-k>",
			function()
				require("harpoon"):list():prev()
			end,
			desc = "harpoon prev",
		},
		{
			"<C-M-j>",
			function()
				require("harpoon"):list():next()
			end,
			desc = "harpoon next",
		},
	},
	config = function()
		require("harpoon"):setup()
	end,
}
