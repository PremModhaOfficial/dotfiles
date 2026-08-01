local M = {}

function M.setup()
	local group = vim.api.nvim_create_augroup("ObsidianEnhancements", { clear = true })
	local is_vault = function()
		return string.find(vim.fn.expand("%:p"), "Conceptrone")
	end

	-- Auto-wrap vault markdown
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		group = group, pattern = { "*.md" },
		callback = function()
			if is_vault() then
				vim.opt_local.wrap = true
				vim.opt_local.linebreak = true
			end
		end,
	})

	-- Auto-save on leave
	vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
		group = group, pattern = { "*.md" },
		callback = function()
			if is_vault() and vim.bo.modified then vim.cmd("silent! write") end
		end,
	})

	-- Update modified timestamp + auto-promote draft→reviewed on save
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = group, pattern = { "*.md" },
		callback = function()
			if not is_vault() then return end
			local lines = vim.api.nvim_buf_get_lines(0, 0, 20, false)
			for i, line in ipairs(lines) do
				if line:match("^modified:") then
					lines[i] = "modified: " .. os.date("%Y-%m-%d %H:%M:%S")
					vim.api.nvim_buf_set_lines(0, i - 1, i, false, { lines[i] })
					break
				end
			end
			for i, line in ipairs(lines) do
				if line:match("status: draft") then
					vim.api.nvim_buf_set_lines(0, i - 1, i, false, { "status: reviewed" })
					break
				end
			end
		end,
	})

	-- User commands
	vim.api.nvim_create_user_command("ObsidianTimestamp", function()
		vim.api.nvim_put({ os.date("%Y-%m-%d %H:%M:%S") }, "c", true, true)
	end, {})

	vim.api.nvim_create_user_command("ObsidianScheduleReview", function()
		local days = tonumber(vim.fn.input("Review in how many days? (default 7): ")) or 7
		local date = os.date("%Y-%m-%d", os.time() + (days * 86400))
		vim.api.nvim_put({ string.format("- [ ] Review on %s #review", date) }, "l", true, true)
	end, {})

	vim.api.nvim_create_user_command("ObsidianAtomic", function(opts)
		local title = opts.args or vim.fn.input("Atomic note title: ")
		if title ~= "" then
			vim.cmd("ObsidianNew from template " .. title .. " atomic-note-template")
		end
	end, { nargs = "?" })
end

return M
