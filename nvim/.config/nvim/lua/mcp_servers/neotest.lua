return {
	name = "neotest",
	displayName = "Neotest Test Runner",
	capabilities = {
		tools = {
			{
				name = "run_nearest_test",
				description = "Run the nearest test to the cursor position",
				handler = function(req, res)
					local neotest = require("neotest")
					neotest.run.run()
					-- Wait a bit for results
					vim.defer_fn(function()
						local results = neotest.state.status_counts(vim.fn.getcwd()) or {}
						res:text(
							string.format(
								"Test run completed. Passed: %d, Failed: %d, Skipped: %d",
								results.passed or 0,
								results.failed or 0,
								results.skipped or 0
							)
						):send()
					end, 1000)
				end,
			},
			{
				name = "run_file_tests",
				description = "Run all tests in the current file",
				handler = function(req, res)
					local neotest = require("neotest")
					neotest.run.run(vim.fn.expand("%"))
					vim.defer_fn(function()
						local results = neotest.state.status_counts(vim.fn.getcwd()) or {}
						res:text(
							string.format(
								"File tests completed. Passed: %d, Failed: %d, Skipped: %d",
								results.passed or 0,
								results.failed or 0,
								results.skipped or 0
							)
						):send()
					end, 1000)
				end,
			},
			{
				name = "run_all_tests",
				description = "Run all tests in the project",
				handler = function(req, res)
					local neotest = require("neotest")
					neotest.run.run({ suite = true })
					vim.defer_fn(function()
						local results = neotest.state.status_counts(vim.fn.getcwd()) or {}
						res:text(
							string.format(
								"All tests completed. Passed: %d, Failed: %d, Skipped: %d",
								results.passed or 0,
								results.failed or 0,
								results.skipped or 0
							)
						):send()
					end, 2000)
				end,
			},
			{
				name = "run_tests_in_dir",
				description = "Run tests in a specific directory",
				inputSchema = {
					type = "object",
					properties = {
						dir = {
							type = "string",
							description = "Directory path to run tests in",
						},
					},
					required = { "dir" },
				},
				handler = function(req, res)
					local neotest = require("neotest")
					neotest.run.run(req.params.dir)
					vim.defer_fn(function()
						local results = neotest.state.status_counts(vim.fn.getcwd()) or {}
						res:text(
							string.format(
								"Directory tests completed. Passed: %d, Failed: %d, Skipped: %d",
								results.passed or 0,
								results.failed or 0,
								results.skipped or 0
							)
						):send()
					end, 1000)
				end,
			},
			{
				name = "debug_nearest_test",
				description = "Debug the nearest test using DAP",
				handler = function(req, res)
					local neotest = require("neotest")
					neotest.run.run({ strategy = "dap" })
					res:text("Debugging nearest test... Check your DAP UI for the debugging session."):send()
				end,
			},
			{
				name = "get_test_summary",
				description = "Get a summary of current test status",
				handler = function(req, res)
					local neotest = require("neotest")
					local results = neotest.state.status_counts(vim.fn.getcwd()) or {}
					local summary = string.format(
						"Test Summary:\n- Total: %d\n- Passed: %d\n- Failed: %d\n- Skipped: %d\n- Running: %d",
						(results.passed or 0) + (results.failed or 0) + (results.skipped or 0) + (results.running or 0),
						results.passed or 0,
						results.failed or 0,
						results.skipped or 0,
						results.running or 0
					)
					res:text(summary):send()
				end,
			},
			{
				name = "list_test_positions",
				description = "List test positions in the current file",
				handler = function(req, res)
					local neotest = require("neotest")
					local positions = neotest.state.positions(vim.fn.expand("%"))
					if not positions then
						return res:text("No test positions found in current file."):send()
					end
					local output = "Test positions in " .. vim.fn.expand("%") .. ":\n"
					for _, pos in ipairs(positions) do
						output = output .. string.format("- %s: %s (line %d)\n", pos.type, pos.name, pos.range[1])
					end
					res:text(output):send()
				end,
			},
			{
				name = "stop_running_tests",
				description = "Stop any currently running tests",
				handler = function(req, res)
					local neotest = require("neotest")
					neotest.run.stop()
					res:text("Stopped running tests."):send()
				end,
			},
			{
				name = "open_test_output",
				description = "Open the test output panel",
				handler = function(req, res)
					local neotest = require("neotest")
					neotest.output.open({ enter = true })
					res:text("Opened test output panel."):send()
				end,
			},
		},
		resources = {
			{
				name = "test_results",
				uri = "neotest://results",
				description = "Current test results summary",
				handler = function(req, res)
					local neotest = require("neotest")
					local results = neotest.state.status_counts(vim.fn.getcwd()) or {}
					local content = vim.inspect(results)
					res:text(content):send()
				end,
			},
			{
				name = "test_output",
				uri = "neotest://output",
				description = "Test output for the last run",
				handler = function(req, res)
					local neotest = require("neotest")
					local output = neotest.output()
					if output then
						res:text(output):send()
					else
						res:text("No test output available."):send()
					end
				end,
			},
		},
		prompts = {
			{
				name = "test_help",
				description = "Help with testing and debugging",
				arguments = {
					{
						name = "topic",
						description = "What help do you need? (e.g., 'running tests', 'debugging', 'configuration')",
						required = true,
					},
				},
				handler = function(req, res)
					local topic = req.params.topic
					res:user()
						:text(string.format("I need help with neotest %s. Can you guide me through it?", topic))
						:llm()
						:text("I'll help you with neotest " .. topic .. ". Here are some tips:")
						:text("- Use run_nearest_test to run the test under cursor")
						:text("- Use debug_nearest_test for debugging with DAP")
						:text("- Check test_results resource for current status")
						:send()
				end,
			},
		},
	},
}
