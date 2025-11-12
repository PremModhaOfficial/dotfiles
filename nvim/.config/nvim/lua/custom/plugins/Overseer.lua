return {
	"stevearc/overseer.nvim",
	enabled = true,
	cmd = {
		"OverseerOpen",
		"OverseerClose",
		"OverseerToggle",
		"OverseerSaveBundle",
		"OverseerLoadBundle",
		"OverseerDeleteBundle",
		"OverseerRunCmd",
		"OverseerRun",
		"OverseerInfo",
		"OverseerBuild",
		"OverseerQuickAction",
		"OverseerTaskAction",
		"OverseerClearCache",
	},
	opts = {
		dap = false,
		task_list = {
			bindings = {
				["<C-h>"] = false,
				["<C-j>"] = false,
				["<C-k>"] = false,
				["<C-l>"] = false,
			},
		},
		form = {
			win_opts = {
				winblend = 0,
			},
		},
		confirm = {
			win_opts = {
				winblend = 0,
			},
		},
		task_win = {
			win_opts = {
				winblend = 0,
			},
		},
	},
  -- stylua: ignore
  keys = {
    { "<leader>osw", "<cmd>OverseerToggle<cr>",      desc = "Overseer Task list" },
    { "<leader>osr", "<cmd>OverseerRun<cr>",         desc = "Overseer Run task" },
    { "<leader>osq", "<cmd>OverseerQuickAction<cr>", desc = "Overseer Quick action" },
    { "<leader>osi", "<cmd>OverseerInfo<cr>",        desc = "Overseer Info" },
    { "<leader>osb", "<cmd>OverseerBuild<cr>",       desc = "Overseer Task builder" },
    { "<leader>ost", "<cmd>OverseerTaskAction<cr>",  desc = "Overseer Task action" },
    { "<leader>osc", "<cmd>OverseerClearCache<cr>",  desc = "Overseer Clear cache" },
  },
}
