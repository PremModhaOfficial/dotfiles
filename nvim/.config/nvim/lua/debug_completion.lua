-- Debug script to inspect jdtls completion item structure
-- Usage: Source this file in a Java buffer and trigger completion

local M = {}

-- Store original completion handler
local original_handler = vim.lsp.handlers["textDocument/completion"]

-- Override completion handler to log items
vim.lsp.handlers["textDocument/completion"] = function(err, result, ctx, config)
	if result and result.items then
		-- Log first 3 items for inspection
		for i = 1, math.min(3, #result.items) do
			local item = result.items[i]
			print("=== Completion Item " .. i .. " ===")
			print("label: " .. (item.label or "nil"))
			print("detail: " .. (item.detail or "nil"))
			print("kind: " .. (item.kind or "nil"))
			
			if item.labelDetails then
				print("labelDetails.detail: " .. (item.labelDetails.detail or "nil"))
				print("labelDetails.description: " .. (item.labelDetails.description or "nil"))
			else
				print("labelDetails: nil")
			end
			
			if item.documentation then
				local doc_str = type(item.documentation) == "string" 
					and item.documentation 
					or (item.documentation.value or "complex doc")
				print("documentation: " .. doc_str:sub(1, 50))
			else
				print("documentation: nil")
			end
			print("")
		end
	end
	
	-- Call original handler
	return original_handler(err, result, ctx, config)
end

M.restore = function()
	vim.lsp.handlers["textDocument/completion"] = original_handler
end

return M
