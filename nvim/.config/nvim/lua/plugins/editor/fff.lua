-- ============================================================================
-- PLUGIN: fff.nvim
-- PURPOSE: Rust-backed frecency file picker + live grep. Primary over snacks.
-- DEPENDENCIES: rustup OR prebuilt binary auto-downloaded by build step
-- ============================================================================

return {
	"dmtrKovalenko/fff.nvim",
	build = function()
		require("fff.download").download_or_build_binary()
	end,
	opts = {
		debug = {
			enabled = false,
			show_scores = false,
		},
	},
	keys = {
		{
			"<leader>sf",
			function()
				require("fff").find_files()
			end,
			desc = "Find Files (fff)",
		},
		{
			"<leader>sF",
			function()
				local fuzzy = require("fff.core").ensure_initialized()
				local ok, git_root = pcall(fuzzy.get_git_root)
				if ok and git_root then
					require("fff").find_files_in_dir(git_root)
				else
					vim.notify("Not in a git repository", vim.log.levels.WARN)
				end
			end,
			desc = "Find Files in Git Root (fff)",
		},
		{
			"<leader>sG",
			function()
				require("fff").live_grep()
			end,
			desc = "Live Grep (fff)",
		},
		{
			"<leader>fw",
			function()
				require("fff").live_grep({ query = vim.fn.expand("<cword>") })
			end,
			desc = "Live Grep word under cursor (fff)",
		},
	},
}
