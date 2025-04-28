return {
	"winter-again/wezterm-config.nvim",
	enabled = false,
	filetype = { "lua" },
	config = function()
		-- changing this to true means the plugin will try to append
		-- $HOME/.config/wezterm' to your RTP, meaning you can more conveniently
		-- access modules in $HOME/.config/wezterm/lua/ for using with this plugin
		-- otherwise, store data where you want
		require("wezterm_config").setup({
			-- defaults:
			append_wezterm_to_rtp = true,
		})
	end,
}
