return { -- Autocompletion
	"saghen/blink.cmp",
	lazy = true,
	event = "InsertEnter",
	dependencies = {
		"Kaiser-Yang/blink-cmp-avante",
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
				return math.floor(#keyword / 2)
			end,
			frecency = { enabled = true },
			use_proximity = true,
			sorts = {
				"score",
				"sort_text",
			},
			-- Use optimized rust-based fuzzy matching
			prebuilt_binaries = {
				download = true,
			},
		},

		-- Enhanced source configuration with filetype-specific behavior
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
			per_filetype = {
				lua = { "lsp", "path", "snippets", "buffer", "lazydev" },
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
					name = "Snippets",
					module = "blink.cmp.sources.snippets",
					score_offset = -5,
				},
				buffer = {
					name = "Buffer",
					module = "blink.cmp.sources.buffer",
					max_items = 5,
					min_keyword_length = 2,
				},
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					score_offset = 100, -- show at a higher priority than lsp
				},
				avante = {
					name = "Avante",
					module = "blink-cmp-avante",
					score_offset = 10,
					async = true,
				},
				copilot = {
					name = "Copilot",
					module = "blink-cmp-copilot",
					score_offset = 8,
					async = true,
				},
			},
		},

		cmdline = {
			enabled = true,
			keymap = {
				preset = "inherit",
				["<CR>"] = { "fallback" }, -- Execute command without completing
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
				},
				menu = {
					draw = {
						columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
					},
				},
			},
		},

		-- Optimized keymap with AI-specific features
		keymap = {
			-- preset = "enter", DONT WANT THIS
			-- ["<Tab>"] = { "snippet_forward", "fallback" }, DONT WANT THIS
			["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide" },
			["<C-y>"] = { "select_and_accept" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<C-k>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
			["<C-j>"] = { "select_next", "fallback" },
			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },

			-- Multi-function forward key
			["<C-l>"] = {
				"snippet_forward",
				function()
					return require("sidekick").nes_jump_or_apply()
				end,
				function()
					return vim.lsp.inline_completion.get()
				end,
				"fallback",
			},
			["<S-C-l>"] = { "snippet_backward", "fallback" },

			["<C-a>"] = {
				function()
					require("blink.cmp").show({
						providers = { "avante", "copilot" },
					})
				end,
				"fallback",
			},
		},

		completion = {
			accept = {
				auto_brackets = {
					enabled = false, -- Use mini.pairs for bracket handling
					semantic_token_resolution = {
						enabled = true,
					},
				},
				create_undo_point = true,
			},
			menu = {
				border = "rounded",
				scrolloff = 2,
				scrollbar = true,
				direction_priority = { "s", "n" },
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
					columns = { { "kind_icon" }, { "label", gap = 1 } },
					components = {
						label = {
							text = function(ctx)
								return require("colorful-menu").blink_components_text(ctx)
							end,
							highlight = function(ctx)
								return require("colorful-menu").blink_components_highlight(ctx)
							end,
						},
					},
				},
			},

			-- Ghost text configuration
			ghost_text = {
				enabled = true,
			},

			documentation = {
				auto_show = true,
				auto_show_delay_ms = 500,
				window = {
					border = "rounded",
				},
			},
		},

		-- Signature help configuration
		signature = {
			enabled = true,
			window = {
				border = "double",
				scrollbar = false,
				direction_priority = { "n", "s" },
				treesitter_highlighting = true,
				show_documentation = false,
			},
		},
	},
}
