return {
	"3rd/image.nvim",
	cond = function()
		return vim.fn.has("gui_running") == 0 and vim.env.TERM ~= nil and vim.api.nvim_list_uis()[1] ~= nil
	end,
	event = "VeryLazy",
	dependencies = {
		{
			"nvim-treesitter/nvim-treesitter",
			build = ":TSUpdate",
		},
	},

	config = function()
		require("image").setup({
			backend = "kitty",
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = true,
					only_render_image_at_cursor = false,
					only_render_image_at_cursor_mode = "popup",
					floating_windows = false,
					filetypes = { "markdown", "vimwiki" },
				},
				neorg = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = true,
					only_render_image_at_cursor = false,
					only_render_image_at_cursor_mode = "popup",
					floating_windows = false,
					filetypes = { "norg" },
				},
			},
			max_width = nil,
			max_height = nil,
			max_width_window_percentage = nil,
			max_height_window_percentage = 50,
			kitty_method = "normal",
			hijack_file_patterns = {},
		})

		local function should_hijack_buffer(bufnr)
			local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
			local bufname = vim.api.nvim_buf_get_name(bufnr)

			if buftype ~= "" then
				return false
			end

			if bufname:match("^[%w-]+://") then
				return false
			end

			if vim.fn.filereadable(bufname) ~= 1 then
				return false
			end

			return true
		end

		vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
			group = vim.api.nvim_create_augroup("ImageNvimHijackValidated", { clear = true }),
			pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
			callback = function(args)
				if should_hijack_buffer(args.buf) then
					local path = vim.api.nvim_buf_get_name(args.buf)
					local win = vim.api.nvim_get_current_win()
					require("image").hijack_buffer(path, win, args.buf)
				end
			end,
		})
	end,
}
