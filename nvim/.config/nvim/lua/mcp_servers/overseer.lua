---@class NativeServer
local overseer = {}

-- Only load overseer modules after ensuring the plugin is loaded
local api = nil
local core = nil

local function ensure_overseer()
	if not api then
		-- Check if overseer is available
		local ok = pcall(require, "overseer")
		if not ok then
			error("Overseer.nvim is not installed or not loaded")
		end
		core = require("overseer")
		api = core.task_list -- This is the main API module in overseer
	end
	return api, core
end

overseer.name = "overseer"
overseer.displayName = "Overseer MCP Server"
overseer.capabilities = {
	tools = {
		{
			name = "list_tasks",
			description = "List all tasks with their current status",
			handler = function(req, res)
				local api = ensure_overseer()
				local tasks = api.list_tasks()
				local task_list = {}
				for _, task in ipairs(tasks) do
					table.insert(task_list, {
						name = task.name,
						id = task.id,
						status = task.status,
						result = task.result,
						output = task:get_raw_lines(),
					})
				end
				return res:text(vim.inspect(task_list)):send()
			end,
		},
		{
			name = "run_task",
			description = "Run a task with given name and optional parameters",
			inputSchema = {
				type = "object",
				properties = {
					task_name = {
						type = "string",
						description = "Name of the task template to run",
					},
					params = {
						type = "object",
						description = "Optional parameters for the task",
						additionalProperties = true,
					},
				},
				required = { "task_name" },
			},
			handler = function(req, res)
				local _, core = ensure_overseer()
				-- Find the task template
				local templates = core.list_templates()
				local task_template = nil
				for _, template in ipairs(templates) do
					if template.name == req.params.task_name then
						task_template = template
						break
					end
				end

				if not task_template then
					return res:error("Task template not found: " .. req.params.task_name)
				end

				-- Create and run the task
				local task = core.new_task(task_template, req.params.params)
				task:start()

				return res:text(string.format("Started task '%s' with ID %s", task.name, task.id)):send()
			end,
		},
		{
			name = "stop_task",
			description = "Stop a running task by ID",
			inputSchema = {
				type = "object",
				properties = {
					task_id = {
						type = "string",
						description = "ID of the task to stop",
					},
				},
				required = { "task_id" },
			},
			handler = function(req, res)
				local api = ensure_overseer()
				local tasks = api.list_tasks()
				local task_id = tonumber(req.params.task_id)
				local task = nil

				for _, t in ipairs(tasks) do
					if t.id == task_id then
						task = t
						break
					end
				end

				if not task then
					return res:error("Task not found: " .. req.params.task_id)
				end

				task:stop()
				return res:text(string.format("Stopped task '%s'", task.name)):send()
			end,
		},
		{
			name = "get_task_output",
			description = "Get the output of a task by ID",
			inputSchema = {
				type = "object",
				properties = {
					task_id = {
						type = "string",
						description = "ID of the task",
					},
				},
				required = { "task_id" },
			},
			handler = function(req, res)
				local api = ensure_overseer()
				local tasks = api.list_tasks()
				local task_id = tonumber(req.params.task_id)
				local task = nil

				for _, t in ipairs(tasks) do
					if t.id == task_id then
						task = t
						break
					end
				end

				if not task then
					return res:error("Task not found: " .. req.params.task_id)
				end

				local output = task:get_raw_lines()
				return res:text(table.concat(output, "\n")):send()
			end,
		},
		{
			name = "list_task_templates",
			description = "List all available task templates",
			handler = function(req, res)
				local _, core = ensure_overseer()
				local templates = core.list_templates()
				-- Convert templates to a simpler format
				local template_list = {}
				for _, template in ipairs(templates) do
					table.insert(template_list, {
						name = template.name,
						desc = template.desc,
						params = template.params,
					})
				end
				return res:text(vim.inspect(template_list)):send()
			end,
		},
	},
	resources = {
		{
			name = "task_list",
			uri = "overseer://tasks",
			description = "List of all tasks with their status",
			handler = function(req, res)
				local api = ensure_overseer()
				local tasks = api.list_tasks()
				local task_list = {}
				for _, task in ipairs(tasks) do
					table.insert(task_list, {
						name = task.name,
						id = task.id,
						status = task.status,
						result = task.result,
					})
				end
				return res:text(vim.json.encode(task_list), "application/json"):send()
			end,
		},
	},
	resourceTemplates = {
		{
			name = "task",
			uriTemplate = "overseer://tasks/{id}",
			description = "Get details of a specific task by ID",
			handler = function(req, res)
				local api = ensure_overseer()
				local tasks = api.list_tasks()
				local task_id = tonumber(req.params.id)
				local task = nil

				for _, t in ipairs(tasks) do
					if t.id == task_id then
						task = t
						break
					end
				end

				if not task then
					return res:error("Task not found: " .. req.params.id)
				end

				local task_info = {
					name = task.name,
					id = task.id,
					status = task.status,
					result = task.result,
					output = task:get_raw_lines(),
					cwd = task.cwd,
				}
				return res:text(vim.json.encode(task_info), "application/json"):send()
			end,
		},
		{
			name = "template",
			uriTemplate = "overseer://templates/{name}",
			description = "Get details of a specific task template",
			handler = function(req, res)
				local _, core = ensure_overseer()
				local templates = core.list_templates()
				for _, template in ipairs(templates) do
					if template.name == req.params.name then
						local template_info = {
							name = template.name,
							desc = template.desc,
							params = template.params,
						}
						return res:text(vim.json.encode(template_info), "application/json"):send()
					end
				end
				return res:error("Template not found: " .. req.params.name)
			end,
		},
	},
}

return overseer
