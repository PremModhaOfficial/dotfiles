require("core.options")
require("core.keymaps")
require("core.autocmds")

-- WORKAROUND: Fix leetcode plugin's broken Snacks picker detection
-- Must be set BEFORE any plugins load
-- See: https://github.com/kawre/leetcode.nvim/issues/199
pcall(function()
	---@diagnostic disable-next-line: inject-field
	require("snacks").config.picker.enabled = true
end)

require("core.lazy")

local utils = require("lib.utils")
local reset_colors = utils.colorscheme_with_transparency("cyberdream", false)

vim.keymap.set("n", "<leader>cd", function()
	reset_colors()
end)
