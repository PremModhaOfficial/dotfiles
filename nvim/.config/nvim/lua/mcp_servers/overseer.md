# Overseer MCP Server

## Overview
The Overseer MCP Server provides a comprehensive interface to interact with the Overseer.nvim plugin through the Model Context Protocol (MCP). It enables LLMs to manage tasks, templates, and task bundles.

## Tools

### 1. List Tasks (`list_tasks`)
- Lists all tasks with their current status, ID and output
- No parameters required
- Returns array of task objects with status and output

### 2. Run Task (`run_task`)
- Runs a task template with optional parameters
- Parameters:
  - `task_name`: Name of the task template to run
  - `params`: Optional object with task parameters

### 3. Stop Task (`stop_task`)
- Stops a running task by its ID
- Parameters:
  - `task_id`: ID of the task to stop

### 4. Get Task Output (`get_task_output`)
- Gets the complete output of a task by ID
- Parameters:
  - `task_id`: ID of the task

### 5. Load Template Bundle (`load_template_bundle`)
- Loads saved task templates from a bundle
- Parameters:
  - `bundle_name`: Name of the bundle to load

### 6. Save Template Bundle (`save_template_bundle`)
- Saves current task templates to a bundle
- Parameters:
  - `bundle_name`: Name for the new bundle

### 7. List Task Templates (`list_task_templates`)
- Lists all available task templates
- No parameters required

## Resources

### Tasks List (`overseer://tasks`)
- Lists all tasks with their status and metadata
- Returns JSON array of task objects

### Task Details (`overseer://tasks/{id}`)
- Gets details and output of a specific task
- URI Parameters:
  - `id`: Task ID
- Returns JSON object with task details including:
  - name
  - id
  - status
  - output
  - runtime
  - environment
  - working directory

### Template Details (`overseer://templates/{name}`)
- Gets details of a specific task template
- URI Parameters:
  - `name`: Template name
- Returns JSON object with template configuration

## Examples

### Running a Task
```lua
mcphub.call_tool('overseer', 'run_task', {
    task_name = 'cargo build',
    params = {
        release = true
    }
})
```

### Getting Task Output
```lua
mcphub.call_tool('overseer', 'get_task_output', {
    task_id = '123'
})
```

### Getting Task Details via Resource
```lua
mcphub.get_resource('overseer', 'overseer://tasks/123')
```

## Implementation Details

### Error Handling
- All tools return proper error responses for:
  - Invalid task IDs
  - Non-existent templates
  - Failed task operations

### Data Types
- Task IDs are numbers internally but handled as strings in the API
- JSON responses use proper MIME types
- Task output is provided as raw text or structured JSON

### Resource Templates
- Use URI templates for dynamic resource paths
- Support both raw and JSON responses
- Include proper error handling
