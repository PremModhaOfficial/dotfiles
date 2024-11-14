return { -- Autocompletion
	"saghen/blink.cmp",
	lazy = false, -- lazy loading handled internally
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	version = "v0.*",

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {},
	opts_extend = { "sources.completion.enabled_providers" },
	config = function()
		local blink_cmp = require("blink.cmp")
		blink_cmp.setup({
			signature_help = {
				enabled = true,
			},

			windows = {
				autocomplete = {
					border = "shadow",
					auto_show = true,
					draw = "reversed",
				},
				documentation = { border = "rounded", auto_show = true },
			},
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

			keymap = {
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide" },
				["<C-y>"] = { "select_and_accept" },
				["<CR>"] = { "accept", "fallback" },

				["<S-Tab>"] = { "select_prev", "fallback" },
				["<C-k>"] = { "select_prev", "fallback" },

				["<Tab>"] = { "select_next", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },

				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },

				["<C-l>"] = { "snippet_forward", "fallback" },
				["<S-C-l>"] = { "snippet_backward", "fallback" },
			},
			highlight = {
				use_nvim_cmp_as_default = true,
			},
			draw = {
				padding = { 1, 0 },
				columns = { { "label", "label_description", gap = 1 }, { "kind", "kind_icon" } },
				components = {
					kind_icon = { width = { fill = true } },
				},
			},
			nerd_font_variant = "mono",
			accept = { auto_brackets = { enabled = true } },
			trigger = { signature_help = { enabled = true } },
		})
	end,
}
