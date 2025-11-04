return {
	name = "dap",
	displayName = "DAP Debugger",
	capabilities = {
		tools = {
			{
				name = "continue",
				description = "Start or continue the debugging session.",
				handler = function(req, res)
					local dap = require("dap")
					dap.continue()
					return res:text("DAP session started/continued."):send()
				end,
			},
			{
				name = "step_over",
				description = "Step over the current line.",
				handler = function(req, res)
					local dap = require("dap")
					dap.step_over()
					return res:text("Stepped over."):send()
				end,
			},
			{
				name = "step_into",
				description = "Step into the function call on the current line.",
				handler = function(req, res)
					local dap = require("dap")
					dap.step_into()
					return res:text("Stepped into."):send()
				end,
			},
			{
				name = "step_out",
				description = "Step out of the current function.",
				handler = function(req, res)
					local dap = require("dap")
					dap.step_out()
					return res:text("Stepped out."):send()
				end,
			},
			{
				name = "toggle_breakpoint",
				description = "Toggle a breakpoint on the current line.",
				handler = function(req, res)
					local dap = require("dap")
					dap.toggle_breakpoint()
					return res:text("Toggled breakpoint."):send()
				end,
			},
			{
				name = "set_conditional_breakpoint",
				description = "Set a conditional breakpoint on the current line.",
				inputSchema = {
					type = "object",
					properties = {
						condition = {
							type = "string",
							description = "The condition for the breakpoint.",
						},
					},
					required = { "condition" },
				},
				handler = function(req, res)
					local dap = require("dap")
					dap.set_breakpoint(req.params.condition)
					return res:text("Set conditional breakpoint."):send()
				end,
			},
			{
				name = "terminate",
				description = "Terminate the current debugging session.",
				handler = function(req, res)
					local dap = require("dap")
					dap.terminate()
					return res:text("Debugging session terminated."):send()
				end,
			},
			{
				name = "open_repl",
				description = "Open the DAP REPL.",
				handler = function(req, res)
					local dap = require("dap")
					dap.repl.open()
					return res:text("DAP REPL opened."):send()
				end,
			},
			{
				name = "toggle_ui",
				description = "Toggle the DAP UI.",
				handler = function(req, res)
					local dapui = require("dapui")
					dapui.toggle()
					return res:text("Toggled DAP UI."):send()
				end,
			},
			{
				name = "list_breakpoints",
				description = "List all breakpoints.",
				handler = function(req, res)
					local dap = require("dap")
					local breakpoints = dap.get_breakpoints()
					local bp_list = {}
					for path, bps in pairs(breakpoints) do
						for _, bp in ipairs(bps) do
							table.insert(
								bp_list,
								string.format("%s:%d - condition: %s", path, bp.line, bp.condition or "none")
							)
						end
					end
					if #bp_list == 0 then
						return res:text("No breakpoints set."):send()
					end
					return res:text("Breakpoints:\n" .. table.concat(bp_list, "\n")):send()
				end,
			},
		},
		resources = {
			{
				name = "session_info",
				uri = "dap://session",
				description = "Get information about the current DAP session.",
				handler = function(req, res)
					local dap = require("dap")
					local session = dap.session()
					if not session then
						return res:text("No active DAP session."):send()
					end
					local info = {
						id = session.id,
						name = session.name,
						state = session.state,
						adapter = session.adapter.name,
					}
					return res:text(vim.inspect(info), "application/json"):send()
				end,
			},
		},
	},
}
