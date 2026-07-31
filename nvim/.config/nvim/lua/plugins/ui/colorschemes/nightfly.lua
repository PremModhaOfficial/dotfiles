return {
	"bluz71/vim-nightfly-colors",
	name = "nightfly",
	lazy = false,
	priority = 1000,
	config = function()
		vim.g.nightflyCursorColor = true
		vim.g.nightflyItalics = true
		vim.g.nightflyNormalFloat = true
		vim.g.nightflyTransparent = true
		vim.g.nightflyWinSeparator = 2
		vim.g.nightflyVirtualTextColor = true
		vim.g.nightflyUnderlineMatchParen = true
		vim.g.nightflyUndercurls = true
		vim.opt.fillchars = {
			horiz = "━",
			horizup = "┻",
			horizdown = "┳",
			vert = "┃",
			vertleft = "┫",
			vertright = "┣",
			verthoriz = "╋",
		}
	end,
}
