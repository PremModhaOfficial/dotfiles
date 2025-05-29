return { -- Autocompletion
	"saghen/blink.cmp",
	lazy = false, -- lazy loading handled internally
	dependencies = {
		"Kaiser-Yang/blink-cmp-avante",
		"hrsh7th/nvim-cmp", -- Add nvim-cmp as a dependency

	{
		"saghen/blink.compat",
		---@module 'blink.compat'
		---@type blink.compat.Config
		opts = {
			impersonate_nvim_cmp = true,
			debug = false,
		},
	},
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
		"zbirenbaum/copilot-cmp",
		"mikavilpas/blink-ripgrep.nvim",
		"giuxtaposition/blink-cmp-copilot",
	},
	version = "v1.*",

 	---@module 'blink.cmp'
 	---@type blink.cmp.Config
 	opts = {
 		fuzzy = {
 			implementation = "prefer_rust_with_warning",
 			max_typos = function(keyword) return math.floor(#keyword / 4) end,
 			use_frecency = true,
 			use_proximity = true,
 		},
 		cmdline = {
			enabled = false,

			keymap = {

				preset = "cmdline",
				["<C-j>"] = { "select_next", "fallback" },
				["<C-k>"] = { "select_prev", "fallback" },
				["<c-f>"] = {
					function()
						require("blink-cmp").show({ providers = { "ripgrep" } })
					end,
				},
				-- ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				-- ["<Tab>"] = { "show", "select_next", "fallback" },
				--
				-- ["<C-e>"] = { "hide" },
				["<CR>"] = { "accept", "fallback" },
			},
			sources = function()
				local type = vim.fn.getcmdtype()
				-- Search forward and backward
				if type == "/" or type == "?" then
					return { "buffer" }
				end
				-- Commands
				if type == ":" or type == "@" then
					return { "cmdline" }
				end
				return {}
			end,
			completion = {
				list = {
					selection = {
						auto_insert = false,
						preselect = false,
					},
				},

				trigger = {
					show_on_blocked_trigger_characters = {},
					show_on_x_blocked_trigger_characters = nil, -- Inherits from top level `completion.trigger.show_on_blocked_trigger_characters` config when not set
				},
				menu = {
					auto_show = nil, -- Inherits from top level `completion.menu.auto_show` config when not set
					draw = {
						columns = { { "label", "label_description", gap = 1 } },
					},
				},
			},
		},
		keymap = {
			-- ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-t>"] = { "show", "show_documentation", "hide_documentation" },

			["<C-e>"] = { "hide" },
			["<C-y>"] = { "select_and_accept" },
			-- ["<C-CR>"] = { "accept", "fallback" },

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
				-- winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
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
					-- winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
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
				-- winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder",
				scrollbar = false, -- Note that the gutter will be disabled when border ~= 'none'
				direction_priority = { "n", "s" },
				treesitter_highlighting = true,
				show_documentation = true,
			},
		},

		sources = {
			default = function()
				local sources = { "lsp", "path", "snippets", "buffer", "lazydev" }

				-- Conditionally add AI sources if available
				if package.loaded["blink-cmp-copilot"] then
					table.insert(sources, "copilot")
				end

				-- Add avante if available
				if package.loaded["blink-cmp-avante"] then
					table.insert(sources, "avante")
				end

				-- Add codecompanion if available
				if package.loaded["codecompanion"] then
					table.insert(sources, "codecompanion")
				end

				return sources
			end,
			providers = {
				lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 1000 },
				avante = {
					module = "blink-cmp-avante",
					name = "Avante",
					opts = {
						-- options for blink-cmp-avante
					},
				},
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
					opts = {
						prefix_min_len = 3,
						backend = {
							use = "ripgrep",
							ripgrep = {
								max_filesize = "2M",
								additional_args = { "--hidden", "--no-ignore" },
							},
						},
					},
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
					max_items = 5,
					module = "blink.cmp.sources.buffer",
					min_keyword_length = 3,
					score_offset = 10,
				},
				snippets = {
					name = "snippets",
					enabled = true,
					max_items = 8,
					min_keyword_length = 2,
					module = "blink.cmp.sources.snippets",
					score_offset = 85,  -- Lower than LSP (90) to prioritize actual completions
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
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
		},
	},
	opts_extend = { "sources.default" },
}
