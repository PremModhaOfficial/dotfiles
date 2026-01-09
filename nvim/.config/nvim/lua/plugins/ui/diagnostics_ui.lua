return {
	"rachartier/tiny-inline-diagnostic.nvim",
	event = "VeryLazy",
	config = function()
		local function get_bg_hex()
			local hl = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
			local bg = hl.bg
			if bg then
				return string.format("#%06x", bg)
			end
			return "#000000" -- Fallback
		end

		local bg_color = get_bg_hex()

		require("tiny-inline-diagnostic").setup({
			preset = "modern",
			transparent_bg = false,
			transparent_cursorline = false,

			-- hi = {
			-- 	error = "#ff0000",
			-- 	warn = "#ffaa00",
			-- 	info = "#00d7ff",
			-- 	hint = "#d787ff",
			-- 	arrow = "#aaaaaa",
			-- 	background = bg_color,
			-- 	mixing_color = bg_color, -- Use background color instead of "None"
			-- },

			options = {
				show_source = {
					enabled = true,
					if_many = true,
				},
				use_icons_from_diagnostic = false,
				set_arrow_to_diag_color = true,
				add_messages = true,
				throttle = 20,
				softwrap = 30,
				multilines = {
					enabled = true,
					always_show = false,
					trim_whitespaces = false,
					tabstop = 4,
				},
				show_all_diags_on_cursorline = false,
				enable_on_insert = true,
				enable_on_select = false,
				overflow = {
					mode = "wrap",
					padding = 0,
				},
				break_line = {
					enabled = false,
					after = 30,
				},
				format = nil,
				virt_texts = {
					priority = 2048,
				},
				severity = {
					vim.diagnostic.severity.ERROR,
					vim.diagnostic.severity.WARN,
					vim.diagnostic.severity.INFO,
					vim.diagnostic.severity.HINT,
				},
				overwrite_events = nil,
			},
			disabled_ft = {},
		})

		vim.diagnostic.config({
			virtual_text = false,
			signs = true,
			underline = true,
			update_in_insert = true,
			severity_sort = true,
		})
	end,
}
