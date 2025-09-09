--k-@class LSPServer
local M = {}

-- Helper function to get LSP clients for a buffer
local function get_lsp_clients(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	return vim.lsp.get_clients({ bufnr = bufnr })
end

-- Helper to handle errors
local function safe_lsp_call(fn, ...)
	local success, result = pcall(fn, ...)
	if not success then
		return nil, result -- result is the error message
	end
	return result
end

-- Smart buffer detection for chat windows
local function get_target_buffer()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	-- Skip chat/special buffers
	if buf_name:match("CodeCompanion") or buf_name:match("Avante") or buf_name:match("chat") then
		-- Find most recent code buffer with LSP
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(win)
			local name = vim.api.nvim_buf_get_name(buf)
			if not (name:match("CodeCompanion") or name:match("Avante") or name:match("chat")) and name ~= "" then
				local clients = get_lsp_clients(buf)
				if #clients > 0 then
					return buf
				end
			end
		end
		-- Fallback: find any loaded buffer with LSP
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) then
				local clients = get_lsp_clients(buf)
				if #clients > 0 then
					local name = vim.api.nvim_buf_get_name(buf)
					if not (name:match("CodeCompanion") or name:match("Avante") or name:match("chat")) then
						return buf
					end
				end
			end
		end
	end

	return current_buf
end

-- Validate that buffer has LSP clients
local function validate_lsp_buffer(bufnr)
	local clients = get_lsp_clients(bufnr)
	if #clients == 0 then
		return false, "No LSP clients attached to buffer " .. bufnr
	end
	return true
end

-- Tool: List available LSP clients for current buffer
M.list_clients = {
	name = "list_lsp_clients",
	description = "List all LSP clients attached to the current buffer",
	inputSchema = {
		type = "object",
		properties = {
			bufnr = { type = "number", description = "Buffer number (optional, defaults to current)" },
		},
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local valid, err = validate_lsp_buffer(bufnr)
		if not valid then
			return res:error(err)
		end
		local clients = get_lsp_clients(bufnr)

		local client_info = {}
		for _, client in ipairs(clients) do
			table.insert(client_info, {
				id = client.id,
				name = client.name,
				root_dir = client.config.root_dir,
				capabilities = vim.tbl_keys(client.server_capabilities or {}),
			})
		end

		return res:text(vim.inspect(client_info)):send()
	end,
}

-- Tool: Check LSP capabilities
M.check_capabilities = {
	name = "check_lsp_capabilities",
	description = "Check what LSP capabilities are supported by the current LSP server",
	inputSchema = {
		type = "object",
		properties = {
			bufnr = { type = "number", description = "Buffer number (optional)" },
			client_id = { type = "number", description = "Specific LSP client ID (optional)" },
		},
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local valid, err = validate_lsp_buffer(bufnr)
		if not valid then
			return res:error(err)
		end
		local clients = get_lsp_clients(bufnr)

		local client = req.params.client_id and vim.lsp.get_client_by_id(req.params.client_id) or clients[1]
		if not client then
			return res:error("Invalid client ID")
		end

		local caps = client.server_capabilities or {}
		local capabilities_info = {
			server_name = client.name,
			server_info = (client.server_capabilities and client.server_capabilities.serverInfo) or {},
			supported_features = {
				rename = caps.renameProvider ~= nil,
				code_action = caps.codeActionProvider ~= nil,
				document_symbol = caps.documentSymbolProvider ~= nil,
				workspace_symbol = caps.workspaceSymbolProvider ~= nil,
				definition = caps.definitionProvider ~= nil,
				references = caps.referencesProvider ~= nil,
				hover = caps.hoverProvider ~= nil,
				signature_help = caps.signatureHelpProvider ~= nil,
				formatting = caps.documentFormattingProvider ~= nil,
				range_formatting = caps.documentRangeFormattingProvider ~= nil,
				completion = caps.completionProvider ~= nil,
			},
			raw_capabilities = caps,
		}

		return res:text(vim.inspect(capabilities_info)):send()
	end,
}

-- Tool: Rename symbol
M.rename_symbol = {
	name = "rename_symbol",
	description = "Rename a symbol using LSP",
	inputSchema = {
		type = "object",
		properties = {
			new_name = { type = "string", description = "New name for the symbol" },
			bufnr = { type = "number", description = "Buffer number (optional)" },
			client_id = { type = "number", description = "Specific LSP client ID (optional)" },
		},
		required = { "new_name" },
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local valid, err = validate_lsp_buffer(bufnr)
		if not valid then
			return res:error(err)
		end
		local clients = get_lsp_clients(bufnr)

		local client = req.params.client_id and vim.lsp.get_client_by_id(req.params.client_id) or clients[1]
		if not client then
			return res:error("Invalid client ID")
		end

		-- Find window containing the buffer or use current window
		local win_id = vim.fn.bufwinid(bufnr)
		if win_id == -1 then
			win_id = vim.api.nvim_get_current_win()
		end
		local params = vim.lsp.util.make_position_params(win_id, client.offset_encoding)
		params.newName = req.params.new_name

		local success, err = safe_lsp_call(client.request, "textDocument/rename", params, function(err, result)
			if err then
				if err.code == -32601 then
					res:error("LSP server does not support rename functionality")
				else
					res:error("Rename failed: " .. vim.inspect(err))
				end
			else
				vim.lsp.util.apply_workspace_edit(result, client.offset_encoding)
				res:text("Symbol renamed successfully"):send()
			end
		end)

		if not success then
			return res:error("Failed to send rename request: " .. err)
		end
	end,
}

-- Tool: Get visual selection
M.get_visual_selection = {
	name = "get_visual_selection",
	description = "Get the current visual selection range",
	inputSchema = {
		type = "object",
		properties = {
			bufnr = { type = "number", description = "Buffer number (optional)" },
		},
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()

		-- Check if we're in visual mode or have a visual selection
		local mode = vim.fn.mode()
		if not (mode == "v" or mode == "V" or mode == "\22") then
			-- Try to get the last visual selection
			local start_pos = vim.fn.getpos("'<")
			local end_pos = vim.fn.getpos("'>")

			if start_pos[2] == 0 or end_pos[2] == 0 then
				return res:error("No visual selection found")
			end

			local selection = {
				start_line = start_pos[2],
				start_col = start_pos[3],
				end_line = end_pos[2],
				end_col = end_pos[3],
				mode = "last_visual",
			}
			return res:text(vim.inspect(selection)):send()
		end

		-- Get current visual selection
		local start_pos = vim.fn.getpos("v")
		local end_pos = vim.fn.getpos(".")

		local selection = {
			start_line = start_pos[2],
			start_col = start_pos[3],
			end_line = end_pos[2],
			end_col = end_pos[3],
			mode = mode,
		}

		return res:text(vim.inspect(selection)):send()
	end,
}

-- Tool: List code actions
M.list_code_actions = {
	name = "list_code_actions",
	description = "List available code actions at current position or selection",
	inputSchema = {
		type = "object",
		properties = {
			bufnr = { type = "number", description = "Buffer number (optional)" },
			line = { type = "number", description = "Line number (1-based, optional)" },
			col = { type = "number", description = "Column number (0-based, optional)" },
			use_visual = { type = "boolean", description = "Use current visual selection (optional)", default = false },
			client_id = { type = "number", description = "Specific LSP client ID (optional)" },
		},
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local valid, err = validate_lsp_buffer(bufnr)
		if not valid then
			return res:error(err)
		end
		local clients = get_lsp_clients(bufnr)

		local client = req.params.client_id and vim.lsp.get_client_by_id(req.params.client_id) or clients[1]
		if not client then
			return res:error("Invalid client ID")
		end

		-- Find window containing the buffer or use current window
		local win_id = vim.fn.bufwinid(bufnr)
		if win_id == -1 then
			win_id = vim.api.nvim_get_current_win()
		end
		local params = vim.lsp.util.make_range_params(win_id, client.offset_encoding)

		if req.params.use_visual then
			-- Use visual selection
			local mode = vim.fn.mode()
			if mode == "v" or mode == "V" or mode == "\22" then
				-- Current visual selection
				local start_pos = vim.fn.getpos("v")
				local end_pos = vim.fn.getpos(".")
				params.range = {
					start = { line = start_pos[2] - 1, character = start_pos[3] - 1 },
					["end"] = { line = end_pos[2] - 1, character = end_pos[3] - 1 },
				}
			else
				-- Last visual selection
				local start_pos = vim.fn.getpos("'<")
				local end_pos = vim.fn.getpos("'>")
				if start_pos[2] ~= 0 and end_pos[2] ~= 0 then
					params.range = {
						start = { line = start_pos[2] - 1, character = start_pos[3] - 1 },
						["end"] = { line = end_pos[2] - 1, character = end_pos[3] - 1 },
					}
				end
			end
		elseif req.params.line and req.params.col then
			-- Use specified position
			params.range = {
				start = { line = req.params.line - 1, character = req.params.col },
				["end"] = { line = req.params.line - 1, character = req.params.col },
			}
		end

		local success, err = safe_lsp_call(client.request, "textDocument/codeAction", params, function(err, result)
			if err then
				if err.code == -32601 then
					res:error("LSP server does not support code actions")
				else
					res:error("Failed to get code actions: " .. vim.inspect(err))
				end
			elseif not result or #result == 0 then
				res:text("No code actions available"):send()
			else
				local actions = {}
				for i, action in ipairs(result) do
					table.insert(actions, {
						index = i,
						title = action.title,
						kind = action.kind,
						isPreferred = action.isPreferred,
						diagnostics = action.diagnostics and #action.diagnostics or 0,
					})
				end
				res:text(vim.inspect(actions)):send()
			end
		end)

		if not success then
			return res:error("Failed to send code action request: " .. err)
		end
	end,
}

-- Tool: Apply code action
M.apply_code_action = {
	name = "apply_code_action",
	description = "Apply a specific code action by index",
	inputSchema = {
		type = "object",
		properties = {
			index = { type = "number", description = "Index of the code action to apply" },
			bufnr = { type = "number", description = "Buffer number (optional)" },
			line = { type = "number", description = "Line number (1-based, optional)" },
			col = { type = "number", description = "Column number (0-based, optional)" },
			use_visual = { type = "boolean", description = "Use current visual selection (optional)", default = false },
			client_id = { type = "number", description = "Specific LSP client ID (optional)" },
		},
		required = { "index" },
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local valid, err = validate_lsp_buffer(bufnr)
		if not valid then
			return res:error(err)
		end
		local clients = get_lsp_clients(bufnr)

		local client = req.params.client_id and vim.lsp.get_client_by_id(req.params.client_id) or clients[1]
		if not client then
			return res:error("Invalid client ID")
		end

		-- Find window containing the buffer or use current window
		local win_id = vim.fn.bufwinid(bufnr)
		if win_id == -1 then
			win_id = vim.api.nvim_get_current_win()
		end
		local params = vim.lsp.util.make_range_params(win_id, client.offset_encoding)

		if req.params.use_visual then
			-- Use visual selection
			local mode = vim.fn.mode()
			if mode == "v" or mode == "V" or mode == "\22" then
				-- Current visual selection
				local start_pos = vim.fn.getpos("v")
				local end_pos = vim.fn.getpos(".")
				params.range = {
					start = { line = start_pos[2] - 1, character = start_pos[3] - 1 },
					["end"] = { line = end_pos[2] - 1, character = end_pos[3] - 1 },
				}
			else
				-- Last visual selection
				local start_pos = vim.fn.getpos("'<")
				local end_pos = vim.fn.getpos("'>")
				if start_pos[2] ~= 0 and end_pos[2] ~= 0 then
					params.range = {
						start = { line = start_pos[2] - 1, character = start_pos[3] - 1 },
						["end"] = { line = end_pos[2] - 1, character = end_pos[3] - 1 },
					}
				end
			end
		elseif req.params.line and req.params.col then
			-- Use specified position
			params.range = {
				start = { line = req.params.line - 1, character = req.params.col },
				["end"] = { line = req.params.line - 1, character = req.params.col },
			}
		end

		local success, err = safe_lsp_call(client.request, "textDocument/codeAction", params, function(err, result)
			if err then
				res:error("Failed to get code actions: " .. vim.inspect(err))
			elseif not result or #result == 0 then
				res:error("No code actions available")
			elseif not result[req.params.index] then
				res:error("Invalid code action index")
			else
				local action = result[req.params.index]
				if action.edit then
					vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
				end
				if action.command then
					local cmd_params = {
						command = action.command.command,
						arguments = action.command.arguments,
					}
					local success, err = safe_lsp_call(
						client.request,
						"workspace/executeCommand",
						cmd_params,
						function(err, result)
							if err then
								-- Command execution error, but don't fail the whole operation
								vim.notify("Command execution failed: " .. vim.inspect(err), vim.log.levels.WARN)
							end
						end
					)
				end
				res:text("Code action applied: " .. action.title):send()
			end
		end)

		if not success then
			return res:error("Failed to send code action request: " .. err)
		end
	end,
}

-- Tool: List diagnostics
M.list_diagnostics = {
	name = "list_diagnostics",
	description = "List diagnostics for the current buffer",
	inputSchema = {
		type = "object",
		properties = {
			bufnr = { type = "number", description = "Buffer number (optional)" },
			severity = { type = "number", description = "Filter by severity (1=Error, 2=Warning, 3=Info, 4=Hint)" },
		},
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local diagnostics = vim.diagnostic.get(bufnr)

		if req.params.severity then
			diagnostics = vim.tbl_filter(function(diag)
				return diag.severity == req.params.severity
			end, diagnostics)
		end

		if #diagnostics == 0 then
			return res:text("No diagnostics found"):send()
		end

		local diag_info = {}
		for _, diag in ipairs(diagnostics) do
			table.insert(diag_info, {
				line = diag.lnum + 1,
				col = diag.col + 1,
				severity = diag.severity,
				message = diag.message,
				source = diag.source,
				code = diag.code,
			})
		end

		return res:text(vim.inspect(diag_info)):send()
	end,
}

-- Tool: Go to definition
M.goto_definition = {
	name = "goto_definition",
	description = "Go to definition of symbol at current position",
	inputSchema = {
		type = "object",
		properties = {
			bufnr = { type = "number", description = "Buffer number (optional)" },
			line = { type = "number", description = "Line number (1-based, optional)" },
			col = { type = "number", description = "Column number (0-based, optional)" },
			client_id = { type = "number", description = "Specific LSP client ID (optional)" },
		},
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local valid, err = validate_lsp_buffer(bufnr)
		if not valid then
			return res:error(err)
		end
		local clients = get_lsp_clients(bufnr)

		local client = req.params.client_id and vim.lsp.get_client_by_id(req.params.client_id) or clients[1]
		if not client then
			return res:error("Invalid client ID")
		end

		-- Find window containing the buffer or use current window
		local win_id = vim.fn.bufwinid(bufnr)
		if win_id == -1 then
			win_id = vim.api.nvim_get_current_win()
		end
		local params = vim.lsp.util.make_position_params(win_id, client.offset_encoding)
		if req.params.line and req.params.col then
			params.position = { line = req.params.line - 1, character = req.params.col }
		end

		local success, err = safe_lsp_call(client.request, "textDocument/definition", params, function(err, result)
			if err then
				if err.code == -32601 then
					res:error("LSP server does not support go-to-definition")
				else
					res:error("Failed to get definition: " .. vim.inspect(err))
				end
			elseif not result or #result == 0 then
				res:text("No definition found"):send()
			else
				local location = result[1] -- Take first result
				if location.uri then
					vim.lsp.util.show_document(location, client.offset_encoding, { focus = true })
					res:text("Jumped to definition"):send()
				else
					res:text("Definition found but no URI"):send()
				end
			end
		end)

		if not success then
			return res:error("Failed to send definition request: " .. err)
		end
	end,
}

-- Tool: Find references
M.find_references = {
	name = "find_references",
	description = "Find all references to symbol at current position",
	inputSchema = {
		type = "object",
		properties = {
			bufnr = { type = "number", description = "Buffer number (optional)" },
			line = { type = "number", description = "Line number (1-based, optional)" },
			col = { type = "number", description = "Column number (0-based, optional)" },
			client_id = { type = "number", description = "Specific LSP client ID (optional)" },
		},
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local valid, err = validate_lsp_buffer(bufnr)
		if not valid then
			return res:error(err)
		end
		local clients = get_lsp_clients(bufnr)

		local client = req.params.client_id and vim.lsp.get_client_by_id(req.params.client_id) or clients[1]
		if not client then
			return res:error("Invalid client ID")
		end

		-- Find window containing the buffer or use current window
		local win_id = vim.fn.bufwinid(bufnr)
		if win_id == -1 then
			win_id = vim.api.nvim_get_current_win()
		end
		local params = vim.lsp.util.make_position_params(win_id, client.offset_encoding)
		if req.params.line and req.params.col then
			params.position = { line = req.params.line - 1, character = req.params.col }
		end

		local success, err = safe_lsp_call(client.request, "textDocument/references", params, function(err, result)
			if err then
				if err.code == -32601 then
					res:error("LSP server does not support find references")
				else
					res:error("Failed to find references: " .. vim.inspect(err))
				end
			elseif not result or #result == 0 then
				res:text("No references found"):send()
			else
				local refs = {}
				for _, ref in ipairs(result) do
					table.insert(refs, {
						uri = ref.uri,
						range = ref.range,
					})
				end
				res:text(vim.inspect(refs)):send()
			end
		end)

		if not success then
			return res:error("Failed to send references request: " .. err)
		end
	end,
}

-- Tool: Hover info
M.hover_info = {
	name = "hover_info",
	description = "Get hover information for symbol at current position",
	inputSchema = {
		type = "object",
		properties = {
			bufnr = { type = "number", description = "Buffer number (optional)" },
			line = { type = "number", description = "Line number (1-based, optional)" },
			col = { type = "number", description = "Column number (0-based, optional)" },
			client_id = { type = "number", description = "Specific LSP client ID (optional)" },
		},
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local valid, err = validate_lsp_buffer(bufnr)
		if not valid then
			return res:error(err)
		end
		local clients = get_lsp_clients(bufnr)

		local client = req.params.client_id and vim.lsp.get_client_by_id(req.params.client_id) or clients[1]
		if not client then
			return res:error("Invalid client ID")
		end

		-- Find window containing the buffer or use current window
		local win_id = vim.fn.bufwinid(bufnr)
		if win_id == -1 then
			win_id = vim.api.nvim_get_current_win()
		end
		local params = vim.lsp.util.make_position_params(win_id, client.offset_encoding)
		if req.params.line and req.params.col then
			params.position = { line = req.params.line - 1, character = req.params.col }
		end

		local success, err = safe_lsp_call(client.request, "textDocument/hover", params, function(err, result)
			if err then
				if err.code == -32601 then
					res:error("LSP server does not support hover information")
				else
					res:error("Failed to get hover info: " .. vim.inspect(err))
				end
			elseif not result or not result.contents then
				res:text("No hover information available"):send()
			else
				local contents = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
				res:text(table.concat(contents, "\n")):send()
			end
		end)

		if not success then
			return res:error("Failed to send hover request: " .. err)
		end
	end,
}

-- Tool: Signature help
M.signature_help = {
	name = "signature_help",
	description = "Get signature help at current position",
	inputSchema = {
		type = "object",
		properties = {
			bufnr = { type = "number", description = "Buffer number (optional)" },
			line = { type = "number", description = "Line number (1-based, optional)" },
			col = { type = "number", description = "Column number (0-based, optional)" },
			client_id = { type = "number", description = "Specific LSP client ID (optional)" },
		},
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local valid, err = validate_lsp_buffer(bufnr)
		if not valid then
			return res:error(err)
		end
		local clients = get_lsp_clients(bufnr)

		local client = req.params.client_id and vim.lsp.get_client_by_id(req.params.client_id) or clients[1]
		if not client then
			return res:error("Invalid client ID")
		end

		-- Find window containing the buffer or use current window
		local win_id = vim.fn.bufwinid(bufnr)
		if win_id == -1 then
			win_id = vim.api.nvim_get_current_win()
		end
		local params = vim.lsp.util.make_position_params(win_id, client.offset_encoding)
		if req.params.line and req.params.col then
			params.position = { line = req.params.line - 1, character = req.params.col }
		end

		local success, err = safe_lsp_call(client.request, "textDocument/signatureHelp", params, function(err, result)
			if err then
				res:error("Failed to get signature help: " .. vim.inspect(err))
			elseif not result or not result.signatures or #result.signatures == 0 then
				res:text("No signature help available"):send()
			else
				local sig = result.signatures[result.activeSignature or 1]
				if sig then
					res:text(sig.label):send()
				else
					res:text("No active signature"):send()
				end
			end
		end)

		if not success then
			return res:error("Failed to send signature help request: " .. err)
		end
	end,
}

-- Tool: Format document
M.format_document = {
	name = "format_document",
	description = "Format the current document",
	inputSchema = {
		type = "object",
		properties = {
			bufnr = { type = "number", description = "Buffer number (optional)" },
			client_id = { type = "number", description = "Specific LSP client ID (optional)" },
		},
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local valid, err = validate_lsp_buffer(bufnr)
		if not valid then
			return res:error(err)
		end
		local clients = get_lsp_clients(bufnr)

		local client = req.params.client_id and vim.lsp.get_client_by_id(req.params.client_id) or clients[1]
		if not client then
			return res:error("Invalid client ID")
		end

		local params = {
			textDocument = vim.lsp.util.make_text_document_params(bufnr),
		}

		local success, err = safe_lsp_call(client.request, "textDocument/formatting", params, function(err, result)
			if err then
				res:error("Failed to format document: " .. vim.inspect(err))
			elseif result then
				vim.lsp.util.apply_text_edits(result, bufnr, client.offset_encoding)
				res:text("Document formatted"):send()
			else
				res:text("No formatting changes needed"):send()
			end
		end)

		if not success then
			return res:error("Failed to send format request: " .. err)
		end
	end,
}

-- Tool: Format range
M.format_range = {
	name = "format_range",
	description = "Format a range in the document",
	inputSchema = {
		type = "object",
		properties = {
			start_line = { type = "number", description = "Start line (1-based)" },
			end_line = { type = "number", description = "End line (1-based)" },
			bufnr = { type = "number", description = "Buffer number (optional)" },
			client_id = { type = "number", description = "Specific LSP client ID (optional)" },
		},
		required = { "start_line", "end_line" },
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local valid, err = validate_lsp_buffer(bufnr)
		if not valid then
			return res:error(err)
		end
		local clients = get_lsp_clients(bufnr)

		local client = req.params.client_id and vim.lsp.get_client_by_id(req.params.client_id) or clients[1]
		if not client then
			return res:error("Invalid client ID")
		end

		local params = {
			textDocument = vim.lsp.util.make_text_document_params(bufnr),
			range = {
				start = { line = req.params.start_line - 1, character = 0 },
				["end"] = { line = req.params.end_line - 1, character = 0 },
			},
		}

		local success, err = safe_lsp_call(client.request, "textDocument/rangeFormatting", params, function(err, result)
			if err then
				res:error("Failed to format range: " .. vim.inspect(err))
			elseif result then
				vim.lsp.util.apply_text_edits(result, bufnr, client.offset_encoding)
				res:text("Range formatted"):send()
			else
				res:text("No formatting changes needed"):send()
			end
		end)

		if not success then
			return res:error("Failed to send range format request: " .. err)
		end
	end,
}

-- Tool: Document symbols
M.document_symbols = {
	name = "document_symbols",
	description = "List all symbols in the current document",
	inputSchema = {
		type = "object",
		properties = {
			bufnr = { type = "number", description = "Buffer number (optional)" },
			client_id = { type = "number", description = "Specific LSP client ID (optional)" },
		},
	},
	handler = function(req, res)
		local bufnr = req.params.bufnr or get_target_buffer()
		local valid, err = validate_lsp_buffer(bufnr)
		if not valid then
			return res:error(err)
		end
		local clients = get_lsp_clients(bufnr)

		local client = req.params.client_id and vim.lsp.get_client_by_id(req.params.client_id) or clients[1]
		if not client then
			return res:error("Invalid client ID")
		end

		local params = {
			textDocument = vim.lsp.util.make_text_document_params(bufnr),
		}

		local success, err = safe_lsp_call(client.request, "textDocument/documentSymbol", params, function(err, result)
			if err then
				res:error("Failed to get document symbols: " .. vim.inspect(err))
			elseif not result or #result == 0 then
				res:text("No symbols found"):send()
			else
				local symbols = {}
				local function process_symbols(sym_list)
					for _, sym in ipairs(sym_list) do
						table.insert(symbols, {
							name = sym.name,
							kind = sym.kind,
							range = sym.range,
							selectionRange = sym.selectionRange,
							children = sym.children and #sym.children or 0,
						})
						if sym.children then
							process_symbols(sym.children)
						end
					end
				end
				process_symbols(result)
				res:text(vim.inspect(symbols)):send()
			end
		end)

		if not success then
			return res:error("Failed to send document symbols request: " .. err)
		end
	end,
}

-- Tool: Workspace symbols
M.workspace_symbols = {
	name = "workspace_symbols",
	description = "Search for symbols in the workspace",
	inputSchema = {
		type = "object",
		properties = {
			query = { type = "string", description = "Symbol query" },
			client_id = { type = "number", description = "Specific LSP client ID (optional)" },
		},
		required = { "query" },
	},
	handler = function(req, res)
		local clients = vim.lsp.get_clients()

		if #clients == 0 then
			return res:error("No LSP clients available")
		end

		local client = req.params.client_id and vim.lsp.get_client_by_id(req.params.client_id) or clients[1]
		if not client then
			return res:error("Invalid client ID")
		end

		local params = {
			query = req.params.query,
		}

		local success, err = safe_lsp_call(client.request, "workspace/symbol", params, function(err, result)
			if err then
				res:error("Failed to search workspace symbols: " .. vim.inspect(err))
			elseif not result or #result == 0 then
				res:text("No symbols found"):send()
			else
				local symbols = {}
				for _, sym in ipairs(result) do
					table.insert(symbols, {
						name = sym.name,
						kind = sym.kind,
						location = sym.location,
					})
				end
				res:text(vim.inspect(symbols)):send()
			end
		end)

		if not success then
			return res:error("Failed to send workspace symbols request: " .. err)
		end
	end,
}

-- Tool: List code buffers with LSP
M.list_code_buffers = {
	name = "list_code_buffers",
	description = "List all buffers with active LSP clients",
	inputSchema = {
		type = "object",
		properties = {},
	},
	handler = function(req, res)
		local code_buffers = {}
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) then
				local clients = get_lsp_clients(buf)
				if #clients > 0 then
					local name = vim.api.nvim_buf_get_name(buf)
					-- Skip chat/special buffers
					if not (name:match("CodeCompanion") or name:match("Avante") or name:match("chat")) then
						table.insert(code_buffers, {
							bufnr = buf,
							name = name ~= "" and name or "[No Name]",
							client_count = #clients,
							clients = vim.tbl_map(function(c) return c.name end, clients),
						})
					end
				end
			end
		end

		if #code_buffers == 0 then
			return res:text("No code buffers with LSP clients found"):send()
		end

		res:text(vim.inspect(code_buffers)):send()
	end,
}

return {
	name = "lsp",
	displayName = "LSP Server",
	capabilities = {
		tools = {
			M.list_clients,
			M.check_capabilities,
			M.get_visual_selection,
			M.rename_symbol,
			M.list_code_actions,
			M.apply_code_action,
			M.list_diagnostics,
			M.goto_definition,
			M.find_references,
			M.hover_info,
			M.signature_help,
			M.format_document,
			M.format_range,
			M.document_symbols,
			M.workspace_symbols,
			M.list_code_buffers,
		},
	},
}
