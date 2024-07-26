local module = {}
		--------
function module.apply_colors(config)
		--------
	config.colors = {
		--------
		foreground = "#F2EEF6",
		background = "#020004",
---		cursor_bg = "#9534DA",
---		cursor_fg = "#F2EEF6",
---		cursor_border = "#E4DEEB",
		--------
		brights = {
		--------
			"#020004",
			"#501A8E",
			"#471B97",
			"#5820B1",
			"#6023C2",
			"#9534DA",
			"#A268E3",
			"#E4DEEB",
		--------
		},
		--------
		ansi = {
		--------
			"#9F9BA4",
			"#7022BE",
			"#5F25CB",
			"#7C3DDB",
			"#9056E0",
			"#BC82E8",
			"#DAC2F4",
			"#E4DEEB",
		--------
		},
		--------
	}
end

return module

