-- nvim v0.8.0
return {
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim", -- required
			"sindrets/diffview.nvim", -- optional - Diff integration
			-- Only one of these is needed, not both.
			"nvim-telescope/telescope.nvim", -- optional
		},
		config = function()
			require("neogit").setup({})
			require("which-key").add({
				{
					"<leader>gm",
					"<cmd>Neogit<cr>",
					desc = "Neogit",
				},
			})
		end,
	},
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		-- optional for floating window border decoration
		dependencies = {
			"nvim-lua/plenary.nvim",
			"lewis6991/gitsigns.nvim",
		},
		-- setting the keybinding for LazyGit with 'keys' is recommended in
		-- order to load the plugin when the command is run for the first time
		keys = {
			{ "<leader>gu", "<cmd>LazyGit<cr>", desc = "LazyGit" },
			{ "<leader>gc", "<cmd>Gitsigns preview_hunk<cr>", desc = "show line diff (Gitsigns)" },
			{
				"<leader>gb",
				"<cmd>Gitsigns toggle_current_line_blame<cr>",
				desc = "Gitsigns toggle current line blame",
			},
		},
	},
	{
		"tpope/vim-fugitive",
		config = function() end,
	},
}
