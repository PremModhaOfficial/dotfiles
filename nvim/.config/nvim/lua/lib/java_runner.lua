-- ~/.config/nvim/lua/config/custom-java.lua
local M = {}

-- Store runtime flags per project (in memory for session)
M.project_runtime_flags = {}

-- Cache for main classes to improve performance
M.main_classes_cache = {}
M.cache_timeout = 30000 -- 30 seconds cache timeout

-- Cache for Vert.x verticles
M.verticles_cache = {}

-- Cache for project type detection
M.project_type_cache = {}

-- Store Vert.x run configurations per project
M.vertx_configurations = {}

-- Store run history (last 10 runs) per project
M.run_history = {}

-- Store favorite configurations per project
M.favorite_configs = {}

-- Add to run history
local function add_to_history(project_root, verticle_name, mode, config)
	if not M.run_history[project_root] then
		M.run_history[project_root] = {}
	end
	
	local history_entry = {
		verticle = verticle_name,
		mode = mode,
		config = vim.deepcopy(config),
		timestamp = os.time(),
	}
	
	-- Remove duplicate if exists
	for i, entry in ipairs(M.run_history[project_root]) do
		if entry.verticle == verticle_name and entry.mode == mode then
			table.remove(M.run_history[project_root], i)
			break
		end
	end
	
	-- Add to front of history
	table.insert(M.run_history[project_root], 1, history_entry)
	
	-- Keep only last 10 entries
	while #M.run_history[project_root] > 10 do
		table.remove(M.run_history[project_root])
	end
end

-- Get recent runs for project
local function get_recent_runs(project_root)
	return M.run_history[project_root] or {}
end

-- Format history entry for display
local function format_history_entry(entry)
	local mode_display = entry.mode
	if entry.config.cluster then mode_display = mode_display .. "+cluster" end
	if entry.config.ha then mode_display = mode_display .. "+ha" end
	if entry.config.redeploy then mode_display = mode_display .. "+hotreload" end
	if entry.config.instances and entry.config.instances > 1 then
		mode_display = mode_display .. " (×" .. entry.config.instances .. ")"
	end
	
	local time_ago = os.difftime(os.time(), entry.timestamp)
	local time_str
	if time_ago < 60 then
		time_str = math.floor(time_ago) .. "s ago"
	elseif time_ago < 3600 then
		time_str = math.floor(time_ago / 60) .. "m ago"
	else
		time_str = math.floor(time_ago / 3600) .. "h ago"
	end
	
	return string.format("🕒 %s [%s] (%s)", entry.verticle, mode_display, time_str)
end

-- Check if port is in use
local function is_port_in_use(port)
	local handle = io.popen("lsof -i:" .. port .. " 2>/dev/null | wc -l")
	if not handle then
		return false
	end
	
	local result = handle:read("*a")
	handle:close()
	
	return tonumber(result) and tonumber(result) > 0
end

-- Common Vert.x ports to check
local function get_default_vertx_ports()
	return {
		8080, -- HTTP server
		8443, -- HTTPS server
		5701, -- Hazelcast cluster
		7800, -- JGroups cluster
	}
end

-- Check for port conflicts and suggest alternatives
-- Callback receives boolean: true to continue, false to cancel
local function check_port_conflicts(config, callback)
	-- Skip check if disabled in config
	if config.skip_port_check then
		callback(true)
		return
	end
	
	local ports_to_check = get_default_vertx_ports()
	local conflicts = {}
	
	for _, port in ipairs(ports_to_check) do
		if is_port_in_use(port) then
			table.insert(conflicts, port)
		end
	end
	
	if #conflicts > 0 then
		local conflict_msg = "⚠️ Ports in use: " .. table.concat(conflicts, ", ")
		vim.notify(conflict_msg, vim.log.levels.WARN)
		
		vim.ui.select({
			"Continue anyway",
			"Suggest alternative ports",
			"Cancel",
		}, {
			prompt = "Port Conflicts Detected",
		}, function(choice)
			if not choice or choice == "Cancel" then
				callback(false)
			elseif choice == "Suggest alternative ports" then
				local suggestions = {}
				for _, port in ipairs(conflicts) do
					-- Suggest port + 1000
					local alt_port = port + 1000
					table.insert(suggestions, string.format("Use %d instead of %d", alt_port, port))
				end
				
				local suggestion_msg = "💡 Suggested alternatives:\n" .. table.concat(suggestions, "\n")
				vim.notify(suggestion_msg, vim.log.levels.INFO)
				callback(true) -- Continue after showing suggestions
			else
				callback(true) -- Continue anyway
			end
		end)
	else
		callback(true) -- No conflicts, continue
	end
end

-- Detect Docker support in project
local function detect_docker_support(project_root)
	local docker_info = {
		has_dockerfile = false,
		has_compose = false,
		compose_files = {},
		dockerfile_path = nil,
	}
	
	-- Check for Dockerfile
	local dockerfile = project_root .. "/Dockerfile"
	if vim.fn.filereadable(dockerfile) == 1 then
		docker_info.has_dockerfile = true
		docker_info.dockerfile_path = dockerfile
	end
	
	-- Check for Docker Compose files
	local compose_files = {
		"docker-compose.yml",
		"docker-compose.yaml",
		"compose.yml",
		"compose.yaml",
	}
	
	for _, compose_file in ipairs(compose_files) do
		local compose_path = project_root .. "/" .. compose_file
		if vim.fn.filereadable(compose_path) == 1 then
			docker_info.has_compose = true
			table.insert(docker_info.compose_files, compose_path)
		end
	end
	
	return docker_info
end

-- Check if Docker is available
local function is_docker_available()
	local handle = io.popen("docker --version 2>/dev/null")
	if not handle then
		return false
	end
	local result = handle:read("*a")
	handle:close()
	return result and result:match("Docker version")
end

-- Build Docker image for Vert.x project
local function build_docker_image(project_root, dockerfile_path, callback)
	local image_name = "vertx-app:" .. vim.fn.fnamemodify(project_root, ":t")
	
	vim.notify("🐳 Building Docker image: " .. image_name, vim.log.levels.INFO)
	
	local cmd = string.format("cd %s && docker build -t %s -f %s .", 
		vim.fn.shellescape(project_root),
		vim.fn.shellescape(image_name),
		vim.fn.shellescape(dockerfile_path))
	
	local snacks_ok, snacks = pcall(require, "snacks")
	if snacks_ok then
		snacks.terminal(cmd, {
			cwd = project_root,
			interactive = false,
			win = {
				title = "Docker Build",
				border = "rounded",
				backdrop = { bg = "#2496ed" },
			},
			on_exit = function(result)
				if result.code == 0 then
					vim.notify("✅ Docker image built successfully: " .. image_name, vim.log.levels.INFO)
					callback(true, image_name)
				else
					vim.notify("❌ Docker build failed", vim.log.levels.ERROR)
					callback(false, nil)
				end
			end,
		})
	else
		-- Fallback to system call
		local exit_code = os.execute(cmd)
		if exit_code == 0 then
			vim.notify("✅ Docker image built successfully: " .. image_name, vim.log.levels.INFO)
			callback(true, image_name)
		else
			vim.notify("❌ Docker build failed", vim.log.levels.ERROR)
			callback(false, nil)
		end
	end
end

-- Run Vert.x in Docker container
local function run_in_docker(verticle_name, project_root, config, image_name)
	local container_name = "vertx-" .. vim.fn.fnamemodify(project_root, ":t")
	
	-- Build docker run command
	local docker_cmd = "docker run --rm -it --name " .. vim.fn.shellescape(container_name)
	
	-- Map common Vert.x ports
	docker_cmd = docker_cmd .. " -p 8080:8080 -p 8443:8443"
	
	-- Add cluster ports if needed
	if config.cluster then
		docker_cmd = docker_cmd .. " -p 5701:5701 -p 7800:7800"
	end
	
	-- Mount config file if specified
	if config.config_file then
		local config_path = project_root .. "/" .. config.config_file
		docker_cmd = docker_cmd .. " -v " .. vim.fn.shellescape(config_path) .. ":/app/config.json"
	end
	
	-- Add environment variables
	if config.cluster then
		docker_cmd = docker_cmd .. " -e VERTX_CLUSTER=true"
	end
	if config.ha then
		docker_cmd = docker_cmd .. " -e VERTX_HA=true"
	end
	
	docker_cmd = docker_cmd .. " " .. vim.fn.shellescape(image_name)
	
	vim.notify("🐳 Running Vert.x in Docker: " .. container_name, vim.log.levels.INFO)
	
	local snacks_ok, snacks = pcall(require, "snacks")
	if snacks_ok then
		snacks.terminal(docker_cmd, {
			cwd = project_root,
			interactive = true,
			shell = "zsh",
			auto_close = false,
			win = {
				style = "terminal",
				border = "rounded",
				backdrop = { bg = "#2496ed" },
				title = "🐳 DOCKER :: " .. verticle_name,
				position = "float",
				scrollback = 10000,
			},
		})
	else
		vim.fn.termopen(docker_cmd, { cwd = project_root })
	end
end

-- Run Docker Compose
local function run_docker_compose(project_root, compose_file)
	local cmd = string.format("cd %s && docker compose -f %s up",
		vim.fn.shellescape(project_root),
		vim.fn.shellescape(compose_file))
	
	vim.notify("🐳 Starting Docker Compose services", vim.log.levels.INFO)
	
	local snacks_ok, snacks = pcall(require, "snacks")
	if snacks_ok then
		snacks.terminal(cmd, {
			cwd = project_root,
			interactive = true,
			shell = "zsh",
			auto_close = false,
			win = {
				style = "terminal",
				border = "rounded",
				backdrop = { bg = "#2496ed" },
				title = "🐳 Docker Compose",
				position = "float",
				scrollback = 10000,
			},
		})
	else
		vim.fn.termopen(cmd, { cwd = project_root })
	end
end

-- Detect if project is Vert.x, standard Java, or unknown
local function detect_project_type(project_root)
	local cache_key = project_root
	local cached = M.project_type_cache[cache_key]
	local current_time = vim.uv.now()

	if cached and (current_time - cached.timestamp) < M.cache_timeout then
		return cached.project_type, cached.confidence
	end

	local project_type = "unknown"
	local confidence = 0

	-- Check Maven pom.xml for Vert.x dependencies
	local pom_path = project_root .. "/pom.xml"
	if vim.fn.filereadable(pom_path) == 1 then
		local pom_content = table.concat(vim.fn.readfile(pom_path), "\n")
		if pom_content:match("io%.vertx") or pom_content:match("vertx%-") then
			project_type = "vertx"
			confidence = 95
		else
			project_type = "standard"
			confidence = 90
		end
	end

	-- Check Gradle build files for Vert.x dependencies
	local gradle_files = {
		project_root .. "/build.gradle",
		project_root .. "/build.gradle.kts",
	}
	for _, gradle_path in ipairs(gradle_files) do
		if vim.fn.filereadable(gradle_path) == 1 then
			local gradle_content = table.concat(vim.fn.readfile(gradle_path), "\n")
			if gradle_content:match("io%.vertx") or gradle_content:match("vertx%-") then
				project_type = "vertx"
				confidence = 95
			elseif project_type == "unknown" then
				project_type = "standard"
				confidence = 90
			end
		end
	end

	-- Cache the result
	M.project_type_cache[cache_key] = {
		project_type = project_type,
		confidence = confidence,
		timestamp = current_time,
	}

	return project_type, confidence
end

-- Find verticles by scanning for classes extending AbstractVerticle
local function find_verticles_in_project(project_root)
	local cache_key = project_root
	local cached = M.verticles_cache[cache_key]
	local current_time = vim.uv.now()

	if cached and (current_time - cached.timestamp) < M.cache_timeout then
		return cached.verticles
	end

	local verticles = {}
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
				goto continue
			end

			local is_verticle = false
			local package_name = ""
			local class_name = ""

			for _, line in ipairs(file_lines) do
				local pkg_match = line:match("^package%s+([%w%.]+)")
				if pkg_match then
					package_name = pkg_match
				end

				local class_match = line:match("public%s+class%s+(%w+)") or line:match("class%s+(%w+)")
				if class_match then
					class_name = class_match
				end

				-- Check for AbstractVerticle extension
				if line:match("extends%s+AbstractVerticle") then
					is_verticle = true
				end

				-- Check for Verticle interface implementation
				if line:match("implements%s+Verticle") or line:match("implements%s+[%w%.]*Verticle") then
					is_verticle = true
				end

				-- Check for @Verticle annotation
				if line:match("@Verticle") then
					is_verticle = true
				end
			end

			if is_verticle and class_name ~= "" then
				local full_class_name = package_name ~= "" and (package_name .. "." .. class_name) or class_name
				table.insert(verticles, {
					name = full_class_name,
					file = file_path,
				})
			end
		end
		::continue::
	end

	M.verticles_cache[cache_key] = {
		verticles = verticles,
		timestamp = current_time,
	}

	return verticles
end

-- Generate Vert.x run commands for a verticle with execution mode support
local function get_vertx_run_commands(verticle_name, project_root, execution_mode, config)
	execution_mode = execution_mode or "launcher"
	config = config or {}

	local pom_path = project_root .. "/pom.xml"
	local gradle_path = project_root .. "/build.gradle"
	local gradle_kts_path = project_root .. "/build.gradle.kts"

	local runtime_flags = M.project_runtime_flags[project_root] or ""
	local cmd_table = {}

	local launcher_args = "run " .. verticle_name
	
	-- Add cluster mode if enabled
	if config.cluster then
		launcher_args = launcher_args .. " --cluster"
	end
	
	-- Add HA mode if enabled
	if config.ha then
		launcher_args = launcher_args .. " --ha"
	end
	
	-- Add redeploy for hot reload
	if config.redeploy then
		launcher_args = launcher_args .. " --redeploy=**/*.java --on-redeploy=mvn compile"
	end
	
	-- Add worker pool size
	if config.worker_pool_size then
		launcher_args = launcher_args .. " --worker-pool-size=" .. config.worker_pool_size
	end
	
	-- Add instances
	if config.instances and config.instances > 1 then
		launcher_args = launcher_args .. " --instances=" .. config.instances
	end
	
	-- Add config file
	if config.config_file then
		launcher_args = launcher_args .. " --conf=" .. config.config_file
	end

	if execution_mode == "launcher" then
		-- Standard Vert.x Launcher execution
		if vim.fn.filereadable(pom_path) == 1 then
			cmd_table = {
				"mvn",
				"compile",
				"exec:java",
				"-Dexec.mainClass=io.vertx.core.Launcher",
				"-Dexec.args=" .. launcher_args,
			}
			
			if runtime_flags ~= "" then
				table.insert(cmd_table, "-Dexec.vmArgs=" .. runtime_flags)
			end
		elseif vim.fn.filereadable(gradle_path) == 1 or vim.fn.filereadable(gradle_kts_path) == 1 then
			cmd_table = {
				"gradle",
				"run",
				"--console=plain",
				"-PmainClass=io.vertx.core.Launcher",
				"-Pargs=" .. launcher_args,
			}
			
			if runtime_flags ~= "" then
				table.insert(cmd_table, "-Djvm.args=" .. runtime_flags)
			end
		end
	elseif execution_mode == "fatjar" then
		-- Fat JAR execution
		local jar_pattern = project_root .. "/target/*-fat.jar"
		local jar_files = vim.fn.glob(jar_pattern, false, true)
		
		if #jar_files > 0 then
			cmd_table = { "java" }
			
			if runtime_flags ~= "" then
				for flag in runtime_flags:gmatch("%S+") do
					table.insert(cmd_table, flag)
				end
			end
			
			table.insert(cmd_table, "-jar")
			table.insert(cmd_table, jar_files[1])
			table.insert(cmd_table, launcher_args)
		else
			-- Build fat jar first
			if vim.fn.filereadable(pom_path) == 1 then
				cmd_table = { "mvn", "clean", "package", "&&", "java", "-jar", "target/*-fat.jar", launcher_args }
			end
		end
	elseif execution_mode == "direct" then
		-- Direct execution without Launcher
		if vim.fn.filereadable(pom_path) == 1 then
			cmd_table = {
				"mvn",
				"compile",
				"exec:java",
				"-Dexec.mainClass=" .. verticle_name,
			}
			
			if runtime_flags ~= "" then
				table.insert(cmd_table, "-Dexec.vmArgs=" .. runtime_flags)
			end
		elseif vim.fn.filereadable(gradle_path) == 1 or vim.fn.filereadable(gradle_kts_path) == 1 then
			cmd_table = {
				"gradle",
				"run",
				"--console=plain",
				"-PmainClass=" .. verticle_name,
			}
			
			if runtime_flags ~= "" then
				table.insert(cmd_table, "-Djvm.args=" .. runtime_flags)
			end
		end
	end

	return cmd_table
end

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
	local current_time = vim.uv.now()

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
	local project_type, confidence = detect_project_type(project_root)

	-- If Vert.x project detected, show verticle picker
	if project_type == "vertx" then
		-- Try to load saved configuration
		M.load_vertx_configuration(project_root)
		
		vim.notify("🔮 Vert.x project detected (confidence: " .. confidence .. "%)", vim.log.levels.INFO)
		M.show_verticle_picker(project_root)
		return
	end

	-- Standard Java project behavior (unchanged)
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

-- Show verticle picker for Vert.x projects
function M.show_verticle_picker(project_root)
	vim.notify("🔍 Scanning for Vert.x verticles...", vim.log.levels.INFO)

	local verticles = find_verticles_in_project(project_root)

	if #verticles == 0 then
		vim.notify("No verticles found. Falling back to standard main classes.", vim.log.levels.WARN)
		M.show_all_main_classes(project_root)
		return
	end

	-- Try to use Snacks picker for fuzzy search
	local snacks_ok, snacks = pcall(require, "snacks")
	if snacks_ok and snacks.picker then
		local items = {
			{ text = "📜 Recent runs", action = "recent" },
			{ text = "⭐ Favorites", action = "favorites" },
			{ text = "⚙️ Configure runtime flags", action = "config" },
			{ text = "💾 Save configuration", action = "save" },
		}
		
		for _, entry in ipairs(verticles) do
			table.insert(items, {
				text = "🔮 " .. entry.name,
				file = entry.file,
				verticle = entry.name,
				action = "run",
			})
		end
		
		snacks.picker.pick({
			source = items,
			prompt = "Vert.x: Select Verticle (" .. #verticles .. " found)",
			preview = function(item)
				if item.file then
					return { file = item.file }
				end
			end,
			format = function(item)
				return item.text
			end,
			confirm = function(item)
				if item.action == "recent" then
					M.show_recent_runs(project_root)
				elseif item.action == "favorites" then
					M.show_favorites(project_root)
				elseif item.action == "config" then
					M.configure_runtime_flags()
				elseif item.action == "save" then
					M.save_vertx_configuration(project_root)
				elseif item.action == "run" then
					M.show_execution_mode_picker(item.verticle, project_root)
				end
			end,
		})
		return
	end

	-- Fallback to vim.ui.select
	local verticle_names = { 
		"📜 Recent runs", 
		"⭐ Favorites",
		"⚙️ Configure runtime flags", 
		"💾 Save configuration" 
	}
	for _, entry in ipairs(verticles) do
		table.insert(verticle_names, entry.name)
	end

	vim.ui.select(verticle_names, {
		prompt = "Vert.x: Select Verticle to Run (" .. (#verticle_names - 4) .. " found)",
		format_item = function(item)
			if item:match("⚙️") or item:match("💾") or item:match("📜") or item:match("⭐") then
				return item
			else
				return "🔮 " .. item
			end
		end,
	}, function(selected_verticle)
		if not selected_verticle then
			vim.notify("Cancelled.", vim.log.levels.INFO)
			return
		end

		if selected_verticle:match("📜") then
			M.show_recent_runs(project_root)
		elseif selected_verticle:match("⭐") then
			M.show_favorites(project_root)
		elseif selected_verticle:match("⚙️") then
			M.configure_runtime_flags()
		elseif selected_verticle:match("💾") then
			M.save_vertx_configuration(project_root)
		else
			M.show_execution_mode_picker(selected_verticle, project_root)
		end
	end)
end

-- Show execution mode picker for a verticle
function M.show_execution_mode_picker(verticle_name, project_root)
	-- Check for Docker support
	local docker_info = detect_docker_support(project_root)
	local docker_available = is_docker_available()
	
	local modes = {
		{ name = "▶️ Standard Run (Launcher)", mode = "launcher", config = {}, help = "Run verticle using io.vertx.core.Launcher" },
		{ name = "🔄 Development (Hot Reload)", mode = "launcher", config = { redeploy = true }, help = "Auto-recompile and reload on file changes" },
		{ name = "🌐 Cluster Mode", mode = "launcher", config = { cluster = true }, help = "Run in clustered mode with event bus bridge" },
		{ name = "🏗️ High Availability", mode = "launcher", config = { ha = true }, help = "Enable HA mode for failover support" },
		{ name = "📦 Fat JAR", mode = "fatjar", config = {}, help = "Build and run as standalone fat JAR" },
		{ name = "⚡ Direct Execution", mode = "direct", config = {}, help = "Run verticle directly without Launcher wrapper" },
		{ name = "⚙️ Custom Configuration...", mode = "custom", config = {}, help = "Build custom configuration with all options" },
	}
	
	-- Add Docker option if available
	if docker_available and (docker_info.has_dockerfile or docker_info.has_compose) then
		table.insert(modes, 7, { 
			name = "🐳 Run in Docker", 
			mode = "docker", 
			config = { docker_info = docker_info }, 
			help = "Run in Docker container" 
		})
	end
	
	-- Add utility options at the end
	table.insert(modes, { name = "⭐ Add to Favorites", mode = "favorite", config = {}, help = "Save current configuration as favorite" })
	table.insert(modes, { name = "❓ Help", mode = "help", config = {}, help = "Show detailed help for execution modes" })

	local mode_names = {}
	for _, m in ipairs(modes) do
		table.insert(mode_names, m.name)
	end

	vim.ui.select(mode_names, {
		prompt = "Select Execution Mode for " .. verticle_name .. " (Press '?' for help)",
		format_item = function(item)
			return item
		end,
	}, function(selected_name)
		if not selected_name then
			vim.notify("Cancelled.", vim.log.levels.INFO)
			return
		end

		local selected_mode
		for _, m in ipairs(modes) do
			if m.name == selected_name then
				selected_mode = m
				break
			end
		end

		if selected_mode.mode == "help" then
			M.show_execution_modes_help()
		elseif selected_mode.mode == "custom" then
			M.show_custom_config_picker(verticle_name, project_root)
		elseif selected_mode.mode == "favorite" then
			M.add_to_favorites(project_root, verticle_name, "launcher", {})
		elseif selected_mode.mode == "docker" then
			M.show_docker_picker(verticle_name, project_root, selected_mode.config.docker_info)
		else
			M.execute_vertx_verticle(verticle_name, project_root, selected_mode.mode, selected_mode.config)
		end
	end)
end

-- Show Docker execution options
function M.show_docker_picker(verticle_name, project_root, docker_info)
	local options = {}
	
	if docker_info.has_dockerfile then
		table.insert(options, "🐳 Build & Run in Docker")
	end
	
	if docker_info.has_compose then
		for _, compose_file in ipairs(docker_info.compose_files) do
			local compose_name = vim.fn.fnamemodify(compose_file, ":t")
			table.insert(options, "🐳 Docker Compose (" .. compose_name .. ")")
		end
	end
	
	table.insert(options, "⚙️ Configure Docker options")
	
	vim.ui.select(options, {
		prompt = "Docker Execution Options",
	}, function(selected)
		if not selected then
			return
		end
		
		if selected:match("Build & Run") then
			-- Build Docker image then run
			build_docker_image(project_root, docker_info.dockerfile_path, function(success, image_name)
				if success then
					run_in_docker(verticle_name, project_root, {}, image_name)
				end
			end)
		elseif selected:match("Docker Compose") then
			-- Extract compose file name and run
			local compose_name = selected:match("%((.+)%)")
			for _, compose_file in ipairs(docker_info.compose_files) do
				if vim.fn.fnamemodify(compose_file, ":t") == compose_name then
					run_docker_compose(project_root, compose_file)
					break
				end
			end
		elseif selected:match("Configure") then
			-- Show configuration options for Docker
			vim.ui.select({
				"Enable cluster mode",
				"Enable HA mode",
				"Add custom ports",
				"Set config file",
			}, {
				prompt = "Docker Configuration",
			}, function(config_option)
				if config_option then
					vim.notify("Docker configuration: " .. config_option, vim.log.levels.INFO)
					-- TODO: Implement docker config options
				end
			end)
		end
	end)
end

-- Show detailed help for execution modes
function M.show_execution_modes_help()
	local help_text = [[
# Vert.x Execution Modes Help

▶️ Standard Run (Launcher)
   Uses io.vertx.core.Launcher to run the verticle.
   Best for: Production-like testing

🔄 Development (Hot Reload)
   Watches for file changes and auto-recompiles.
   Flags: --redeploy=**/*.java --on-redeploy=mvn compile
   Best for: Active development

🌐 Cluster Mode
   Enables clustering with Hazelcast.
   Flags: --cluster
   Best for: Multi-instance deployments

🏗️ High Availability
   Enables HA mode for automatic failover.
   Flags: --ha
   Best for: Production systems requiring high uptime

📦 Fat JAR
   Packages all dependencies into a single executable JAR.
   Best for: Distribution and deployment

⚡ Direct Execution
   Runs verticle class directly without Launcher.
   Best for: Quick testing and debugging

🐳 Run in Docker
   Builds Docker image and runs in container.
   Supports: Port mapping, environment variables, compose
   Best for: Container-based deployments

⚙️ Custom Configuration
   Build custom setup with:
   - Cluster mode toggle
   - HA mode toggle
   - Hot reload toggle
   - Instance count (1-N)
   - Worker pool size
   - Config file path

⭐ Add to Favorites
   Save frequently-used configurations for quick access.

Keybindings (in verticle files):
- <leader>rv : Run this verticle
- <leader>dv : Debug this verticle

For more info: https://vertx.io/docs/vertx-core/java/
]]
	
	-- Create a floating window to show help
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(help_text, "\n"))
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	
	local width = math.min(80, vim.o.columns - 4)
	local height = math.min(35, vim.o.lines - 4)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)
	
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " Vert.x Execution Modes Help ",
		title_pos = "center",
	})
	
	-- Close on q or Escape
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
	vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, nowait = true })
end

-- Show custom configuration picker
function M.show_custom_config_picker(verticle_name, project_root)
	local custom_config = {
		cluster = false,
		ha = false,
		redeploy = false,
		instances = 1,
		worker_pool_size = nil,
		config_file = nil,
	}

	local options = {
		"🌐 Cluster Mode: " .. tostring(custom_config.cluster),
		"🏗️ High Availability: " .. tostring(custom_config.ha),
		"🔄 Hot Reload: " .. tostring(custom_config.redeploy),
		"📊 Instances: " .. custom_config.instances,
		"⚙️ Worker Pool Size: " .. (custom_config.worker_pool_size or "default"),
		"📄 Config File: " .. (custom_config.config_file or "none"),
		"✅ Run with these settings",
	}

	local function show_config_menu()
		vim.ui.select(options, {
			prompt = "Configure " .. verticle_name,
			format_item = function(item)
				return item
			end,
		}, function(selected)
			if not selected then
				vim.notify("Cancelled.", vim.log.levels.INFO)
				return
			end

			if selected:match("Cluster Mode") then
				custom_config.cluster = not custom_config.cluster
				options[1] = "🌐 Cluster Mode: " .. tostring(custom_config.cluster)
				show_config_menu()
			elseif selected:match("High Availability") then
				custom_config.ha = not custom_config.ha
				options[2] = "🏗️ High Availability: " .. tostring(custom_config.ha)
				show_config_menu()
			elseif selected:match("Hot Reload") then
				custom_config.redeploy = not custom_config.redeploy
				options[3] = "🔄 Hot Reload: " .. tostring(custom_config.redeploy)
				show_config_menu()
			elseif selected:match("Instances") then
				vim.ui.input({ prompt = "Number of instances: ", default = tostring(custom_config.instances) }, function(input)
					if input then
						custom_config.instances = tonumber(input) or 1
						options[4] = "📊 Instances: " .. custom_config.instances
					end
					show_config_menu()
				end)
			elseif selected:match("Worker Pool Size") then
				vim.ui.input({
					prompt = "Worker pool size (leave empty for default): ",
					default = custom_config.worker_pool_size or "",
				}, function(input)
					if input and input ~= "" then
						custom_config.worker_pool_size = tonumber(input)
						options[5] = "⚙️ Worker Pool Size: " .. custom_config.worker_pool_size
					else
						custom_config.worker_pool_size = nil
						options[5] = "⚙️ Worker Pool Size: default"
					end
					show_config_menu()
				end)
			elseif selected:match("Config File") then
				vim.ui.input({
					prompt = "Config file path (relative to project root): ",
					default = custom_config.config_file or "",
				}, function(input)
					if input and input ~= "" then
						custom_config.config_file = input
						options[6] = "📄 Config File: " .. input
					else
						custom_config.config_file = nil
						options[6] = "📄 Config File: none"
					end
					show_config_menu()
				end)
			elseif selected:match("✅") then
				M.execute_vertx_verticle(verticle_name, project_root, "launcher", custom_config)
			end
		end)
	end

	show_config_menu()
end

-- Execute Vert.x verticle
function M.execute_vertx_verticle(verticle_name, project_root, execution_mode, config)
	execution_mode = execution_mode or "launcher"
	config = config or {}

	-- Check for port conflicts before running (async)
	check_port_conflicts(config, function(should_continue)
		if not should_continue then
			vim.notify("❌ Execution cancelled due to port conflicts", vim.log.levels.WARN)
			return
		end

		-- Add to history
		add_to_history(project_root, verticle_name, execution_mode, config)

		local cmd_table = get_vertx_run_commands(verticle_name, project_root, execution_mode, config)

		if #cmd_table == 0 then
			vim.notify("❌ Could not generate Vert.x run command. Not a Maven/Gradle project?", vim.log.levels.ERROR)
			return
		end

		local runtime_flags = M.project_runtime_flags[project_root] or ""
		if runtime_flags ~= "" then
			vim.notify("⚡ Using runtime flags: " .. runtime_flags, vim.log.levels.INFO)
		end

		local mode_display = execution_mode
		if config.cluster then
			mode_display = mode_display .. "+cluster"
		end
		if config.ha then
			mode_display = mode_display .. "+ha"
		end
		if config.redeploy then
			mode_display = mode_display .. "+hotreload"
		end

		vim.notify("🔮 Running Vert.x verticle (" .. mode_display .. "): " .. verticle_name, vim.log.levels.INFO)

		local snacks_ok, snacks = pcall(require, "snacks")
		if snacks_ok then
			local title_suffix = runtime_flags ~= "" and " [" .. runtime_flags .. "]" or ""
			title_suffix = title_suffix .. " [" .. mode_display .. "]"
			
			snacks.terminal(cmd_table, {
				cwd = project_root,
				interactive = true,
				shell = "zsh",
				auto_close = false,
				win = {
					style = "terminal",
					border = "rounded",
					backdrop = { bg = "#9966cc" },
					title = "VERT.X :: " .. verticle_name .. title_suffix,
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
	end)
end

-- Save Vert.x configuration to disk
function M.save_vertx_configuration(project_root)
	local config_dir = project_root .. "/.nvim"
	local config_file = config_dir .. "/vertx-config.json"

	-- Create .nvim directory if it doesn't exist
	if vim.fn.isdirectory(config_dir) == 0 then
		vim.fn.mkdir(config_dir, "p")
	end

	local config_data = {
		runtime_flags = M.project_runtime_flags[project_root] or "",
		configurations = M.vertx_configurations[project_root] or {},
		run_history = M.run_history[project_root] or {},
		favorites = M.favorite_configs[project_root] or {},
		version = "1.0",
		timestamp = os.date("%Y-%m-%d %H:%M:%S"),
	}

	local json_str = vim.fn.json_encode(config_data)
	local success = pcall(vim.fn.writefile, { json_str }, config_file)

	if success then
		vim.notify("✅ Configuration saved to " .. config_file, vim.log.levels.INFO)
	else
		vim.notify("❌ Failed to save configuration", vim.log.levels.ERROR)
	end
end

-- Load Vert.x configuration from disk
function M.load_vertx_configuration(project_root)
	local config_file = project_root .. "/.nvim/vertx-config.json"

	if vim.fn.filereadable(config_file) == 0 then
		return false
	end

	local success, file_content = pcall(vim.fn.readfile, config_file)
	if not success then
		return false
	end

	local json_str = table.concat(file_content, "\n")
	local ok, config_data = pcall(vim.fn.json_decode, json_str)

	if ok and config_data then
		if config_data.runtime_flags then
			M.project_runtime_flags[project_root] = config_data.runtime_flags
		end
		if config_data.configurations then
			M.vertx_configurations[project_root] = config_data.configurations
		end
		if config_data.run_history then
			M.run_history[project_root] = config_data.run_history
		end
		if config_data.favorites then
			M.favorite_configs[project_root] = config_data.favorites
		end
		vim.notify("✅ Configuration loaded from " .. config_file, vim.log.levels.INFO)
		return true
	end

	return false
end

-- Show recent runs menu
function M.show_recent_runs(project_root)
	local recent = get_recent_runs(project_root)
	
	if #recent == 0 then
		vim.notify("No recent runs found", vim.log.levels.INFO)
		return
	end
	
	local options = {}
	for _, entry in ipairs(recent) do
		table.insert(options, format_history_entry(entry))
	end
	
	vim.ui.select(options, {
		prompt = "Recent Runs (" .. #options .. " entries)",
		format_item = function(item)
			return item
		end,
	}, function(selected)
		if not selected then
			return
		end
		
		-- Find the selected entry
		for i, opt in ipairs(options) do
			if opt == selected then
				local entry = recent[i]
				M.execute_vertx_verticle(entry.verticle, project_root, entry.mode, entry.config)
				break
			end
		end
	end)
end

-- Add configuration to favorites
function M.add_to_favorites(project_root, verticle_name, mode, config)
	if not M.favorite_configs[project_root] then
		M.favorite_configs[project_root] = {}
	end
	
	local fav_entry = {
		verticle = verticle_name,
		mode = mode,
		config = vim.deepcopy(config),
		name = vim.fn.input("Favorite name: ", verticle_name .. " (" .. mode .. ")"),
	}
	
	if fav_entry.name ~= "" then
		table.insert(M.favorite_configs[project_root], fav_entry)
		vim.notify("⭐ Added to favorites: " .. fav_entry.name, vim.log.levels.INFO)
	end
end

-- Show favorites menu
function M.show_favorites(project_root)
	local favorites = M.favorite_configs[project_root] or {}
	
	if #favorites == 0 then
		vim.notify("No favorites found. Add some from execution mode picker!", vim.log.levels.INFO)
		return
	end
	
	local options = { "🗑️ Remove a favorite" }
	for _, fav in ipairs(favorites) do
		table.insert(options, "⭐ " .. fav.name)
	end
	
	vim.ui.select(options, {
		prompt = "Favorites (" .. (#options - 1) .. " entries)",
		format_item = function(item)
			return item
		end,
	}, function(selected)
		if not selected then
			return
		end
		
		if selected:match("🗑️") then
			M.remove_from_favorites(project_root)
		else
			-- Find and run the selected favorite
			for i = 1, #favorites do
				if "⭐ " .. favorites[i].name == selected then
					local fav = favorites[i]
					M.execute_vertx_verticle(fav.verticle, project_root, fav.mode, fav.config)
					break
				end
			end
		end
	end)
end

-- Remove a favorite
function M.remove_from_favorites(project_root)
	local favorites = M.favorite_configs[project_root] or {}
	
	if #favorites == 0 then
		vim.notify("No favorites to remove", vim.log.levels.INFO)
		return
	end
	
	local options = {}
	for _, fav in ipairs(favorites) do
		table.insert(options, fav.name)
	end
	
	vim.ui.select(options, {
		prompt = "Remove favorite",
		format_item = function(item)
			return "🗑️ " .. item
		end,
	}, function(selected)
		if not selected then
			return
		end
		
		for i = #favorites, 1, -1 do
			if favorites[i].name == selected then
				table.remove(favorites, i)
				vim.notify("Removed favorite: " .. selected, vim.log.levels.INFO)
				break
			end
		end
	end)
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
		vim.notify("Command: " .. table.concat(cmd_table, " "), vim.log.levels.INFO)
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

-- Check if current file is a verticle
local function is_current_file_verticle()
	local success, buf_lines = pcall(vim.api.nvim_buf_get_lines, 0, 0, -1, false)
	if not success then
		return false
	end
	
	for _, line in ipairs(buf_lines) do
		if line:match("extends%s+AbstractVerticle") or 
		   line:match("implements%s+Verticle") or 
		   line:match("@Verticle") then
			return true
		end
	end
	return false
end

-- Setup LSP code actions for Java/Vert.x
function M.setup_code_actions()
	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("JavaVertxCodeActions", { clear = true }),
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if not client or client.name ~= "jdtls" then
				return
			end
			
			local bufnr = args.buf
			
			-- Add code action for running verticle
			vim.api.nvim_buf_create_user_command(bufnr, "RunThisVerticle", function()
				local project_root = find_project_root()
				local project_type = detect_project_type(project_root)
				
				if project_type ~= "vertx" then
					vim.notify("Not a Vert.x project", vim.log.levels.WARN)
					return
				end
				
				if not is_current_file_verticle() then
					vim.notify("Current file is not a verticle", vim.log.levels.WARN)
					return
				end
				
				local verticle_class = get_current_file_main_class()
				if verticle_class then
					M.show_execution_mode_picker(verticle_class, project_root)
				else
					vim.notify("Could not determine verticle class name", vim.log.levels.ERROR)
				end
			end, { desc = "Run this Vert.x verticle" })
			
			-- Add code action for debugging verticle
			vim.api.nvim_buf_create_user_command(bufnr, "DebugThisVerticle", function()
				local project_root = find_project_root()
				local project_type = detect_project_type(project_root)
				
				if project_type ~= "vertx" then
					vim.notify("Not a Vert.x project", vim.log.levels.WARN)
					return
				end
				
				if not is_current_file_verticle() then
					vim.notify("Current file is not a verticle", vim.log.levels.WARN)
					return
				end
				
				local verticle_class = get_current_file_main_class()
				if verticle_class then
					M.debug_vertx_verticle(verticle_class, project_root)
				else
					vim.notify("Could not determine verticle class name", vim.log.levels.ERROR)
				end
			end, { desc = "Debug this Vert.x verticle" })
			
			-- Add keybinding for quick run
			if is_current_file_verticle() then
				vim.keymap.set("n", "<leader>rv", function()
					vim.cmd("RunThisVerticle")
				end, { buffer = bufnr, desc = "Run Verticle" })
				
				vim.keymap.set("n", "<leader>dv", function()
					vim.cmd("DebugThisVerticle")
				end, { buffer = bufnr, desc = "Debug Verticle" })
			end
		end,
	})
end

-- Debug Vert.x verticle with DAP
function M.debug_vertx_verticle(verticle_name, project_root)
	local dap_ok, dap = pcall(require, "dap")
	if not dap_ok then
		vim.notify("❌ nvim-dap not installed", vim.log.levels.ERROR)
		return
	end
	
	vim.notify("🐛 Starting debug session for: " .. verticle_name, vim.log.levels.INFO)
	
	-- Build the project first
	local pom_path = project_root .. "/pom.xml"
	local gradle_path = project_root .. "/build.gradle"
	
	local build_cmd
	if vim.fn.filereadable(pom_path) == 1 then
		build_cmd = "mvn compile"
	elseif vim.fn.filereadable(gradle_path) == 1 then
		build_cmd = "gradle compileJava"
	else
		vim.notify("❌ Not a Maven/Gradle project", vim.log.levels.ERROR)
		return
	end
	
	-- Build then debug
	vim.fn.jobstart(build_cmd, {
		cwd = project_root,
		on_exit = function(_, exit_code)
			if exit_code ~= 0 then
				vim.notify("❌ Build failed", vim.log.levels.ERROR)
				return
			end
			
			vim.schedule(function()
				-- Create Vert.x debug configuration
				dap.run({
					type = "java",
					request = "launch",
					name = "Debug Vert.x Verticle: " .. verticle_name,
					mainClass = "io.vertx.core.Launcher",
					args = "run " .. verticle_name,
					projectName = vim.fn.fnamemodify(project_root, ":t"),
					cwd = project_root,
					vmArgs = M.project_runtime_flags[project_root] or "",
				})
			end)
		end,
	})
end

return M
