local trigger_text = ";"
return { -- Autocompletion
	"saghen/blink.cmp",
	lazy = false, -- lazy loading handled internally
	dependencies = {
		"hrsh7th/nvim-cmp", -- Add nvim-cmp as a dependency
		{
			"L3MON4D3/LuaSnip",
			dependencies = {
				"rafamadriz/friendly-snippets",
			},
			version = "v2.*",
			build = "make install_jsregexp",
			config = function()
				_ = require("luasnip.loaders.from_vscode").lazy_load()
			end,
		},
		{
			"saghen/blink.compat",
			---@module 'blink.compat'
			---@type blink.compat.Config
			opts = {
				impersonate_nvim_cmp = true,
				debug = false,
			},
		},
		"zbirenbaum/copilot-cmp",
		"mikavilpas/blink-ripgrep.nvim",
		"giuxtaposition/blink-cmp-copilot",
	},
	version = "v0.*",

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = {
			["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide" },
			["<C-y>"] = { "select_and_accept" },
			["<C-CR>"] = { "accept", "fallback" },

			-- ["<S-Tab>"] = { "select_prev", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<C-k>"] = { "select_prev", "fallback" },

			-- ["<Tab>"] = { "select_next", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
			["<C-j>"] = { "select_next", "fallback" },

			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },

			["<C-l>"] = { "snippet_forward", "fallback" },
			["<S-C-l>"] = { "snippet_backward", "fallback" },
			cmdline = {
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<Tab>"] = { "show", "select_next", "fallback" },

				["<C-e>"] = { "hide" },
				["<CR>"] = { "accept", "fallback" },
			},
		},
		completion = {
			accept = {
				auto_brackets = {
					enabled = true,
					-- blocked_filetypes = { "codecompanion" },
				},
				create_undo_point = true,
			},
			menu = {
				enabled = true,
				border = "rounded",
				winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
				scrolloff = 2,
				scrollbar = true,
				direction_priority = { "s", "n" },
				auto_show = function(ctx)
					return ctx.mode ~= "cmdline"
				end,
				draw = {
					align_to = "cursor", -- 'none',
					padding = 1,
					gap = 1,
					treesitter = { "lsp" },

					columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
					-- for a setup similar to nvim-cmp: https://github.com/Saghen/blink.cmp/pull/245#issuecomment-2463659508
					-- columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 } },
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
					winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
					scrollbar = true,
				},
			},
			ghost_text = {
				enabled = true,
				show_with_selection = true,
			},
			list = {
				selection = {
					auto_insert = false,
					preselect = true,
				},
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
				show_documentation = true,
			},
		},

		sources = {
			default = {
				"lsp",
				"path",
				"snippets",
				"buffer",
				"copilot",
				"dadbod",
				"lazydev",
				"ripgrep",
				"codecompanion",
			},
			cmdline = function()
				local type = vim.fn.getcmdtype()
				if type == "/" or type == "?" then
					return { "buffer" }
				end
				if type == ":" then
					return { "cmdline" }
				end
				return {}
			end,
			providers = {
				lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 1000 },
				codecompanion = {
					name = "CodeCompanion",
					module = "codecompanion.providers.completion.blink",
					-- kind = "CC",
					enabled = true,
					async = true,
				},
				ripgrep = {
					module = "blink-ripgrep",
					name = "Ripgrep",
					---@module "blink-ripgrep"
					---@type blink-ripgrep.Options
					opts = { prefix_min_len = 3, context_size = 5, max_filesize = "1M" },
				},
				lsp = {
					name = "lsp",
					enabled = true,
					module = "blink.cmp.sources.lsp",
					-- kind = "LSP",
					score_offset = 90, -- the higher the number, the higher the priority
				},
				-- luasnip = {
				-- 	name = "luasnip",
				-- 	module = "blink.cmp.sources.luasnip",
				-- 	min_keyword_length = 2,
				-- 	fallbacks = { "snippets" },
				-- 	score_offset = 85,
				-- 	max_items = 8,
				-- 	-- Only show luasnip items if I type the trigger_text characters, so
				-- 	-- to expand the "bash" snippet, if the trigger_text is ";" I have to
				-- 	-- type ";bash"
				-- 	-- After accepting the completion, delete the trigger_text characters
				-- 	-- from the final inserted text
				-- },
				path = {
					name = "Path",
					module = "blink.cmp.sources.path",
					score_offset = 3,
					-- When typing a path, I would get snippets and text in the
					-- suggestions, I want those to show only if there are no path
					-- suggestions
					-- fallbacks = { "luasnip", "buffer" },
					opts = {
						trailing_slash = true,
						label_trailing_slash = true,
						get_cwd = function(context)
							return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
						end,
						show_hidden_files_by_default = true,
					},
				},
				buffer = {
					name = "Buffer",
					enabled = true,
					max_items = 3,
					module = "blink.cmp.sources.buffer",
					min_keyword_length = 4,
				},
				snippets = {
					name = "snippets",
					enabled = true,
					max_items = 8,
					min_keyword_length = 1,
					module = "blink.cmp.sources.snippets",
					score_offset = 85, -- the higher the number, the higher the priority
					-- Only show snippets if I type the trigger_text characters, so
					-- to expand the "bash" snippet, if the trigger_text is ";" I have to
					-- type ";bash"
					should_show_items = function()
						local col = vim.api.nvim_win_get_cursor(0)[2]
						local before_cursor = vim.api.nvim_get_current_line():sub(1, col)
						-- NOTE: remember that `trigger_text` is modified at the top of the file
						return before_cursor:match(trigger_text .. "%w*$") ~= nil
					end,
					-- After accepting the completion, delete the trigger_text characters
					-- from the final inserted text
					transform_items = function(_, items)
						local col = vim.api.nvim_win_get_cursor(0)[2]
						local before_cursor = vim.api.nvim_get_current_line():sub(1, col)
						local trigger_pos = before_cursor:find(trigger_text .. "[^" .. trigger_text .. "]*$")
						if trigger_pos then
							for _, item in ipairs(items) do
								item.textEdit = {
									newText = item.insertText or item.label,
									range = {
										start = { line = vim.fn.line(".") - 1, character = trigger_pos - 1 },
										["end"] = { line = vim.fn.line(".") - 1, character = col },
									},
								}
							end
						end
						-- NOTE After the transformation, I have to reload the luasnip source
						-- Otherwise really crazy shit happens and I spent way too much time
						-- figurig this out
						vim.schedule(function()
							require("blink.cmp").reload("snippets")
						end)
						return items
					end,
				},
				dadbod = {
					name = "Dadbod",
					module = "vim_dadbod_completion.blink",
					score_offset = 85, -- the higher the number, the higher the priority
				},
				-- Third class citizen mf always talking shit
				copilot = {
					name = "copilot",
					enabled = true,
					module = "blink-cmp-copilot",
					-- kind = "Copilot",
					min_keyword_length = 6,
					score_offset = -100, -- the higher the number, the higher the priority
					async = true,
				},
			},
		},
		snippets = {
			preset = "luasnip",
			-- https://www.lazyvim.org/extras/coding/luasnip#blinkcmp-optional
			expand = function(snippet)
				require("luasnip").lsp_expand(snippet)
			end,
			active = function(filter)
				if filter and filter.direction then
					return require("luasnip").jumpable(filter.direction)
				end
				return require("luasnip").in_snippet()
			end,
			jump = function(direction)
				require("luasnip").jump(direction)
			end,
		},

		appearance = {
			highlight_ns = vim.api.nvim_create_namespace("blink_cmp"),
			-- Sets the fallback highlight groups to nvim-cmp's highlight groups
			-- Useful for when your theme doesn't support blink.cmp
			-- Will be removed in a future release
			use_nvim_cmp_as_default = false,
			nerd_font_variant = "mono",
		},
	},
	opts_extend = { "sources.default" },
}
