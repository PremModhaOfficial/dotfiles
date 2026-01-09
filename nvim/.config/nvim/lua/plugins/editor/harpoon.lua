return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local harpoon = require("harpoon")

		-- REQUIRED
		harpoon:setup()
		-- REQUIRED

		vim.keymap.set("n", "<leader>e", function()
			harpoon:list():add()
		end, { desc = "harpoon add" })
		vim.keymap.set("n", "<C-e>", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "harpoon quick menu" })

		vim.keymap.set("n", "<M-j>", function()
			harpoon:list():select(1)
		end, { desc = "harpoon select 1" })
		vim.keymap.set("n", "<M-k>", function()
			harpoon:list():select(2)
		end, { desc = "harpoon select 2" })
		vim.keymap.set("n", "<M-l>", function()
			harpoon:list():select(3)
		end, { desc = "harpoon select 3" })
		vim.keymap.set("n", "<M-h>", function()
			harpoon:list():select(4)
		end, { desc = "harpoon select 4" })

		-- Toggle previous & next buffers stored within Harpoon list
		vim.keymap.set("n", "<C-M-k>", function()
			harpoon:list():prev()
		end)
		vim.keymap.set("n", "<C-M-j>", function()
			harpoon:list():next()
		end)
	end,
}
