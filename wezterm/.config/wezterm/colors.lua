local module = {}
		--------
function module.apply_colors(config)
		--------
	config.colors = {
		--------
		foreground = "#E6E8E8",
		background = "#000000",
---		cursor_bg = "#65531B",
---		cursor_fg = "#E6E8E8",
---		cursor_border = "#5A2331",
		--------
		brights = {
		--------
			"#051719",
			"#A52B4A",
			"#73299D",
			"#912641",
			"#812245",
			"#65531B",
			"#65371B",
			"#5A2331",
		--------
		},
		--------
		ansi = {
		--------
			"#031011",
			"#CF496B",
			"#9A3DCC",
			"#C13357",
			"#AD2E5B",
			"#897124",
			"#894A24",
			"#1D0B10",
		--------
		},
		--------
	}
end

return module

