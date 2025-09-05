-- ~/.config/nvim/lua/config/custom-java.lua
local M = {}

-- Store runtime flags per project (in memory for session)
M.project_runtime_flags = {}

-- Cache for main classes to improve performance
M.main_classes_cache = {}
M.cache_timeout = 30000 -- 30 seconds cache timeout

-- Finds the project root using git. Falls back to the current directory.
local function find_project_root()
	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if git_root and git_root ~= "" then
		return git_root
	end
	return vim.fn.getcwd()
end

-- Enhanced function to get main class from current file context
local function get_current_file_main_class()
	local success, buf_lines = pcall(vim.api.nvim_buf_get_lines, 0, 0, -1, false)
	if not success then
		vim.notify("Error reading current buffer", vim.log.levels.ERROR)
		return nil
	end
	local package_name = ""
	local class_name = ""

	-- Extract package and class name from current buffer
	for _, line in ipairs(buf_lines) do
		local pkg_match = line:match("^package%s+([%w%.]+)")
		if pkg_match then
			package_name = pkg_match
		end

		local class_match = line:match("public%s+class%s+(%w+)") or line:match("class%s+(%w+)")
		if class_match then
			class_name = class_match
		end

		-- Stop if we found both
		if package_name ~= "" and class_name ~= "" then
			break
		end
	end

	if class_name ~= "" then
		if package_name ~= "" then
			return package_name .. "." .. class_name
		else
			return class_name
		end
	end

	return nil
end

-- Check if current file has a main method
local function current_file_has_main()
	local success, buf_lines = pcall(vim.api.nvim_buf_get_lines, 0, 0, -1, false)
	if not success then
		return false
	end
	for _, line in ipairs(buf_lines) do
		if line:match("public%s+static%s+void%s+main") or line:match("static%s+public%s+void%s+main") then
			return true
		end
	end
	return false
end

-- Find main classes by scanning Java files in the project
local function find_main_classes_in_project(project_root)
	-- Check cache first
	local cache_key = project_root
	local cached = M.main_classes_cache[cache_key]
	local current_time = vim.loop.now()

	if cached and (current_time - cached.timestamp) < M.cache_timeout then
		return cached.classes
	end

	local main_classes = {}

	-- Use find command to locate all .java files
	local find_cmd = string.format("find '%s' -name '*.java' -type f 2>/dev/null", project_root)
	local java_files = vim.fn.systemlist(find_cmd)

	if vim.v.shell_error ~= 0 then
		vim.notify("Error scanning for Java files: " .. table.concat(java_files, " "), vim.log.levels.ERROR)
		return {}
	end

	for _, file_path in ipairs(java_files) do
		if vim.fn.filereadable(file_path) == 1 then
			local success, file_lines = pcall(vim.fn.readfile, file_path)
			if not success then
				vim.notify("Error reading file: " .. file_path, vim.log.levels.WARN)
				goto continue
			end
			local has_main = false
			local package_name = ""
			local class_name = ""

			-- Check each line for package, class, and main method
			for _, line in ipairs(file_lines) do
				-- Extract package
				local pkg_match = line:match("^package%s+([%w%.]+)")
				if pkg_match then
					package_name = pkg_match
				end

				-- Extract class name
				local class_match = line:match("public%s+class%s+(%w+)") or line:match("class%s+(%w+)")
				if class_match then
					class_name = class_match
				end

				-- Check for main method
				if line:match("public%s+static%s+void%s+main") or line:match("static%s+public%s+void%s+main") then
					has_main = true
				end
			end

			-- If we found a main method and class name, add to results
			if has_main and class_name ~= "" then
				local full_class_name = package_name ~= "" and (package_name .. "." .. class_name) or class_name
				table.insert(main_classes, {
					name = full_class_name,
					file = file_path,
				})
			end
		end
		::continue::
	end

	-- Cache the results
	M.main_classes_cache[cache_key] = {
		classes = main_classes,
		timestamp = current_time,
	}

	return main_classes
end

-- NEW: Function to configure runtime flags for current project
function M.configure_runtime_flags()
	local project_root = find_project_root()
	local current_flags = M.project_runtime_flags[project_root] or ""

	-- Prepare some common flag presets
	local presets = {
		"Custom...",
		"", -- Clear flags
		"-Xmx2g",
		"-Xmx4g",
		"-Xmx2g -XX:+UseG1GC",
		"-Djava.awt.headless=true",
		"-Dspring.profiles.active=dev",
		"-Xms1g -Xmx4g -XX:+UseG1GC",
		"-Dfile.encoding=UTF-8 -Djava.awt.headless=true",
	}

	vim.ui.select(presets, {
		prompt = "Select Runtime Flags (Current: '" .. current_flags .. "')",
		format_item = function(item)
			if item == "Custom..." then
				return "✏️  Custom..."
			elseif item == "" then
				return "🗑️  Clear flags"
			else
				return "⚡ " .. item
			end
		end,
	}, function(selected)
		if not selected then
			vim.notify("Cancelled.", vim.log.levels.INFO)
			return
		end

		if selected == "Custom..." then
			vim.ui.input({
				prompt = "Enter custom runtime flags: ",
				default = current_flags,
			}, function(custom_flags)
				if custom_flags then
					M.project_runtime_flags[project_root] = custom_flags
					vim.notify("✅ Runtime flags set: " .. custom_flags, vim.log.levels.INFO)
				end
			end)
		else
			M.project_runtime_flags[project_root] = selected
			if selected == "" then
				vim.notify("✅ Runtime flags cleared", vim.log.levels.INFO)
			else
				vim.notify("✅ Runtime flags set: " .. selected, vim.log.levels.INFO)
			end
		end
	end)
end

-- NEW: Enhanced run function with runtime flags option
function M.run_main_class_picker()
	local project_root = find_project_root()

	-- If current file has main method, offer to run it directly
	if current_file_has_main() then
		local current_main_class = get_current_file_main_class()
		if current_main_class then
			local current_flags = M.project_runtime_flags[project_root] or ""
			local flag_display = current_flags ~= "" and " (flags: " .. current_flags .. ")" or ""

			local choices = {
				"▶ Run current file (" .. current_main_class .. ")" .. flag_display,
				"📋 Choose from all main classes",
				"⚙️ Configure runtime flags",
			}

			vim.ui.select(choices, {
				prompt = "Java: Run Options",
				format_item = function(item)
					return item
				end,
			}, function(choice)
				if not choice then
					vim.notify("Cancelled.", vim.log.levels.INFO)
					return
				end

				if choice:match("▶ Run current file") then
					M.execute_java_class(current_main_class, project_root)
				elseif choice:match("⚙️ Configure runtime flags") then
					M.configure_runtime_flags()
				else
					M.show_all_main_classes(project_root)
				end
			end)
			return
		end
	end

	-- Fallback to showing all main classes
	M.show_all_main_classes(project_root)
end

-- Show all main classes using file system scan
function M.show_all_main_classes(project_root)
	vim.notify("🔍 Scanning for main classes...", vim.log.levels.INFO)

	-- Find main classes in project
	local main_classes = find_main_classes_in_project(project_root)

	if #main_classes == 0 then
		vim.notify("No main classes found in the project.", vim.log.levels.WARN)
		return
	end

	-- Add runtime flags option to the list
	local class_names = { "⚙️ Configure runtime flags" }
	for _, entry in ipairs(main_classes) do
		table.insert(class_names, entry.name)
	end

	-- Use Neovim's built-in picker
	vim.ui.select(class_names, {
		prompt = "Java: Select Main Class to Run (" .. (#class_names - 1) .. " found)",
		format_item = function(item)
			if item:match("⚙️") then
				return item
			else
				return "▶ " .. item
			end
		end,
	}, function(selected_class)
		-- User cancelled the selection
		if not selected_class then
			vim.notify("Cancelled.", vim.log.levels.INFO)
			return
		end

		if selected_class:match("⚙️") then
			M.configure_runtime_flags()
		else
			M.execute_java_class(selected_class, project_root)
		end
	end)
end

-- Enhanced execution logic with runtime flags support
function M.execute_java_class(class_name, project_root)
	-- Debug: Show what we're checking
	vim.notify("🔍 Checking project root: " .. project_root, vim.log.levels.INFO)

	local pom_path = project_root .. "/pom.xml"
	local gradle_path = project_root .. "/build.gradle"
	local gradle_kts_path = project_root .. "/build.gradle.kts"

	-- Debug: Check file existence
	local pom_exists = vim.fn.filereadable(pom_path) == 1
	local gradle_exists = vim.fn.filereadable(gradle_path) == 1
	local gradle_kts_exists = vim.fn.filereadable(gradle_kts_path) == 1

	-- Get runtime flags for this project
	local runtime_flags = M.project_runtime_flags[project_root] or ""

	local cmd_table
	if pom_exists then
		cmd_table = {
			"mvn",
			"-X",
			"-q",
			"compile",
			"exec:java",
			"-Dexec.mainClass=" .. class_name,
		}

		-- Add runtime flags to Maven command
		if runtime_flags ~= "" then
			table.insert(cmd_table, "-Dexec.args=" .. runtime_flags)
		end

		vim.notify("✅ Detected Maven project", vim.log.levels.INFO)
		vim.notify(vim.tbl_keys(cmd_table))
	elseif gradle_exists or gradle_kts_exists then
		cmd_table = { "gradle", "run", "--console=plain", "-PmainClass=" .. class_name }

		-- Add runtime flags to Gradle command
		if runtime_flags ~= "" then
			table.insert(cmd_table, "-Dexec.args=" .. runtime_flags)
		end

		vim.notify("✅ Detected Gradle project", vim.log.levels.INFO)
	else
		vim.notify("❌ Not a Maven/Gradle project. Cannot run.", vim.log.levels.ERROR)
		vim.notify("Looked for files in: " .. project_root, vim.log.levels.ERROR)
		return
	end

	-- Show runtime flags info if present
	if runtime_flags ~= "" then
		vim.notify("⚡ Using runtime flags: " .. runtime_flags, vim.log.levels.INFO)
	end

	local snacks_ok, snacks = pcall(require, "snacks")
	if snacks_ok then
		local title_suffix = runtime_flags ~= "" and " [" .. runtime_flags .. "]" or ""
		snacks.terminal(cmd_table, {
			cwd = project_root,
			interactive = true,
			shell = "zsh",
			auto_close = false,
			win = {
				style = "terminal",
				border = "rounded",
				backdrop = { bg = "#ff0000" },
				title = "JAVA :: " .. class_name .. title_suffix,
				position = "float",
				scrollback = 10000,
			},
			action_on_keypress = "none",
		})
	else
		vim.notify("snacks.nvim not found. Falling back to termopen.", vim.log.levels.WARN)
		local cmd_str = table.concat(cmd_table, " ")
		vim.fn.termopen(cmd_str, { cwd = project_root })
	end
end

-- NEW: F9 behavior - auto-run if single main class, otherwise pick (original F6 behavior)
function M.run_main_class_auto()
	local project_root = find_project_root()

	-- First check if current file has main method for priority
	if current_file_has_main() then
		local current_main_class = get_current_file_main_class()
		if current_main_class then
			vim.notify("🚀 Auto-running current file: " .. current_main_class, vim.log.levels.INFO)
			M.execute_java_class(current_main_class, project_root)
			return
		end
	end

	-- Find all main classes in project
	vim.notify("🔍 Scanning for main classes...", vim.log.levels.INFO)
	local main_classes = find_main_classes_in_project(project_root)

	if #main_classes == 0 then
		vim.notify("No main classes found in the project.", vim.log.levels.WARN)
		return
	elseif #main_classes == 1 then
		-- Auto-run the single main class
		local single_class = main_classes[1].name
		vim.notify("🚀 Auto-running single main class: " .. single_class, vim.log.levels.INFO)
		M.execute_java_class(single_class, project_root)
	else
		-- Multiple main classes found, show picker (without config options)
		local class_names = {}
		for _, entry in ipairs(main_classes) do
			table.insert(class_names, entry.name)
		end

		vim.ui.select(class_names, {
			prompt = "Java: Select Main Class to Run (" .. #class_names .. " found)",
			format_item = function(item)
				return "▶ " .. item
			end,
		}, function(selected_class)
			if not selected_class then
				vim.notify("Cancelled.", vim.log.levels.INFO)
				return
			end
			M.execute_java_class(selected_class, project_root)
		end)
	end
end

-- F10: Quick run current file's main method (for keybindings)
function M.run_current_main()
	if not current_file_has_main() then
		vim.notify("Current file doesn't have a main method", vim.log.levels.WARN)
		return
	end

	local main_class = get_current_file_main_class()
	if main_class then
		local project_root = find_project_root()
		M.execute_java_class(main_class, project_root)
	else
		vim.notify("Could not determine main class name", vim.log.levels.ERROR)
	end
end

return M
