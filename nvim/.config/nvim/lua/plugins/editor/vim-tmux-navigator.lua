return {
	"christoomey/vim-tmux-navigator",
	lazy = false,
	config = function()
		-- Disable tmux navigation in specific contexts to avoid conflicts
		local disabled_filetypes = {
			"TelescopePrompt",
			"codecompanion",
			"Avante",
		}

		vim.keymap.set("n", "<C-h>", function()
			if vim.tbl_contains(disabled_filetypes, vim.bo.filetype) then
				vim.cmd("normal! h")
			else
				vim.cmd("TmuxNavigateLeft")
			end
		end, { noremap = true, silent = true })

		vim.keymap.set("n", "<C-j>", function()
			if vim.tbl_contains(disabled_filetypes, vim.bo.filetype) then
				vim.cmd("normal! j")
			else
				vim.cmd("TmuxNavigateDown")
			end
		end, { noremap = true, silent = true })

		vim.keymap.set("n", "<C-k>", function()
			if vim.tbl_contains(disabled_filetypes, vim.bo.filetype) then
				vim.cmd("normal! k")
			else
				vim.cmd("TmuxNavigateUp")
			end
		end, { noremap = true, silent = true })

		vim.keymap.set("n", "<C-l>", function()
			if vim.tbl_contains(disabled_filetypes, vim.bo.filetype) then
				vim.cmd("normal! l")
			else
				vim.cmd("TmuxNavigateRight")
			end
		end, { noremap = true, silent = true })
	end,
}
