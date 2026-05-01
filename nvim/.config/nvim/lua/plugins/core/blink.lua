-- ============================================================================
-- PHASE 4: BLINK.CMP ENHANCEMENT - "GLASSY HUD" & SMART PERFORMANCE
-- ============================================================================

return { -- Autocompletion
	"saghen/blink.cmp",
	lazy = true,
	event = "InsertEnter",
	dependencies = {

		"kristijanhusak/vim-dadbod-completion", -- dada bot
		{
			"xzbdmw/colorful-menu.nvim",
			config = function()
				require("colorful-menu").setup({
					max_width = 60,
				})
			end,
		},
		{
			"saghen/blink.compat",
			opts = { debug = true },
		},
		{
			"folke/lazydev.nvim",
			ft = "lua",
			opts = {
				library = {
					{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				},
			},
		},
		{
			"L3MON4D3/LuaSnip",
			dependencies = { "rafamadriz/friendly-snippets" },
			version = "v2.*",
			build = "make install_jsregexp",
			config = function()
				require("luasnip.loaders.from_vscode").lazy_load()
			end,
		},
		"zbirenbaum/copilot-cmp",
		"mikavilpas/blink-ripgrep.nvim",
		"giuxtaposition/blink-cmp-copilot",
	},
	version = "v1.*",

	config = function(_, opts)
		require("blink.cmp").setup(opts)
	end,

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		fuzzy = {
			implementation = "rust",
			max_typos = function(keyword)
				return math.min(math.floor(#keyword / 3), 2) -- Max 2 typos
			end,
			frecency = { enabled = true },
			use_proximity = true,
			sorts = function(ctx)
				local filetype = vim.bo.filetype
				if filetype == "lua" then
					return { "exact", "score", "sort_text" }
				elseif filetype == "python" or filetype == "typescript" or filetype == "javascript" then
					return { "score", "sort_text", "label" }
				elseif filetype == "sql" then
					return { "score", "kind", "sort_text" }
				else
					return { "score", "sort_text" }
				end
			end,
			prebuilt_binaries = { download = true },
		},

		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
			per_filetype = {
				lua = { "lsp", "path", "snippets", "buffer", "lazydev", "ripgrep" },
				python = { "lsp", "path", "snippets", "buffer", "ripgrep" },
				typescript = { "lsp", "path", "snippets", "buffer", "ripgrep" },
				javascript = { "lsp", "path", "snippets", "buffer", "ripgrep" },
				jsx = { "lsp", "path", "snippets", "buffer", "ripgrep" },
				tsx = { "lsp", "path", "snippets", "buffer", "ripgrep" },
				sql = { "lsp", "path", "snippets", "buffer", "dadbod" },
				mysql = { "lsp", "path", "snippets", "buffer", "dadbod" },
				plsql = { "lsp", "path", "snippets", "buffer", "dadbod" },
				rust = { "lsp", "path", "snippets", "buffer", "ripgrep" },
				go = { "lsp", "path", "snippets", "buffer", "ripgrep" },
			leetcode = { "lsp", "path", "snippets", "buffer" },
			["leetcode.java"] = { "lsp", "path", "snippets", "buffer" },
			["leetcode.python"] = { "lsp", "path", "snippets", "buffer" },
			["leetcode.cpp"] = { "lsp", "path", "snippets", "buffer" },
		},
			providers = {
				lsp = {
					name = "LSP",
					module = "blink.cmp.sources.lsp",
					score_offset = 99,
				},
				path = {
					name = "Path",
					module = "blink.cmp.sources.path",
					score_offset = 3,
				},
				snippets = {
					name = "Snip",
					module = "blink.cmp.sources.snippets",
					score_offset = -5,
				},
				-- SMART BUFFER: Disabled on large files (>1.5MB)
				buffer = {
					name = "Buffer",
					module = "blink.cmp.sources.buffer",
					max_items = 3,
					min_keyword_length = 2,
					enabled = function()
						return vim.api.nvim_buf_get_offset(0, vim.api.nvim_buf_line_count(0)) < 1500000
					end,
				},
				lazydev = {
					name = "Lazy",
					module = "lazydev.integrations.blink",
					score_offset = 100,
				},
				dadbod = {
					name = "DB",
					module = "vim_dadbod_completion.blink",
					score_offset = 5,
				},
				copilot = {
					name = "AI",
					module = "blink-cmp-copilot",
					score_offset = 8,
					async = true,
				},
				codecompanion = {
					name = "AI",
					module = "codecompanion.providers.completion.blink",
					score_offset = 7,
					async = true,
					enabled = true,
				},
				-- SMART RIPGREP: Disabled on large files
				ripgrep = {
					name = "Rg",
					module = "blink-ripgrep",
					score_offset = 2,
					async = true,
					enabled = function()
						return vim.api.nvim_buf_get_offset(0, vim.api.nvim_buf_line_count(0)) < 1500000
					end,
				},
			},
		},

		cmdline = {
			enabled = true,
			keymap = {
				preset = "inherit",
				["<CR>"] = { "fallback" },
				["<C-j>"] = { "select_next", "fallback" },
				["<C-k>"] = { "select_prev", "fallback" },
				["<c-f>"] = {
					function()
						require("blink-cmp").show({ providers = { "ripgrep" } })
					end,
				},
			},
			sources = function()
				local type = vim.fn.getcmdtype()
				if type == "/" or type == "?" then
					return { "buffer" }
				end
				if type == ":" then
					local cmdline = vim.fn.getcmdline()
					if cmdline:match("^%s*[vg]rep") then
						return { "buffer" }
					else
						return { "cmdline" }
					end
				elseif type == "@" then
					return { "cmdline" }
				end
				return {}
			end,
			completion = {
				list = { selection = { auto_insert = false, preselect = false } },
				trigger = { show_on_blocked_trigger_characters = {} },
				menu = {
					draw = {
						columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
					},
				},
			},
		},

		keymap = {
			["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide" },
			["<C-y>"] = { "select_and_accept" },
			["<C-k>"] = { "select_prev" },
			["<C-j>"] = { "select_next" },
			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },
			["<C-l>"] = { "snippet_forward", "fallback" },
			["<S-C-l>"] = { "snippet_backward", "fallback" },
			["<M-c>"] = {
				function()
					require("blink.cmp").show({ providers = { "copilot" } })
				end,
				"fallback",
			},
			["<M-n>"] = {
				function()
					require("blink.cmp").show({ providers = { "codecompanion" } })
				end,
				"fallback",
			},
		},

		completion = {
			list = {
				selection = {
					auto_insert = false,
					preselect = false,
				},
			},
			accept = {
				auto_brackets = {
					enabled = false,
					semantic_token_resolution = { enabled = true },
				},
				create_undo_point = true,
			},
			menu = {
				border = { "", "", "", "▌", "", "", "", "▐" },
				scrolloff = 2,
				scrollbar = true,
				direction_priority = { "s", "n" },
				winblend = 0,
				auto_show = function(ctx)
					if ctx.mode == "cmdline" then
						return false
					end
					local ai_filetypes = { "codecompanion", "Avante" }
					for _, ft in ipairs(ai_filetypes) do
						if vim.bo.filetype == ft then
							return true
						end
					end
					return ctx.mode ~= "cmdline"
				end,
				draw = {
					padding = { 1, 1 },
					columns = {
						{ "kind_icon", gap = 1 },
						{ "label", "label_description", gap = 1 },
						{ "source_name" },
					},
					components = {
						label = {
							text = function(ctx)
								return require("colorful-menu").blink_components_text(ctx)
							end,
							highlight = function(ctx)
								return require("colorful-menu").blink_components_highlight(ctx)
							end,
						},
						source_name = {
							width = { max = 30 },
							text = function(ctx)
								return string.format("[%s]", ctx.source_name)
							end,
							highlight = "BlinkCmpSource",
						},
					},
				},
			},

			ghost_text = {
				enabled = true,
			},

			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200, -- Snappier (was 500ms)
				update_delay_ms = 50,
				window = {
					border = { "▀", "▀", "▀", " ", "▄", "▄", "▄", " " },
					winblend = 0,
				},
			},

			trigger = {
				show_on_insert = true,
				show_on_blocked_trigger_characters = {},
			},
		},

		signature = {
			enabled = true,
			window = {
				border = { "▀", "▀", "▀", " ", "▄", "▄", "▄", " " },
				scrollbar = false,
				direction_priority = { "n", "s" },
				show_documentation = true,
			},
		},
	},
}
