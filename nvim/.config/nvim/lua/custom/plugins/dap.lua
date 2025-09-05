-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
	-- NOTE: Yes, you can install new plugins here!
	"mfussenegger/nvim-dap",
	-- NOTE: And you can specify dependencies as well
	dependencies = {
		-- Creates a beautiful debugger UI
		"rcarriga/nvim-dap-ui",

		-- Required dependency for nvim-dap-ui
		"nvim-neotest/nvim-nio",

		-- Installs the debug adapters for you
		"williamboman/mason.nvim",
		"jay-babu/mason-nvim-dap.nvim",

		-- Add your own debuggers here
		"leoluz/nvim-dap-go",
	},
	keys = function(_, keys)
		local dap = require("dap")
		local dapui = require("dapui")
		return {
			-- Basic debugging keymaps with leader prefix (no conflicts!)
			{ "<leader>dc", dap.continue, desc = "Debug: Start/Continue" },
			{ "<leader>di", dap.step_into, desc = "Debug: Step Into" },
			{ "<leader>do", dap.step_over, desc = "Debug: Step Over" },
			{ "<leader>dO", dap.step_out, desc = "Debug: Step Out" },
			{ "<leader>db", dap.toggle_breakpoint, desc = "Debug: Toggle Breakpoint" },
			{
				"<leader>dB",
				function()
					dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
				end,
				desc = "Debug: Set Breakpoint",
			},
			{ "<leader>dr", dap.repl.open, desc = "Debug: Open REPL" },
			{ "<leader>du", dapui.toggle, desc = "Debug: Toggle UI" },
			{ "<leader>dt", dap.terminate, desc = "Debug: Terminate" },
			{
				"<leader>dw",
				function()
					dapui.elements.watches.add(vim.fn.input("Expression: "))
				end,
				desc = "Debug: Add Watch",
			},
			unpack(keys),
		}
	end,
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		require("mason-nvim-dap").setup({
			-- Makes a best effort to setup the various debuggers with
			-- reasonable debug configurations
			automatic_installation = true,

			-- You can provide additional configuration to the handlers,
			-- see mason-nvim-dap README for more information
			handlers = {},

			-- You'll need to check that you have the required things installed
			-- online, please don't ask me how to install them :)
			ensure_installed = {
				-- Update this to ensure that you have the debuggers for the langs you want
				"codelldb",
				"delve",
			},
		})

		-- NerdFont breakpoint icons with fallbacks
		local function define_sign(name, icon, fallback)
			local has_nerd_font = vim.fn.has("gui_running") == 1 or vim.env.TERM_PROGRAM == "iTerm.app"
			local text = has_nerd_font and icon or fallback

			vim.fn.sign_define(name, {
				text = text,
				texthl = name,
				linehl = name == "DapStopped" and "DapStoppedLine" or "",
				numhl = "",
			})
		end

		-- Define signs with NerdFont icons and fallbacks
		define_sign("DapBreakpoint", "", "●")           -- Regular breakpoint
		define_sign("DapBreakpointCondition", "", "◆")   -- Conditional breakpoint
		define_sign("DapLogPoint", "", "▶")              -- Log point
		define_sign("DapStopped", "", "▶")               -- Current execution line
		define_sign("DapBreakpointRejected", "", "✗")    -- Rejected breakpoint

		-- Enhanced Java configuration
		dap.configurations.java = {
			{
				type = "java",
				request = "launch",
				name = "Launch Java Program",
				mainClass = function()
					return vim.fn.input("Main class (or press Enter for auto-detect): ", "", "file")
				end,
				projectName = function()
					return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
				end,
				-- Add VM arguments support
				vmArgs = function()
					local args = vim.fn.input("VM Args (optional): ")
					return args ~= "" and args or nil
				end,
			},
			{
				type = "java",
				request = "attach",
				name = "Attach to Java Process",
				hostName = "localhost",
				port = function()
					return vim.fn.input("Port: ", "5005")
				end,
			},
		}

		-- Dap UI setup
		-- For more information, see |:help nvim-dap-ui|
		dapui.setup({
			-- Set icons to characters that are more likely to work in every terminal.
			--    Feel free to remove or use ones that you like more! :)
			--    Don't feel like these are good choices.
			icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
			controls = {
				icons = {
					pause = "⏸",
					play = "▶",
					step_into = "⏎",
					step_over = "⏭",
					step_out = "⏮",
					step_back = "b",
					run_last = "▶▶",
					terminate = "⏹",
					disconnect = "⏏",
				},
			},
		})

		-- Enhanced event listeners with notifications
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
			vim.notify("🐛 Debug session started", vim.log.levels.INFO)
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			vim.notify("✅ Debug session ended", vim.log.levels.INFO)
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			vim.notify("🔚 Debug session exited", vim.log.levels.INFO)
			dapui.close()
		end

		-- Install golang specific config
		require("dap-go").setup({
			delve = {
				-- On Windows delve must be run attached or it crashes.
				-- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
				detached = vim.fn.has("win32") == 0,
			},
		})
	end,
}
