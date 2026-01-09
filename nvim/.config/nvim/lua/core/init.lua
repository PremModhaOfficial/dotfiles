require("core.options")
require("core.keymaps")
require("core.autocmds")
require("core.lazy")

local utils = require("lib.utils")
local reset_colors = utils.colorscheme_with_transparency("rose-pine", false)

vim.keymap.set("n", "<leader>cd", function()
	reset_colors()
end)
