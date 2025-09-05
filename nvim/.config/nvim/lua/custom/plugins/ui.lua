return {
	{
		"uga-rosa/ccc.nvim",
		event = "VeryLazy",
		config = function()
			local ccc = require("ccc")
			local map = function(keys, func, desc)
				vim.keymap.set("n", keys, func, { desc = "ColorPicker: " .. desc })
			end
			map("<leader>cp", function()
				vim.cmd([[CccPick]])
			end, "Pick")

			local mapping = ccc.mapping
			ccc.setup({
				-- Your preferred settings
				-- Example: enable highlighter
				highlighter = {
					auto_enable = true,
					lsp = true,
				},
			})
		end,
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		-- enabled = false,
		opts = {
			notify = {
				enabled = false,  -- Let Snacks handle notifications
			},
			lsp = {
				progress = {
					enabled = true,
					-- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
					-- See the section on formatting for more details on how to customize.
					--- @type NoiceFormat|string
					format = "lsp_progress",
					--- @type NoiceFormat|string
					format_done = "lsp_progress_done",
					throttle = 1000 / 3, -- frequency to update lsp progress message
					view = "mini",
				},
				override = {
					-- override the default lsp markdown formatter with Noice
					["vim.lsp.util.convert_input_to_markdown_lines"] = false,
					-- override the lsp markdown formatter with Noice
					["vim.lsp.util.stylize_markdown"] = false,
					-- override cmp documentation with Noice (needs the other options to work)
					["cmp.entry.get_documentation"] = false,
				},
				hover = {
					enabled = false,
					silent = false, -- set to true to not show a message if hover is not available
					view = nil, -- when nil, use defaults from documentation
					---@type NoiceViewOptions
					opts = {}, -- merged with defaults from documentation
				},
				signature = {
					enabled = false,
					auto_open = {
						enabled = false,
						trigger = false, -- Automatically show signature help when typing a trigger character from the LSP
						luasnip = false, -- Will open signature help when jumping to Luasnip insert nodes
						throttle = 50, -- Debounce lsp signature help request by 50ms
					},
					view = nil, -- when nil, use defaults from documentation
					---@type NoiceViewOptions
					opts = {}, -- merged with defaults from documentation
				},
				message = {
					-- Messages shown by lsp servers
					enabled = true,
					view = "notify",
					opts = {},
				},
				documentation = {
					view = "hover",
					enabled = false,
					---@type NoiceViewOptions
					opts = {
						lang = "markdown",
						replace = true,
						render = "plain",
						format = { "{message}" },
						win_options = { concealcursor = "n", conceallevel = 3 },
					},
				},
			},
			routes = {
				{
					filter = {
						event = "msg_show",
						any = {
							{ find = "%d+L, %d+B" },
							{ find = "; after #%d+" },
							{ find = "; before #%d+" },
						},
					},
					view = "mini",
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
			},
		},
		  -- stylua: ignore
		keys = {
			{ "<leader>sN", "", desc = "+noice" },
			{ "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline", },
			{ "<leader>sNa", function() require("noice").cmd("all") end, desc = "Noice All", },
			{ "<leader>sNt", function() require("noice").cmd("pick") end, desc = "Noice Picker (Telescope/FzfLua)", },
			-- { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end,
			-- 	silent = true, expr = true, desc = "Scroll Forward", mode = { "i", "n", "s" }, },
			-- { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end
			-- 	end, silent = true, expr = true, desc = "Scroll Backward", mode = { "i", "n", "s" },
			-- },
		},
		config = function(_, opts)
			-- HACK: noice shows messages from before it was enabled,
			-- but this is not ideal when Lazy is installing plugins,
			-- so clear the messages in this case.
			if vim.o.filetype == "lazy" then
				vim.cmd([[messages clear]])
			end
			require("noice").setup(opts)
		end,
	},
}
