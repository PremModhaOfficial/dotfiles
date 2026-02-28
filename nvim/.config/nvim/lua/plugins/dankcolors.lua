return {
	{
		"RRethy/base16-nvim",
		priority = 1000,
		config = function()
			require('base16-colorscheme').setup({
				base00 = '#17130b',
				base01 = '#17130b',
				base02 = '#959189',
				base03 = '#959189',
				base04 = '#f1ece2',
				base05 = '#fffcf8',
				base06 = '#fffcf8',
				base07 = '#fffcf8',
				base08 = '#ffa299',
				base09 = '#ffa299',
				base0A = '#fddb8a',
				base0B = '#aeffa0',
				base0C = '#ffedc2',
				base0D = '#fddb8a',
				base0E = '#ffe3a0',
				base0F = '#ffe3a0',
			})

			vim.api.nvim_set_hl(0, 'Visual', {
				bg = '#959189',
				fg = '#fffcf8',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Statusline', {
				bg = '#fddb8a',
				fg = '#17130b',
			})
			vim.api.nvim_set_hl(0, 'LineNr', { fg = '#959189' })
			vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#ffedc2', bold = true })

			vim.api.nvim_set_hl(0, 'Statement', {
				fg = '#ffe3a0',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Keyword', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Repeat', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Conditional', { link = 'Statement' })

			vim.api.nvim_set_hl(0, 'Function', {
				fg = '#fddb8a',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Macro', {
				fg = '#fddb8a',
				italic = true
			})
			vim.api.nvim_set_hl(0, '@function.macro', { link = 'Macro' })

			vim.api.nvim_set_hl(0, 'Type', {
				fg = '#ffedc2',
				bold = true,
				italic = true
			})
			vim.api.nvim_set_hl(0, 'Structure', { link = 'Type' })

			vim.api.nvim_set_hl(0, 'String', {
				fg = '#aeffa0',
				italic = true
			})

			vim.api.nvim_set_hl(0, 'Operator', { fg = '#f1ece2' })
			vim.api.nvim_set_hl(0, 'Delimiter', { fg = '#f1ece2' })
			vim.api.nvim_set_hl(0, '@punctuation.bracket', { link = 'Delimiter' })
			vim.api.nvim_set_hl(0, '@punctuation.delimiter', { link = 'Delimiter' })

			vim.api.nvim_set_hl(0, 'Comment', {
				fg = '#959189',
				italic = true
			})

			local current_file_path = vim.fn.stdpath("config") .. "/lua/plugins/dankcolors.lua"
			if not _G._matugen_theme_watcher then
				local uv = vim.uv or vim.loop
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
