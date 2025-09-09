-- CodeCompanion Buffer Protection
local M = {}

-- Function to return focus to CodeCompanion buffer after MCP tools
function M.return_to_codecompanion()
	local bufs = vim.api.nvim_list_bufs()
	for _, buf in ipairs(bufs) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "codecompanion" then
			-- Find window with codecompanion buffer
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_get_buf(win) == buf then
					vim.api.nvim_set_current_win(win)
					return true
				end
			end
		end
	end
	return false
end

-- Auto-return to CodeCompanion after MCP tool completion
local function setup_auto_return()
	-- Listen for MCPHub tool completion events
	vim.api.nvim_create_autocmd("User", {
		pattern = "MCPHubToolEnd",
		callback = function()
			vim.defer_fn(function()
				M.return_to_codecompanion()
			end, 100) -- Small delay to ensure tool operations complete
		end,
		desc = "Return to CodeCompanion after MCP tool completion",
	})
end

-- Setup the auto-return functionality
setup_auto_return()

-- Create user command for manual return
vim.api.nvim_create_user_command("ReturnToCodeCompanion", function()
	if M.return_to_codecompanion() then
		print("Returned to CodeCompanion")
	else
		print("No CodeCompanion buffer found")
	end
end, { desc = "Return focus to CodeCompanion buffer" })

return M
