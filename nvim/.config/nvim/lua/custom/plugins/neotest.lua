return {
	"nvim-neotest/neotest",
	dependencies = {

		{
			"rcasia/neotest-java",
			ft = "java",
			dependencies = {
				"mfussenegger/nvim-jdtls",
				"mfussenegger/nvim-dap", -- for the debugger
				"rcarriga/nvim-dap-ui", -- recommended
				"theHamsta/nvim-dap-virtual-text", -- recommended
			},
		},
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		-- Adapters
		"nvim-neotest/neotest-plenary",
		"nvim-neotest/neotest-vim-test",
		-- "nvim-neotest/neotest-jest",
		-- "marilari88/neotest-vitest",
		-- "haydenmeade/neotest-jest",
		-- "nvim-neotest/neotest-python",
		-- "rouge8/neotest-rust",
		-- "lawrence-laz/neotest-zig",
		-- "sidlatau/neotest-dart",
		-- "rcasia/neotest-bash",
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-plenary"),
				require("neotest-vim-test")({
					ignore_file_types = { "python", "javascript", "typescript", "rust", "zig", "dart", "bash" },
				}),
				require("neotest-java")({
					-- config here
				}),
				-- require("neotest-jest"),
				-- require("neotest-vitest"),
				-- require("neotest-python"),
				-- require("neotest-rust"),
				-- require("neotest-zig"),
				-- require("neotest-dart"),
				-- require("neotest-bash"),
			},
			quickfix = {
				enable = true,
				open = false,
			},
			output = {
				open_on_run = false,
			},
			output_panel = {
				enable = true,
				open = "botright split | resize 15",
			},
		})
	end,
	keys = {
		-- {
		-- 	"<leader>tt",
		-- 	function()
		-- 		require("neotest").run.run()
		-- 	end,
		-- 	desc = "Run nearest test",
		-- },
		-- {
		-- 	"<leader>tf",
		-- 	function()
		-- 		require("neotest").run.run(vim.fn.expand("%"))
		-- 	end,
		-- 	desc = "Run file tests",
		-- },
		-- {
		-- 	"<leader>ta",
		-- 	function()
		-- 		require("neotest").run.run({ suite = true })
		-- 	end,
		-- 	desc = "Run all tests",
		-- },
		-- {
		-- 	"<leader>ts",
		-- 	function()
		-- 		require("neotest").summary.toggle()
		-- 	end,
		-- 	desc = "Toggle test summary",
		-- },
		-- {
		-- 	"<leader>to",
		-- 	function()
		-- 		require("neotest").output.open({ enter = true })
		-- 	end,
		-- 	desc = "Open test output",
		-- },
		-- {
		-- 	"<leader>td",
		-- 	function()
		-- 		require("neotest").run.run({ strategy = "dap" })
		-- 	end,
		-- 	desc = "Debug nearest test",
		-- },
	},
}
