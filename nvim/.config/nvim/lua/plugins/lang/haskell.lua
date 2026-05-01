return {
	"mrcjkb/haskell-tools.nvim",
	version = false,
	ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
	keys = {
		{
			"<localleader>e",
			"<cmd>HlsEvalAll<cr>",
			ft = "haskell",
			desc = "Evaluate All",
		},
		{
			"<localleader>h",
			function()
				require("haskell-tools").hoogle.hoogle_signature()
			end,
			ft = "haskell",
			desc = "Hoogle Signature",
		},
		{
			"<localleader>r",
			function()
				require("haskell-tools").repl.toggle()
			end,
			ft = "haskell",
			desc = "REPL (Package)",
		},
		{
			"<localleader>R",
			function()
				require("haskell-tools").repl.toggle(vim.api.nvim_buf_get_name(0))
			end,
			ft = "haskell",
			desc = "REPL (Buffer)",
		},
	},
}
