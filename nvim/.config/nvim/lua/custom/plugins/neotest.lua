-- neotest.lua
-- Testing framework for running and debugging tests
-- Integrates with Go via neotest-go adapter and Delve debugger

return {
	{
		-- Core neotest plugin
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-neotest/neotest-go",
		},
		-- Lazy load on Go files or neotest commands
		event = { "BufEnter *.go" },
		cmd = { "Neotest" },
		opts = {
			-- Test discovery and execution
			discovery = {
				enabled = true,
				concurrent = 2,
			},
			running = {
				concurrent = 2,
			},
			-- Output handling
			output = {
				open_on_run = "short",
			},
			-- Status notifications
			status = {
				virtual_text = true,
				signs = true,
			},
			-- Summary window configuration
			summary = {
				open = "botright vsplit | vertical resize 50",
			},
			-- Adapter configurations
			adapters = {
				["neotest-go"] = {
					args = { "-v", "-race", "-count=1" },
					go_test_args = { "-v", "-race" },
					dap_go_enabled = true,
					utils_search_patterns = { "TestMain" },
				},
			},
		},
		config = function(_, opts)
			local neotest = require("neotest")
			
			-- Verify Go is available
			if vim.fn.executable("go") == 0 then
				vim.notify(
					"Go executable not found in PATH. Testing will not work.",
					vim.log.levels.WARN
				)
			end

			-- Setup neotest with merged options
			neotest.setup(opts)

			-- Create autogroup for Go test-specific autocmds
			local go_augroup = vim.api.nvim_create_augroup("neotest_go", { clear = true })

			-- Auto-detect go.mod for project-level test discovery
			vim.api.nvim_create_autocmd("BufEnter", {
				group = go_augroup,
				pattern = "*.go",
				callback = function(event)
					-- Warn if go.mod doesn't exist in project root
					local root = vim.fs.root(0, { "go.mod", ".git" })
					if root and not vim.loop.fs_stat(vim.fn.fnamemodify(root .. "/go.mod", ":p")) then
						vim.notify(
							"go.mod not found - tests may fail. Ensure you're in a Go project.",
							vim.log.levels.WARN
						)
					end
				end,
			})

			-- Ensure DAP configuration exists for Go debugging
			if pcall(require, "dap") then
				local dap = require("dap")
				if not dap.configurations.go then
					vim.notify(
						"DAP not configured for Go. Debug tests with <leader>td may not work.",
						vim.log.levels.WARN
					)
				end
			end
		end,
		keys = function()
			return {
				-- Run tests
				{
					"<leader>tr",
					"<cmd>Neotest run<cr>",
					desc = "Test: Run Nearest",
				},
				{
					"<leader>tf",
					"<cmd>Neotest run file<cr>",
					desc = "Test: Run File",
				},
				{
					"<leader>tR",
					"<cmd>Neotest run cwd<cr>",
					desc = "Test: Run All",
				},

				-- Test control
				{
					"<leader>ts",
					"<cmd>Neotest stop<cr>",
					desc = "Test: Stop",
				},

				-- Output and debugging
				{
					"<leader>to",
					"<cmd>Neotest output-panel<cr>",
					desc = "Test: Show Output Panel",
				},
				{
					"<leader>tp",
					"<cmd>Neotest output<cr>",
					desc = "Test: Show Output",
				},

				-- Debug integration
				{
					"<leader>td",
					"<cmd>Neotest debug<cr>",
					desc = "Test: Debug (Delve)",
				},

			-- Summary and navigation
			{
				"<leader>tw",
				"<cmd>Neotest summary<cr>",
				desc = "Test: Summary Window",
			},
			}
		end,
	},
}
