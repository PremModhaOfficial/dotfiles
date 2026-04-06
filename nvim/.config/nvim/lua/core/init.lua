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

require("lib.borderless").setup()
local utils = require("lib.utils")
local disable_transparency = utils.colorscheme_with_transparency("neon-cherrykiss-night", false)

vim.keymap.set("n", "<leader>cd", disable_transparency, { desc = "Disable Transparency" })
