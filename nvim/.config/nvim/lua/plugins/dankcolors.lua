return {
	{
		"RRethy/base16-nvim",
		priority = 1000,
		config = function()
			require('base16-colorscheme').setup({
				base00 = '#19120c',
				base01 = '#19120c',
				base02 = '#a59e98',
				base03 = '#a59e98',
				base04 = '#fff6ef',
				base05 = '#fffbf8',
				base06 = '#fffbf8',
				base07 = '#fffbf8',
				base08 = '#ffa09b',
				base09 = '#ffa09b',
				base0A = '#ffc18d',
				base0B = '#b1ffa1',
				base0C = '#ffdec3',
				base0D = '#ffc18d',
				base0E = '#ffcca1',
				base0F = '#ffcca1',
			})

			vim.api.nvim_set_hl(0, 'Visual', {
				bg = '#a59e98',
				fg = '#fffbf8',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Statusline', {
				bg = '#ffc18d',
				fg = '#19120c',
			})
			vim.api.nvim_set_hl(0, 'LineNr', { fg = '#a59e98' })
			vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#ffdec3', bold = true })

			vim.api.nvim_set_hl(0, 'Statement', {
				fg = '#ffcca1',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Keyword', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Repeat', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Conditional', { link = 'Statement' })

			vim.api.nvim_set_hl(0, 'Function', {
				fg = '#ffc18d',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Macro', {
				fg = '#ffc18d',
				italic = true
			})
			vim.api.nvim_set_hl(0, '@function.macro', { link = 'Macro' })

			vim.api.nvim_set_hl(0, 'Type', {
				fg = '#ffdec3',
				bold = true,
				italic = true
			})
			vim.api.nvim_set_hl(0, 'Structure', { link = 'Type' })

			vim.api.nvim_set_hl(0, 'String', {
				fg = '#b1ffa1',
				italic = true
			})

			vim.api.nvim_set_hl(0, 'Operator', { fg = '#fff6ef' })
			vim.api.nvim_set_hl(0, 'Delimiter', { fg = '#fff6ef' })
			vim.api.nvim_set_hl(0, '@punctuation.bracket', { link = 'Delimiter' })
			vim.api.nvim_set_hl(0, '@punctuation.delimiter', { link = 'Delimiter' })

			vim.api.nvim_set_hl(0, 'Comment', {
				fg = '#a59e98',
				italic = true
			})

			local current_file_path = vim.fn.stdpath("config") .. "/lua/plugins/dankcolors.lua"
			if not _G._matugen_theme_watcher then
				local uv = vim.uv
				_G._matugen_theme_watcher = uv.new_fs_event()
				_G._matugen_theme_watcher:start(current_file_path, {}, vim.schedule_wrap(function()
					local new_spec = dofile(current_file_path)
					if new_spec and new_spec[1] and new_spec[1].config then
						new_spec[1].config()
						print("Theme reload")
					end
				end))
			end
		end
	}
}
