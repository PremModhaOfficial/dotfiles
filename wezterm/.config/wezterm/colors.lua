local module = {}
		--------
function module.apply_colors(config)
		--------
	config.colors = {
		--------
		foreground = "#ADDCE9",
		background = "#000006",
---		cursor_bg = "#144A6C",
---		cursor_fg = "#ADDCE9",
---		cursor_border = "#81C4D7",
		--------
		brights = {
		--------
			"#000014",
			"#170C45",
			"#2B0934",
			"#130F52",
			"#380A30",
			"#144A6C",
			"#196D86",
			"#81C4D7",
		--------
		},
		--------
		ansi = {
		--------
			"#5A8996",
			"#1E105A",
			"#3C0D49",
			"#18136C",
			"#490D3F",
			"#1B6493",
			"#2194B5",
			"#81C4D7",
		--------
		},
		--------
	}
end

return module

