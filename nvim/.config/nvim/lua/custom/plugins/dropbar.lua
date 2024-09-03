return {
	"Bekaboo/dropbar.nvim",
	-- optional, but required for fuzzy finder support
	dependencies = {
		"nvim-telescope/telescope-fzf-native.nvim",
	},
	opts = {
		bar = {
			hover = true,
			---@type dropbar_source_t[]|fun(buf: integer, win: integer): dropbar_source_t[]
			sources = function(buf, _)
				local sources = require("dropbar.sources")
				if vim.bo[buf].ft == "markdown" then
					return {
						sources.path,
						sources.markdown,
					}
				end
				if vim.bo[buf].buftype == "terminal" then
					return {
						sources.terminal,
					}
				end
				return {
					sources.path,
					utils.source.fallback({
						sources.lsp,
						sources.treesitter,
					}),
				}
			end,
			padding = {
				left = 1,
				right = 1,
			},
			pick = {
				pivots = "abcdefghijklmnopqrstuvwxyz",
			},
			truncate = true,
		},
		sources = {
			path = {
				---@type string|fun(buf: integer, win: integer): string
				relative_to = function(_, win)
					-- Workaround for Vim:E5002: Cannot find window number
					local ok, cwd = pcall(vim.fn.getcwd, win)
					return ok and cwd or vim.fn.getcwd()
				end,
				---Can be used to filter out files or directories
				---based on their name
				---@type fun(name: string): boolean
				filter = function(_)
					return true
				end,
				---Last symbol from path source when current buf is modified
				---@param sym dropbar_symbol_t
				---@return dropbar_symbol_t
				modified = function(sym)
					return sym
				end,
				---@type boolean|fun(path: string): boolean?|nil
				preview = function(path)
					local stat = vim.uv.fs_stat(path)
					if not stat or stat.type ~= "file" then
						return false
					end
					if stat.size > 524288 then
						vim.notify(
							string.format('[dropbar.nvim] file "%s" too large to preview', path),
							vim.log.levels.WARN
						)
						return false
					end
					return true
				end,
			},
			treesitter = {
				-- Lua pattern used to extract a short name from the node text
				name_pattern = "[#~%*%w%._%->!@:]+%s*" .. string.rep("[#~%*%w%._%->!@:]*", 3, "%s*"),
				-- The order matters! The first match is used as the type
				-- of the treesitter symbol and used to show the icon
				-- Types listed below must have corresponding icons
				-- in the `icons.kinds.symbols` table for the icon to be shown
				valid_types = {
					"array",
					"boolean",
					"break_statement",
					"call",
					"case_statement",
					"class",
					"constant",
					"constructor",
					"continue_statement",
					"delete",
					"do_statement",
					"enum",
					"enum_member",
					"event",
					"for_statement",
					"function",
					"h1_marker",
					"h2_marker",
					"h3_marker",
					"h4_marker",
					"h5_marker",
					"h6_marker",
					"if_statement",
					"interface",
					"keyword",
					"list",
					"macro",
					"method",
					"module",
					"namespace",
					"null",
					"number",
					"operator",
					"package",
					"pair",
					"property",
					"reference",
					"repeat",
					"scope",
					"specifier",
					"string",
					"struct",
					"switch_statement",
					"type",
					"type_parameter",
					"unit",
					"value",
					"variable",
					"while_statement",
					"declaration",
					"field",
					"identifier",
					"object",
					"statement",
					"text",
				},
			},
			lsp = {
				request = {
					-- Times to retry a request before giving up
					ttl_init = 60,
					interval = 1000, -- in ms
				},
			},
			markdown = {
				parse = {
					-- Number of lines to update when cursor moves out of the parsed range
					look_ahead = 200,
				},
			},
		},
	},
	config = function()
		-- vim.ui.select = require("dropbar.utils.menu").select
		local bar = require("dropbar.utils.bar")
		require("which-key").add({
			{
				"<leader>cc",
				function()
					bar.get_current()
				end,
				desc = "Toggle Dropbar",
			},
		})
	end,
}
