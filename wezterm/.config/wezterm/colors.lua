local module = {}
		--------
function module.apply_colors(config)
		--------
	config.colors = {
		--------
		foreground = "#D6C4B7",
		background = "#000102",
---		cursor_bg = "#5C7015",
---		cursor_fg = "#D6C4B7",
---		cursor_border = "#BCA391",
		--------
		brights = {
		--------
			"#000308",
			"#115A21",
			"#563B10",
			"#6C3C14",
			"#673713",
			"#5C7015",
			"#793F16",
			"#BCA391",
		--------
		},
		--------
		ansi = {
		--------
			"#837265",
			"#167828",
			"#704C15",
			"#93521B",
			"#8A4A19",
			"#80961C",
			"#9F551D",
			"#BCA391",
		--------
		},
		--------
	}
end

return module

