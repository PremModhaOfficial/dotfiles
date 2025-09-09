return { -- Autocompletion
	"saghen/blink.cmp",
	lazy = false, -- lazy loading handled internally
	dependencies = {
		"Kaiser-Yang/blink-cmp-avante",
		"kristijanhusak/vim-dadbod-completion", --dada bot
		{
			"xzbdmw/colorful-menu.nvim",
			config = function()
				require("colorful-menu").setup({})
			end,
		},

		{
			"saghen/blink.compat",
			---@module 'blink.compat'
			---@type blink.compat.Config
			opts = {
				debug = true,
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

	config = function(_, opts)
		require("blink.cmp").setup(opts)

		-- Optimized highlight groups - reduced from 25+ to 8 essential groups
		local highlights = {
			-- Core completion kinds
			BlinkCmpKindText = { fg = "#a8c5f0", bg = "NONE" },
			BlinkCmpKindMethod = { fg = "#85d3f2", bg = "NONE" },
			BlinkCmpKindFunction = { fg = "#85d3f2", bg = "NONE" },
			BlinkCmpKindConstructor = { fg = "#f19c65", bg = "NONE" },
			BlinkCmpKindField = { fg = "#c49ec4", bg = "NONE" },
			BlinkCmpKindVariable = { fg = "#dfb3e6", bg = "NONE" },
			BlinkCmpKindClass = { fg = "#f19c65", bg = "NONE" },
			BlinkCmpKindInterface = { fg = "#f19c65", bg = "NONE" },
			BlinkCmpKindModule = { fg = "#a8c5f0", bg = "NONE" },
			BlinkCmpKindProperty = { fg = "#c49ec4", bg = "NONE" },
			BlinkCmpKindUnit = { fg = "#f19c65", bg = "NONE" },
			BlinkCmpKindValue = { fg = "#f19c65", bg = "NONE" },
			BlinkCmpKindEnum = { fg = "#f19c65", bg = "NONE" },
			BlinkCmpKindKeyword = { fg = "#dfafdf", bg = "NONE" },
			BlinkCmpKindSnippet = { fg = "#7ee787", bg = "NONE" },
			BlinkCmpKindColor = { fg = "#f19c65", bg = "NONE" },
			BlinkCmpKindFile = { fg = "#a8c5f0", bg = "NONE" },
			BlinkCmpKindReference = { fg = "#c49ec4", bg = "NONE" },
			BlinkCmpKindFolder = { fg = "#a8c5f0", bg = "NONE" },
			BlinkCmpKindEnumMember = { fg = "#85d3f2", bg = "NONE" },
			BlinkCmpKindConstant = { fg = "#f19c65", bg = "NONE" },
			BlinkCmpKindStruct = { fg = "#f19c65", bg = "NONE" },
			BlinkCmpKindEvent = { fg = "#c49ec4", bg = "NONE" },
			BlinkCmpKindOperator = { fg = "#85d3f2", bg = "NONE" },
			BlinkCmpKindTypeParameter = { fg = "#f19c65", bg = "NONE" },
			
			-- AI provider highlights
			BlinkCmpKindCopilot = { fg = "#6cc644", bg = "NONE" },
			BlinkCmpKindCodeCompanion = { fg = "#f19c65", bg = "NONE" },
			BlinkCmpKindAvante = { fg = "#85d3f2", bg = "NONE" },
		}

		-- Apply highlights efficiently
		for hl_group, hl_config in pairs(highlights) do
			vim.api.nvim_set_hl(0, hl_group, hl_config)
		end
	end,

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		-- Performance optimizations for v1.7.0
		performance = {
			max_view_entries = 200,
			debounce = 60,
			throttle = 32,
			fetch_timeout = 500,
		},
		
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
				lua = { "lsp", "path", "snippets", "buffer", "luasnip" },
				javascript = { "lsp", "path", "snippets", "buffer", "npm" },
				typescript = { "lsp", "path", "snippets", "buffer", "npm" },
				python = { "lsp", "path", "snippets", "buffer", "jedi" },
				rust = { "lsp", "path", "snippets", "buffer", "crates" },
				go = { "lsp", "path", "snippets", "buffer", "go_packages" },
			},
			providers = {
				lsp = {
					name = "LSP",
					module = "blink.cmp.sources.lsp",
					fallback_for = { "lsp" },
				},
				path = {
					name = "Path",
					module = "blink.cmp.sources.path",
					score_offset = 3,
				},
				snippets = {
					name = "Snippets",
					module = "blink.cmp.sources.snippets",
					score_offset = 5,
				},
				buffer = {
					name = "Buffer",
					module = "blink.cmp.sources.buffer",
					fallback_for = { "buffer" },
					max_items = 5,
					min_length = 2,
				},
				-- AI providers with optimized scoring
				avante = {
					name = "Avante",
					module = "blink-cmp-avante",
					score_offset = 10,
					async = true,
				},
				codecompanion = {
					name = "CodeCompanion",
					module = "blink-cmp-codecompanion",
					score_offset = 9,
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
						preselect = true,
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
			["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide" },
			["<C-y>"] = { "accept" },
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
			
			-- AI provider shortcuts
			["<C-a>"] = {
				function()
					require("blink.cmp").show({
						providers = { "avante", "codecompanion", "copilot" },
					})
				end,
				"fallback",
			},
			["<C-g>"] = {
				function()
					require("blink.cmp").show({
						providers = { "codecompanion" },
					})
				end,
				"fallback",
			},
		},
		
		completion = {
			accept = {
				auto_brackets = {
					enabled = false, -- Let mini.pairs handle brackets
					semantic_token_resolution = {
						enabled = true,
					},
				},
				create_undo_point = true,
			},
			menu = {
				enabled = true,
				border = "rounded",
				scrolloff = 2,
				scrollbar = true,
				direction_priority = { "s", "n" },
				auto_show = function(ctx)
					if ctx.mode == "cmdline" then
						return false
					end
					
					-- Always show in AI plugin buffers
					local ai_filetypes = { "codecompanion", "Avante" }
					for _, ft in ipairs(ai_filetypes) do
						if vim.bo.filetype == ft then
							return true
						end
					end
					
					return ctx.mode ~= "cmdline"
				end,
				draw = {
					align_to = "label",
					padding = 1,
					gap = 1,
					treesitter = { "lsp", "snippets", "buffer" },
					columns = {
						{ "label", "label_description", gap = 1 },
						{
							"kind_icon",
							"kind",
							gap = 1,
						},
					},
				},
			},
			
			-- Ghost text and buffer caching optimizations
			ghost_text = {
				enabled = true,
				position = "inline",
			},
			
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 500,
				window = {
					border = "rounded",
				},
			},
		},
		
		-- Optimized highlight configuration
		highlight = {
			use_nvim_cmp_as_default = false,
		},
	},
}