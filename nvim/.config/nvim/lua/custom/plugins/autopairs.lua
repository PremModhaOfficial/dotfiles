return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	config = function()
		local status, npairs = pcall(require, "nvim-autopairs")
		if not status then
			print("Failed to load nvim-autopairs")
			return
		end
		npairs.setup({
			check_ts = true, -- use treesitter to check for a pair
			ts_config = {
				lua = { "string", "source" }, -- it will not add a pair on that treesitter node
				javascript = { "string", "template_string" },
				java = false, -- don't check treesitter on java
			},
			disable_filetype = { "TelescopePrompt", "spectre_panel" },
			fast_wrap = {
				map = "<M-e>",
				chars = { "{", "[", "(", '"', "'" },
				pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
				offset = 0, -- Offset from pattern match
				end_key = "$",
				keys = "qwertyuiopzxcvbnmasdfghjkl",
				check_comma = true,
				highlight = "PmenuSel",
				highlight_grey = "LineNr",
			},
		})
	end,
}
