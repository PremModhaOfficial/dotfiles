return {
	{
		"supermaven-inc/supermaven-nvim",
		config = function()
			-- Function to get the hex color of a highlight group
			---@param name string
			---@param attr string
			---@return string|nil
			local function get_hl_color(name, attr)
				local hl = vim.api.nvim_get_hl(0, { name = name })
				if hl[attr] then
					return string.format("#%06x", hl[attr])
				end
				return nil
			end

			-- Get the suggestion color from the Pmenu highlight group
			local suggestion_color = get_hl_color("Pmenu", "fg") or "#B00B69"

			-- Debugging: Print the fetched color
			print("Fetched supermaven suggestion color: " .. suggestion_color)

			require("supermaven-nvim").setup({
				keymaps = {
					-- accept_suggestion with shift+tab
					accept_suggestion = "<S-Tab>",
					clear_suggestion = "<C-]>",
					accept_word = "<C-j>",
				},
				ignore_filetypes = { cpp = true }, -- or { "cpp", }
				color = {
					suggestion_color = suggestion_color,
					-- red cterm=167 gui=red
					cterm = 167,
				},
				log_level = "off", -- set to "off" to disable logging completely
				disable_inline_completion = false, -- disables inline completion for use with cmp
				disable_keymaps = false, -- disables built in keymaps for more manual control
				condition = function()
					return false
				end, -- condition to check for stopping supermaven, `true` means to stop supermaven when the condition is true.
			})
		end,
	},
}
