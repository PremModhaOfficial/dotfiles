return {
	"altermo/ultimate-autopair.nvim",
	event = { "InsertEnter", "CmdlineEnter" },
	branch = "v0.6", --recommended as each new version will have breaking changes
	opts = {
		space2 = { enable = true },
		space = { enable = true },
		close = { enable = true },
		tabout = { enable = true, imap = "<tab>" },
	},
}
