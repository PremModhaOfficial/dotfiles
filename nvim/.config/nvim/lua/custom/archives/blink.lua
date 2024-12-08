return { -- Autocompletion
	"saghen/blink.cmp",
	lazy = false, -- lazy loading handled internally
	dependencies = {
		"rafamadriz/friendly-snippets",
		"hrsh7th/nvim-cmp", -- Add nvim-cmp as a dependency
		-- "saghen/blink.compat", "zbirenbaum/copilot-cmp",
	},
	version = "v0.*",

	opts_extend = { "sources.completion.enabled_providers" },
	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
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
		completion = {
			accept = { auto_brackets = { enabled = true } },
			menu = {
				enabled = true,
				border = "rounded",
				winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
				scrolloff = 2,
				scrollbar = true,
				direction_priority = { "s", "n" },
				auto_show = true,
				draw = {
					align_to_component = "label", -- or 'none' to disable
					padding = 1,
					gap = 1,
					treesitter = true,
					columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
					-- for a setup similar to nvim-cmp: https://github.com/Saghen/blink.cmp/pull/245#issuecomment-2463659508
					-- columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 500,
				-- Delay before updating the documentation window when selecting a new item,
				-- while an existing item is still visible
				update_delay_ms = 50,
				-- Whether to use treesitter highlighting, disable if you run into performance issues
				treesitter_highlighting = true,
				window = {
					border = "rounded",
					winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None",
					scrollbar = true,
				},
			},
			ghost_text = {
				enabled = false,
			},
		},

		-- Experimental signature help support
		signature = {
			enabled = true,
			window = {
				border = "double",
				winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder",
				scrollbar = false, -- Note that the gutter will be disabled when border ~= 'none'
				direction_priority = { "n", "s" },
				treesitter_highlighting = true,
			},
		},

		sources = {
			providers = {
				-- dont show LuaLS require statements when lazydev has items
				lsp = { fallback_for = { "lazydev" } },
				lazydev = { name = "LazyDev", module = "lazydev.integrations.blink" },
			},
			completion = {
				enabled_providers = { "lsp", "path", "snippets", "buffer", "lazydev" },

				-- Example dynamically picking providers based on the filetype and treesitter node:
				-- enabled_providers = function(ctx)
				--   local node = vim.treesitter.get_node()
				--   if vim.bo.filetype == 'lua' then
				--     return { 'lsp', 'path' }
				--   elseif node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }), node:type())
				--     return { 'buffer' }
				--   else
				--     return { 'lsp', 'path', 'snippets', 'buffer' }
				--   end
				-- end
			},
		},

		appearance = {
			highlight_ns = vim.api.nvim_create_namespace("blink_cmp"),
			-- Sets the fallback highlight groups to nvim-cmp's highlight groups
			-- Useful for when your theme doesn't support blink.cmp
			-- Will be removed in a future release
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
		},
	},
}
