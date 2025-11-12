-- Filename: ~/github/dotfiles-latest/neovim/neobean/lua/plugins/mini-files.lua
-- https://github.com/echasnovski/mini.files
-- Based on LazyVim.org configuration

return {
	"nvim-mini/mini.files",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = function(_, opts)
		-- I didn't like the default mappings, so I modified them
		-- Module mappings created only inside explorer.
		-- Use `''` (empty string) to not create one.
		opts.mappings = vim.tbl_deep_extend("force", opts.mappings or {}, {
			close = "<esc>",
			-- Use this if you want to open several files
			go_in = "l",
			-- This opens the file, but quits out of mini.files (default L)
			go_in_plus = "<CR>",
			-- I swapped the following 2 (default go_out: h)
			-- go_out_plus: when you go out, it shows you only 1 item to the right
			-- go_out: shows you all the items to the right
			go_out = "H",
			go_out_plus = "h",
			-- Default <BS>
			reset = ",",
			-- Default @
			reveal_cwd = ".",
			show_help = "g?",
			-- Default =
			synchronize = "s",
			trim_left = "<",
			trim_right = ">",
		})

		opts.windows = vim.tbl_deep_extend("force", opts.windows or {}, {
			preview = true,
			width_focus = 20,
			width_preview = 60,
		})

		opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
			-- Whether to use for editing directories
			-- Disabled by default in LazyVim because neo-tree is used for that
			use_as_default_explorer = true,
			-- If set to false, files are moved to the trash directory
			-- To get this dir run :echo stdpath('data')
			-- ~/.local/share/neobean/mini.files/trash
			permanent_delete = false,
		})

		return opts
	end,

	-- CUSTOM KEYBINDS (PRESERVED FROM ORIGINAL)
	keys = {
		{
			-- Open the directory of the file currently being edited
			-- If the file doesn't exist because you maybe switched to a new git branch
			-- open the current working directory
			"<M-0>",
			function()
				local buf_name = vim.api.nvim_buf_get_name(0)
				local dir_name = vim.fn.fnamemodify(buf_name, ":p:h")
				if vim.fn.filereadable(buf_name) == 1 then
					-- Pass the full file path to highlight the file
					require("mini.files").open(buf_name, true)
				elseif vim.fn.isdirectory(dir_name) == 1 then
					-- If the directory exists but the file doesn't, open the directory
					require("mini.files").open(dir_name, true)
				else
					-- If neither exists, fallback to the current working directory
					require("mini.files").open(vim.uv.cwd(), true)
				end
			end,
			desc = "Open mini.files (Directory of Current File or CWD if not exists)",
		},
		-- Open the current working directory
		{
			"<M-9>",
			function()
				require("mini.files").open(vim.uv.cwd(), true)
			end,
			desc = "Open mini.files (cwd)",
		},
	},

	config = function(_, opts)
		-- Set up mini.files
		require("mini.files").setup(opts)

		-- Set up icons with nvim-web-devicons
		local MiniFiles = require("mini.files")
		local devicons = require("nvim-web-devicons")

		-- Hook into file explorer updates to add icons
		local function add_icons_to_explorer()
			local explorer_state = MiniFiles.get_explorer_state()
			if not explorer_state or not explorer_state.cwd then
				return
			end

			local cwd = explorer_state.cwd
			local buf = vim.api.nvim_get_current_buf()

			-- Clear previous extmarks
			local ns_id = vim.api.nvim_create_namespace("MiniFilesIcons")
			vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

			for i, line in ipairs(lines) do
				-- Skip empty lines
				if line:gsub("%s+", "") == "" then
					goto continue
				end

				-- Extract filename - mini.files displays just the name
				-- Remove any leading/trailing whitespace and directory markers
				local entry_name = line:match("^%s*(.-)%s*$")
				if not entry_name or entry_name == "" then
					goto continue
				end

				-- Build full path to check if it's a directory
				local entry_path = cwd .. "/" .. entry_name
				local is_dir = vim.fn.isdirectory(entry_path) == 1

				-- Get the icon
				local icon, hl = devicons.get_icon(entry_name)

				-- Use folder icon for directories
				if is_dir then
					icon = " "
					hl = "MiniFilesDirectory"
				end

				-- Set the virtual text extmark
				if icon then
					vim.api.nvim_buf_set_extmark(buf, ns_id, i - 1, 0, {
						virt_text = { { icon .. " ", hl or "Normal" } },
						virt_text_pos = "inline",
					})
				end

				::continue::
			end
		end

		-- Set up autocmds for icon updates
		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniFilesExplorerOpen",
			callback = add_icons_to_explorer,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniFilesExplorerUpdated",
			callback = add_icons_to_explorer,
		})

		-- Integrate with Snacks rename
		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniFilesActionRename",
			callback = function(event)
				if Snacks and Snacks.rename and Snacks.rename.on_rename_file then
					Snacks.rename.on_rename_file(event.data.from, event.data.to)
				end
			end,
		})
	end,
}
