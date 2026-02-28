-- Plugin: Ramilito/kubectl.nvim
-- Installed via store.nvim

return {
	"ramilito/kubectl.nvim",
	-- use a release tag to download pre-built binaries
	version = "2.*",
	-- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
	-- build = 'make build',
	-- OR if you use nix, build from source with:
	-- build = 'nix run .#build-plugin',
	dependencies = "saghen/blink.download",
	config = function()
		require("kubectl").setup({})

		vim.keymap.set(
			"n",
			"<leader>k",
			'<cmd>lua require("kubectl").toggle({ tab = true })<cr>',
			{ noremap = true, silent = true, desc = "kubectl: toggle (tab)" }
		)
	end,
}
