return {
	"christoomey/vim-tmux-navigator",
	lazy = false,
	vim.keymap.set("n", "<C-h>", ":TmuxNavigateLeft<CR>", { noremap = true, silent = true }),
	vim.keymap.set("n", "<C-j>", ":TmuxNavigateDown<CR>", { noremap = true, silent = true }),
	vim.keymap.set("n", "<C-k>", ":TmuxNavigateUp<CR>", { noremap = true, silent = true }),
	vim.keymap.set("n", "<C-l>", ":TmuxNavigateRight<CR>", { noremap = true, silent = true }),
}
