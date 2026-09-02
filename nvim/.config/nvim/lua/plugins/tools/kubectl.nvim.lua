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
	keys = {
		{
			"<leader>k",
			function()
				require("kubectl").toggle({ tab = false })
			end,
			desc = "kubectl: toggle",
		},
	},
	config = function()
		require("kubectl").setup({
			tab = false,
		})
	end,
}
