return { -- Autocompletion
	"saghen/blink.cmp",
	lazy = false, -- lazy loading handled internally
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	version = "v0.*",

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = { preset = "default" },
		draw = {
			padding = { 1, 0 },
			columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
			components = {
				kind_icon = { width = { fill = true } },
			},
		},
		signature_help = {
			enabled = true,
		},
		highlight = {
			use_nvim_cmp_as_default = true,
		},
		nerd_font_variant = "mono",
		accept = { auto_brackets = { enabled = true } },
		trigger = { signature_help = { enabled = true } },
		sources = {
			completion = {
				enabled_providers = { "lsp", "path", "snippets", "lazydev" },
			},
			providers = {
				-- dont show LuaLS require statements when lazydev has items
				lsp = { fallback_for = { "lazydev" } },
				lazydev = { name = "LazyDev", module = "lazydev.integrations.blink" },
			},
		},
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
