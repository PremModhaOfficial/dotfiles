return {
	"alex-popov-tech/store.nvim",
	dependencies = {
		{
			"OXY2DEV/markview.nvim",
			init = function()
				-- We use blink.cmp. Skip markview's legacy nvim-cmp source
				-- registration: it calls `cmp.setup.filetype(...)`, which
				-- blink.compat does not implement and warns about. Setting
				-- markview's own guard (markview/integrations.lua register_cmp_source)
				-- makes it return early while its blink.cmp source still registers.
				vim.g.markview_cmp_loaded = true
			end,
		},
	},
	cmd = "Store",
}
