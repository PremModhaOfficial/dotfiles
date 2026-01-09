--@diagnostic disable: unused-local
return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	lazy = true,
	event = { "BufReadPre *.md", "BufNewFile *.md" },
	cmd = { "ObsidianSearch", "ObsidianOpen", "ObsidianNew", "ObsidianQuickSwitch", "ObsidianFollowLink" },
	dependencies = {
		{ "nvim-lua/plenary.nvim", lazy = true },
		-- Optional: for better telescope integration
		{ "nvim-telescope/telescope.nvim", lazy = true },
		"bullets-vim/bullets.vim",
		{
			"HakonHarnes/img-clip.nvim",
			event = "BufReadPre *.md",
			opts = {
				default = {
					dir_path = "assets/imgs",
					extension = "png",
					file_name = "%Y-%m-%d-%H-%M-%S",
					template = "![$CURSOR]($FILE_PATH)",
					prompt_for_file_name = true,
					drag_and_drop = { enabled = true },
				},
				filetypes = {
					markdown = {
						url_encode_path = true,
						template = "![$CURSOR]($FILE_PATH)",
						download_images = false,
					},
				},
			},
		},
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

		log_level = vim.log.levels.INFO,

		-- Disable legacy commands to avoid deprecation warnings
		legacy_commands = false,

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

	frontmatter = {
		enabled = true,
		func = function(note)
			if note.title then
				note:add_alias(note.title)
			end

			local out = {
				id = note.id or "",
				aliases = note.aliases or {},
				tags = note.tags or {},
				created = os.date("%Y-%m-%d %H:%M:%S"),
				modified = os.date("%Y-%m-%d %H:%M:%S"),
				status = "draft",  -- Default for atomic notes
				links = {},  -- For tracking outgoing links
				backlinks = {},  -- Placeholder for future backlink integration
			}

			-- Preserve existing metadata
			if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
				for k, v in pairs(note.metadata) do
					out[k] = v
				end
			end

			return out
		end,
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
				-- Atomic note specific
				status_options = "draft|reviewed|refined|mastered",
				link_to_parent = function()
					return "[[Parent Note]]"  -- Placeholder; customize per note
				end,
				atomic_id = function()
					return string.format("atomic-%s", os.date("%Y%m%d%H%M%S"))
				end,
			},
		},

		follow_url_func = function(url)
			vim.fn.jobstart({ "xdg-open", url }) -- linux
		end,


		open = {
			func = function(uri)
				vim.ui.open(uri, { cmd = { "open", "-a", "/Applications/Obsidian.app" } })
			end,
		},

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
	search = {
		sort_by = "modified",
		sort_reversed = true,
		max_lines = 1000,
		cache = true,  -- Enable caching for faster searches
	},

	open_notes_in = "current",

		-- Enhanced callbacks for atomic note workflow
		callbacks = {
			post_setup = function(client)
				-- Auto-create templates directory
				local workspace_path = vim.fn.expand("~/Notes/Conceptrone/")
				local templates_dir = workspace_path .. "/templates"
				if vim.fn.isdirectory(templates_dir) == 0 then
					vim.fn.mkdir(templates_dir, "p")
				end

				require("lib.obsidian_extras").setup()
			end,

			enter_note = function(client, note)
				-- Note entered - additional setup can be added here if needed
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
				if workspace then
					print("Workspace set to: " .. workspace.name)
				else
					print("Workspace set (no workspace info available)")
				end
			end,
		},

		-- Enhanced UI for better atomic note experience
		ui = {
			enable = false,
			update_debounce = 300,  -- Increase for less frequent updates
			max_file_length = 5000,
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
