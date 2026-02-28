return {
	"bluz71/vim-nightfly-colors",
	name = "nightfly",
	enabled = false,
	lazy = false,
	priority = 1000,
	config = function()
		vim.g.nightflyCursorColor = true
		vim.g.nightflyItalics = true
		vim.g.nightflyNormalFloat = true
		vim.g.nightflyTransparent = true
		-- The nightflyWinSeparator option specifies the style of window separators:
		--
		--     0 will display no window separators
		--
		--     1 will display block separators; this is the default
		--
		--     2 will diplay line separators
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
