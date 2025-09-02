-- Enable undercurl support in Neovim
local M = {}

-- All the fancy diagnostic signs with undercurls
function M.setup()
	-- Enable terminal features
	vim.opt.termguicolors = true

	-- Define all diagnostic signs with undercurls
	local signs = { Error = "", Warn = "", Hint = "", Info = "" }

	-- Configure diagnostics appearance
	vim.diagnostic.config({
		virtual_text = {
			prefix = "●", -- Could be '■', '▎', 'x'
			hl_mode = "combine",
		},
		-- virtual_lines = true,
		signs = true,
		underline = true,
		update_in_insert = false,
		severity_sort = true,
	})

	-- Set diagnostic highlights with undercurls
	vim.cmd([[highlight DiagnosticUnderlineError gui=undercurl guisp=#FF5555]])
	vim.cmd([[highlight DiagnosticUnderlineWarn gui=undercurl guisp=#FFAA00]])
	vim.cmd([[highlight DiagnosticUnderlineInfo gui=undercurl guisp=#00AAFF]])
	vim.cmd([[highlight DiagnosticUnderlineHint gui=undercurl guisp=#00FF00]])
	vim.cmd([[highlight SpellBad gui=undercurl guisp=#FF5555]])
	vim.cmd([[highlight SpellCap gui=undercurl guisp=#00AAFF]])

	-- Set diagnostic signs
	for type, icon in pairs(signs) do
		local hl = "DiagnosticSign" .. type
		vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
	end
end

return M
