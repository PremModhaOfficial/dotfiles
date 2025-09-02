--@diagnostic disable: unused-local
return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	lazy = true,
	ft = "markdown",
	dependencies = {
		"nvim-lua/plenary.nvim",
		-- Optional: for better telescope integration
		"nvim-telescope/telescope.nvim",
		"bullets-vim/bullets.vim",
	},
	opts = {
		workspaces = {
			{
				name = "prem",
				path = "~/Notes/Conceptrone/",
				overrides = {
					notes_subdir = "notes",
				},
			},
		},
		open = {
			func = function(uri)
				vim.ui.open(uri, { cmd = { "open", "-a", "/Applications/Obsidian.app" } })
			end,
		},

		log_level = vim.log.levels.INFO,

		daily_notes = {
			folder = "notes/",
			date_format = "%Y-%m-%d",
			alias_format = "%B %-d, %Y",
			template = "daily-template.md", -- You'll create this template
		},

		completion = {
			nvim_cmp = false,
			blink = true,
			min_chars = 1,
		},

		-- Enhanced mappings for atomic note workflow
		mappings = {
			-- Default mappings
			["gf"] = {
				action = function()
					return require("obsidian").util.gf_passthrough()
				end,
				opts = { noremap = false, expr = true, buffer = true },
			},
			["<leader>ch"] = {
				action = function()
					return require("obsidian").util.toggle_checkbox()
				end,
				opts = { buffer = true },
			},
			["<cr>"] = {
				action = function()
					return require("obsidian").util.smart_action()
					-- header_level
				end,
				opts = { buffer = true, expr = true },
			},

			-- Your existing mappings
			["<leader>b"] = {
				action = function()
					vim.cmd("wall")
				end,
				desc = "Save all buffers",
			},
			["<leader>fo"] = {
				action = function()
					vim.cmd("ObsidianSearch")
				end,
				desc = "Search for notes",
			},
			["<leader>od"] = {
				action = function()
					vim.cmd("ObsidianDailies")
				end,
				desc = "Open dailies",
				opts = { noremap = true },
			},
			["<leader>oo"] = {
				action = function()
					vim.cmd("ObsidianOpen")
				end,
				desc = "Open in Obsidian app",
				opts = { noremap = true },
			},
			["<leader>on"] = {
				action = function()
					vim.cmd("ObsidianNew")
				end,
				desc = "Create new note",
				opts = { noremap = true },
			},

			-- NEW: Enhanced mappings for atomic note workflow
			["<leader>ot"] = {
				action = function()
					vim.cmd("ObsidianTemplate atomic-note-template")
				end,
				desc = "Insert atomic note template",
				opts = { noremap = true },
			},
			["<leader>ol"] = {
				action = function()
					vim.cmd("ObsidianLinks")
				end,
				desc = "Show all links in current note",
				opts = { noremap = true },
			},
			["<leader>ob"] = {
				action = function()
					vim.cmd("ObsidianBacklinks")
				end,
				desc = "Show backlinks to current note",
				opts = { noremap = true },
			},
			["<leader>og"] = {
				action = function()
					vim.cmd("ObsidianTags")
				end,
				desc = "Browse all tags",
				opts = { noremap = true },
			},
			["<leader>or"] = {
				action = function()
					-- Custom function to mark note for review
					local client = require("obsidian").get_client()
					local note = client:current_note()
					if note then
						-- Add review tag and update status
						local content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
						for i, line in ipairs(content) do
							if line:match("^%*%*Status:%*%*") then
								content[i] = "**Status:** #needs-review"
								vim.api.nvim_buf_set_lines(0, i - 1, i, false, { content[i] })
								break
							end
						end
						print("Note marked for review")
					end
				end,
				desc = "Mark note for review",
				opts = { noremap = true },
			},
			["<leader>oc"] = {
				action = function()
					-- Custom function to create concept note
					local title = vim.fn.input("Concept title: ")
					if title ~= "" then
						-- vim.cmd("ObsidianNew " .. title)
						vim.cmd("Obsidian new_from_template " .. title .. " atomic-note-template")
					end
				end,
				desc = "Create new concept note",
				opts = { noremap = true },
			},
		},

		new_notes_location = "notes_subdir",

		-- Enhanced note ID function for atomic notes
		note_id_func = function(title)
			local suffix = ""
			if title ~= nil then
				-- Clean title for atomic notes
				suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
				-- Ensure it starts with a letter (good for linking)
				if suffix:match("^%d") then
					suffix = "note-" .. suffix
				end
			else
				-- Generate meaningful ID for untitled notes
				suffix = "untitled-" .. os.date("%Y%m%d-%H%M%S")
			end
			return suffix
		end,

		note_path_func = function(spec)
			local path = spec.dir / tostring(spec.id)
			return path:with_suffix(".md")
		end,

		wiki_link_func = function(opts)
			return require("obsidian.util").wiki_link_id_prefix(opts)
		end,

		markdown_link_func = function(opts)
			return require("obsidian.util").markdown_link(opts)
		end,

		preferred_link_style = "wiki",

		image_name_func = function()
			return string.format("%s-", os.date("%Y%m%d-%H%M%S"))
		end,

		disable_frontmatter = false,

		-- Enhanced frontmatter for atomic notes
		note_frontmatter_func = function(note)
			if note.title then
				note:add_alias(note.title)
			end

			local out = {
				id = note.id,
				aliases = note.aliases,
				tags = note.tags,
				created = os.date("%Y-%m-%d %H:%M:%S"),
				modified = os.date("%Y-%m-%d %H:%M:%S"),
			}

			-- Preserve existing metadata
			if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
				for k, v in pairs(note.metadata) do
					out[k] = v
				end
			end

			return out
		end,

		-- TEMPLATES CONFIGURATION - This is crucial for atomic notes
		templates = {
			folder = "templates",
			date_format = "%Y-%m-%d",
			time_format = "%H:%M",
			substitutions = {
				-- Custom substitutions for atomic note template
				yesterday = function()
					return os.date("%Y-%m-%d", os.time() - 24 * 60 * 60)
				end,
				tomorrow = function()
					return os.date("%Y-%m-%d", os.time() + 24 * 60 * 60)
				end,
				-- Add current timestamp
				timestamp = function()
					return os.date("%Y-%m-%d %H:%M:%S")
				end,
				-- Add ISO date
				isodate = function()
					return os.date("%Y-%m-%d")
				end,
			},
		},

		follow_url_func = function(url)
			vim.fn.jobstart({ "xdg-open", url }) -- linux
		end,

		use_advanced_uri = false,
		open_app_foreground = false,

		picker = {
			name = "snacks.pick",
			note_mappings = {
				new = "<C-x>",
				insert_link = "<C-l>",
			},
			tag_mappings = {
				tag_note = "<C-x>",
				insert_tag = "<C-l>",
			},
		},

		-- Optimized for atomic note workflow
		sort_by = "modified",
		sort_reversed = true,
		search_max_lines = 1000,
		open_notes_in = "current",

		-- Enhanced callbacks for atomic note workflow
		callbacks = {
			post_setup = function(client)
				-- Auto-create templates directory
				local templates_dir = client.dir / "templates"
				if not templates_dir:exists() then
					templates_dir:mkdir()
				end

				require("../../config/obsidianCustoms").setup()
			end,

			enter_note = function(client, note)
				-- Auto-set conceallevel for better markdown rendering
				vim.opt_local.conceallevel = 2
				vim.opt_local.concealcursor = "nc"
			end,

			leave_note = function(client, note)
				-- Auto-save when leaving note
				if vim.bo.modified then
					vim.cmd("silent! write")
				end
			end,

			pre_write_note = function(client, note)
				-- Update modified timestamp in frontmatter
				local lines = vim.api.nvim_buf_get_lines(0, 0, 20, false)
				for i, line in ipairs(lines) do
					if line:match("^modified:") then
						lines[i] = "modified: " .. os.date("%Y-%m-%d %H:%M:%S")
						vim.api.nvim_buf_set_lines(0, i - 1, i, false, { lines[i] })
						break
					end
				end
			end,

			post_set_workspace = function(client, workspace)
				print("Workspace set to: " .. workspace.name)
			end,
		},

		-- Enhanced UI for better atomic note experience
		ui = {
			enable = false,
			update_debounce = 200,
			max_file_length = 5000,
			checkboxes = {
				[" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
				["x"] = { char = "", hl_group = "ObsidianDone" },
				[">"] = { char = "", hl_group = "ObsidianRightArrow" },
				["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
				["!"] = { char = "", hl_group = "ObsidianImportant" },
				-- Add review-specific checkboxes
				["?"] = { char = "󰘥", hl_group = "ObsidianQuestion" },
				["i"] = { char = "󰋼", hl_group = "ObsidianInfo" },
			},
			bullets = { char = "•", hl_group = "ObsidianBullet" },
			external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
			reference_text = { hl_group = "ObsidianRefText" },
			highlight_text = { hl_group = "ObsidianHighlightText" },
			tags = { hl_group = "ObsidianTag" },
			block_ids = { hl_group = "ObsidianBlockID" },
			hl_groups = {
				ObsidianTodo = { bold = true, fg = "#f78c6c" },
				ObsidianDone = { bold = true, fg = "#89ddff" },
				ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
				ObsidianTilde = { bold = true, fg = "#ff5370" },
				ObsidianImportant = { bold = true, fg = "#d73128" },
				ObsidianBullet = { bold = true, fg = "#89ddff" },
				ObsidianRefText = { underline = true, fg = "#c792ea" },
				ObsidianExtLinkIcon = { fg = "#c792ea" },
				ObsidianTag = { italic = true, fg = "#89ddff" },
				ObsidianBlockID = { italic = true, fg = "#89ddff" },
				ObsidianHighlightText = { bg = "#75662e" },
				-- New highlight groups
				ObsidianQuestion = { bold = true, fg = "#ffcb6b" },
				ObsidianInfo = { bold = true, fg = "#82aaff" },
			},
		},

		attachments = {
			img_folder = "assets/imgs",
			img_text_func = function(client, path)
				path = client:vault_relative_path(path) or path
				return string.format("![%s](%s)", path.name, path)
			end,
		},
	},
}
