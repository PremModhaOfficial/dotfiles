local M = {}

local function find_project_root()
	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if git_root and git_root ~= "" then return git_root end
	return vim.fn.getcwd()
end

local function get_current_file_main_class()
	local ok, lines = pcall(vim.api.nvim_buf_get_lines, 0, 0, -1, false)
	if not ok then return nil end
	local pkg, cls = "", ""
	for _, l in ipairs(lines) do
		if not pkg then pkg = l:match("^package%s+([%w%.]+)") end
		if not cls then cls = l:match("public%s+class%s+(%w+)") or l:match("class%s+(%w+)") end
		if pkg and cls then break end
	end
	if cls and cls ~= "" then
		return (pkg ~= "" and (pkg .. "." .. cls) or cls)
	end
end

local function current_file_has_main()
	local ok, lines = pcall(vim.api.nvim_buf_get_lines, 0, 0, -1, false)
	if not ok then return false end
	for _, l in ipairs(lines) do
		if l:match("public%s+static%s+void%s+main") then return true end
	end
	return false
end

function M.detect_project_type(project_root)
	for _, f in ipairs({ "pom.xml", "build.gradle", "build.gradle.kts" }) do
		if vim.fn.filereadable(project_root .. "/" .. f) == 1 then
			return "maven"
		end
	end
	return "unknown"
end

local function find_main_classes_in_project(project_root)
	local files = vim.fn.systemlist(string.format("find '%s' -name '*.java' -type f 2>/dev/null", project_root))
	if vim.v.shell_error ~= 0 then return {} end
	local result = {}
	for _, fp in ipairs(files) do
		local ok, fl = pcall(vim.fn.readfile, fp)
		if ok then
			local pkg, cls, has_main = "", "", false
			for _, l in ipairs(fl) do
				if not pkg then pkg = l:match("^package%s+([%w%.]+)") end
				if not cls then cls = l:match("public%s+class%s+(%w+)") or l:match("class%s+(%w+)") end
				if l:match("public%s+static%s+void%s+main") then has_main = true end
			end
			if has_main and cls and cls ~= "" then
				table.insert(result, { name = (pkg ~= "" and (pkg .. "." .. cls) or cls), file = fp })
			end
		end
	end
	return result
end

local function launch(cmd_table, opts)
	local snacks_ok, snacks = pcall(require, "snacks")
	if snacks_ok then
		snacks.terminal(cmd_table, vim.tbl_extend("force", {
			cwd = opts.cwd,
			interactive = true,
			shell = "zsh",
			auto_close = false,
			win = {
				style = "terminal",
				border = "rounded",
				title = opts.title or "JAVA",
				position = "float",
				scrollback = 10000,
			},
			action_on_keypress = "none",
		}, opts.extra or {}))
	else
		vim.fn.termopen(table.concat(cmd_table, " "), { cwd = opts.cwd })
	end
end

local function build_cmd_table(class_name, project_root)
	local root = project_root
	if vim.fn.filereadable(root .. "/pom.xml") == 1 then
		return { "mvn", "-q", "compile", "exec:java", "-Dexec.mainClass=" .. class_name }
	elseif vim.fn.filereadable(root .. "/build.gradle") == 1 or vim.fn.filereadable(root .. "/build.gradle.kts") == 1 then
		return { "gradle", "run", "--console=plain", "-PmainClass=" .. class_name }
	end
end

function M.execute_java_class(class_name, project_root)
	local cmd = build_cmd_table(class_name, project_root)
	if not cmd then
		vim.notify("Not a Maven/Gradle project", vim.log.levels.ERROR)
		return
	end
	launch(cmd, { cwd = project_root, title = "JAVA :: " .. class_name })
end

function M.run_main_class_picker()
	local root = find_project_root()
	if current_file_has_main() then
		local cls = get_current_file_main_class()
		if cls then
			vim.ui.select({
				"▶ Run " .. cls,
				"📋 Choose from all main classes",
			}, { prompt = "Java" }, function(choice)
				if not choice then return end
				if choice:match("Run") then
					M.execute_java_class(cls, root)
				else
					M._show_all_main_classes(root)
				end
			end)
			return
		end
	end
	M._show_all_main_classes(root)
end

function M._show_all_main_classes(root)
	local classes = find_main_classes_in_project(root)
	if #classes == 0 then
		vim.notify("No main classes found", vim.log.levels.WARN)
		return
	end
	local names = {}
	for _, c in ipairs(classes) do table.insert(names, c.name) end
	vim.ui.select(names, { prompt = "Java: Run Main Class" }, function(sel)
		if sel then M.execute_java_class(sel, root) end
	end)
end

function M.run_main_class_auto()
	local root = find_project_root()
	if current_file_has_main() then
		local cls = get_current_file_main_class()
		if cls then return M.execute_java_class(cls, root) end
	end
	local classes = find_main_classes_in_project(root)
	if #classes == 0 then
		vim.notify("No main classes found", vim.log.levels.WARN)
	elseif #classes == 1 then
		M.execute_java_class(classes[1].name, root)
	else
		M._show_all_main_classes(root)
	end
end

function M.run_current_main()
	if not current_file_has_main() then
		vim.notify("No main method in current file", vim.log.levels.WARN)
		return
	end
	local cls = get_current_file_main_class()
	if cls then M.execute_java_class(cls, find_project_root()) end
end

function M.debug_java_class()
	local cls = get_current_file_main_class()
	if not cls then vim.notify("Could not determine class", vim.log.levels.ERROR) return end
	local dap_ok, dap = pcall(require, "dap")
	if not dap_ok then vim.notify("nvim-dap not installed", vim.log.levels.ERROR) return end
	local root = find_project_root()
	local build_cmd = vim.fn.filereadable(root .. "/pom.xml") == 1
		and "mvn compile" or "gradle compileJava"
	vim.fn.jobstart(build_cmd, {
		cwd = root,
		on_exit = function(_, code)
			if code ~= 0 then vim.notify("Build failed", vim.log.levels.ERROR) return end
			vim.schedule(function()
				dap.run({
					type = "java", request = "launch",
					name = "Debug " .. cls,
					mainClass = cls,
					projectName = vim.fn.fnamemodify(root, ":t"),
					cwd = root,
				})
			end)
		end,
	})
end

function M.setup_code_actions()
	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("JavaCodeActions", { clear = true }),
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if not client or client.name ~= "jdtls" then return end
			vim.keymap.set("n", "<leader>rm", M.run_current_main, { buffer = args.buf, desc = "Run main" })
			vim.keymap.set("n", "<leader>dm", M.debug_java_class, { buffer = args.buf, desc = "Debug class" })
		end,
	})
end

return M
