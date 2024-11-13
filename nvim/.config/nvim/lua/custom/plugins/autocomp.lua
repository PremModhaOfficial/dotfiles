return { -- Autocompletion
	"saghen/blink.cmp",
	lazy = false, -- lazy loading handled internally
	dependencies = "rafamadriz/friendly-snippets",
	version = "v0.*",
	opts = {
		keymap = { preset = "default" },
		highlight = {
			use_nvim_cmp_as_default = true,
		},
		nerd_font_variant = "mono",
		accept = { auto_brackets = { enabled = true } },
		trigger = { signature_help = { enabled = true } },
	},
	opts_extend = { "sources.completion.enabled_providers" },
	config = function()
		local blink_cmp = require("blink.cmp")
		blink_cmp.setup({
			keymap = { preset = "default" },
			highlight = {
				use_nvim_cmp_as_default = true,
			},
			nerd_font_variant = "mono",
			accept = { auto_brackets = { enabled = true } },
			trigger = { signature_help = { enabled = true } },
		})
	end,
}
