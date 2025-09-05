-- Add this to your init.lua or in a separate file in your lua/config/ directory
local M = {}

function M.setup()
	-- Obsidian-specific autocommands and enhancements
	local obsidian_group = vim.api.nvim_create_augroup("ObsidianEnhancements", { clear = true })

	-- Auto-wrap for better markdown editing in obsidian notes
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		group = obsidian_group,
		pattern = { "*.md" },
		callback = function()
			local file_path = vim.fn.expand("%:p")
			-- Only apply to files in your obsidian vault
			if string.find(file_path, "Conceptrone") then
				vim.opt_local.wrap = true
				vim.opt_local.linebreak = true
			end
		end,
	})

	-- Auto-save obsidian notes when leaving buffer
	vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
		group = obsidian_group,
		pattern = { "*.md" },
		callback = function()
			local file_path = vim.fn.expand("%:p")
			if string.find(file_path, "Conceptrone") and vim.bo.modified then
				vim.cmd("silent! write")
			end
		end,
	})

	-- Automatically update modified timestamp when saving
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = obsidian_group,
		pattern = { "*.md" },
		callback = function()
			local file_path = vim.fn.expand("%:p")
			if string.find(file_path, "Conceptrone") then
				local lines = vim.api.nvim_buf_get_lines(0, 0, 20, false)
				for i, line in ipairs(lines) do
					if line:match("^modified:") then
						local new_line = "modified: " .. os.date("%Y-%m-%d %H:%M:%S")
						vim.api.nvim_buf_set_lines(0, i - 1, i, false, { new_line })
						break
					end
				end
			end
		end,
	})

	-- Quick function to insert current timestamp
	vim.api.nvim_create_user_command("ObsidianTimestamp", function()
		local timestamp = os.date("%Y-%m-%d %H:%M:%S")
		vim.api.nvim_put({ timestamp }, "c", true, true)
	end, {})

	-- Function to quickly add review reminder
	vim.api.nvim_create_user_command("ObsidianScheduleReview", function()
		local days = vim.fn.input("Review in how many days? (default 7): ")
		days = tonumber(days) or 7
		local review_date = os.date("%Y-%m-%d", os.time() + (days * 24 * 60 * 60))
		local reminder = string.format("- [ ] Review on %s #review", review_date)
		vim.api.nvim_put({ reminder }, "l", true, true)
	end, {})

	-- Function to promote note status
	vim.api.nvim_create_user_command("ObsidianPromoteStatus", function()
		local status_map = {
			["#draft"] = "#reviewed",
			["#reviewed"] = "#refined",
			["#refined"] = "#mastered",
		}

		local lines = vim.api.nvim_buf_get_lines(0, 0, 10, false)
		for i, line in ipairs(lines) do
			for old_status, new_status in pairs(status_map) do
				if line:find(old_status) then
					local new_line = line:gsub(old_status, new_status)
					vim.api.nvim_buf_set_lines(0, i - 1, i, false, { new_line })
					print(string.format("Status promoted from %s to %s", old_status, new_status))
					return
				end
			end
		end
		print("No promotable status found")
	end, {})

	-- Enhanced search for atomic notes by status
	vim.api.nvim_create_user_command("ObsidianSearchByStatus", function()
		local status = vim.fn.input("Search status (draft/reviewed/refined/mastered): ")
		if status ~= "" then
			vim.cmd("Obsidian search #" .. status)
		end
	end, {})

	-- Quick link insertion with search
	vim.keymap.set("n", "<leader>oL", function()
		-- This will open search and allow you to insert a link to selected note
		vim.cmd("Obsidian quick switch")
	end, { desc = "Quick link to note" })

	-- Navigate to related notes
	vim.keymap.set("n", "<leader>oR", function()
		-- Search for notes with similar tags
		local current_line = vim.api.nvim_get_current_line()
		local tag_match = current_line:match("#[%w/%-]+")
		if tag_match then
			vim.cmd("Obsidian search " .. tag_match)
		else
			print("No tag found on current line")
		end
	end, { desc = "Find related notes by tag" })

	-- Toggle between edit and preview mode (if you have a markdown preview plugin)
	vim.keymap.set("n", "<leader>op", function()
		if vim.g.obsidian_preview_mode then
			vim.opt_local.conceallevel = 0
			vim.g.obsidian_preview_mode = false
			print("Edit mode")
		else
			vim.opt_local.conceallevel = 2
			vim.g.obsidian_preview_mode = true
			print("Preview mode")
		end
	end, { desc = "Toggle preview mode" })

	vim.keymap.set("i", "<C-t>", function()
		local tag = vim.fn.input("Tag: ")
		if tag ~= "" then
			if not tag:match("^#") then
				tag = "#" .. tag
			end
			vim.api.nvim_put({ tag }, "c", true, true)
		end
	end, { desc = "Insert tag" })

	-- Create note from visual selection
	vim.keymap.set("v", "<leader>on", function()
		local start_pos = vim.fn.getpos("'<")
		local end_pos = vim.fn.getpos("'>")
		local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

		-- Get selected text
		if #lines == 1 then
			lines[1] = lines[1]:sub(start_pos[3], end_pos[3])
		else
			lines[1] = lines[1]:sub(start_pos[3])
			lines[#lines] = lines[#lines]:sub(1, end_pos[3])
		end

		local selected_text = table.concat(lines, "\n")
		local title = vim.fn.input("Note title: ", selected_text:match("[^\n]*"))

		if title ~= "" then
			vim.cmd("Obsidian new " .. title)
			-- Insert selected text as content
		end
	end, { desc = "Create note from selection" })

	-- Link Template Note
	vim.keymap.set("v", "<leader>oc", function()
		local start_pos = vim.fn.getpos("'<")
		local end_pos = vim.fn.getpos("'>")
		local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

		-- Get selected text
		if #lines == 1 then
			lines[1] = lines[1]:sub(start_pos[3], end_pos[3])
		else
			lines[1] = lines[1]:sub(start_pos[3])
			lines[#lines] = lines[#lines]:sub(1, end_pos[3])
		end

		local selected_text = table.concat(lines, "\n")
		local title = vim.fn.input("Note title: ", selected_text:match("[^\n]*"))

		if title ~= "" then
			-- Insert selected text as content
			vim.cmd("Obsidian new from template " .. title .. " atomic-note-template")
			local wrapped_text = "[[" .. selected_text .. "]]"
			vim.api.nvim_buf_set_text(
				0,
				start_pos[2] - 1,
				start_pos[3] - 1,
				end_pos[2] - 1,
				end_pos[3],
				{ wrapped_text }
			)
			-- Insert selected text as content
		end
	end, { desc = "Create Template-note from selection" })
end

return M
