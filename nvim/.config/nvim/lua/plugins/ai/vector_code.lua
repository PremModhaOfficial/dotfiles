return {
	"Davidyz/VectorCode",
	version = "*",
	build = "uv tool upgrade vectorcode", -- This helps keeping the CLI up-to-date
	-- build = "pipx upgrade vectorcode", -- If you used pipx to install the CLI
	dependencies = { "nvim-lua/plenary.nvim" },
}
