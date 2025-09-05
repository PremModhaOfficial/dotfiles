return {
	"ravitemer/mcphub.nvim",
	event = "VimEnter", -- Load earlier than VeryLazy
	priority = 1000, -- High priority to load first
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	build = "npm install -g mcp-hub@latest",
	config = function()
		require("mcphub").setup({
			-- Auto-approval configuration
			auto_approve = function(params)
				-- Respect CodeCompanion's auto tool mode when enabled
				if vim.g.codecompanion_auto_tool_mode == true then
					return true
				end
				
				-- Auto-approve safe file operations in current project
				if params.tool_name == "read_file" then
					local path = params.arguments.path or ""
					if path:match("^" .. vim.fn.getcwd()) then
						return true
					end
				end
				
				-- Auto-approve GitHub read operations
				if params.server_name == "github" and params.tool_name and 
				   (params.tool_name:match("^get_") or params.tool_name:match("^list_")) then
					return true
				end
				
				-- Check if tool is configured for auto-approval in servers.json
				if params.is_auto_approved_in_server then
					return true
				end
				
				return false -- Show confirmation prompt for everything else
			end,
			
			-- Extension configurations
			extensions = {
				avante = {
					make_slash_commands = true, -- Enable /mcp:server:prompt slash commands
				}
			}
		})
	end,
}
