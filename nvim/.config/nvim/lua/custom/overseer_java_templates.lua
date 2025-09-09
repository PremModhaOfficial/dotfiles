local overseer = require("overseer")

-- Template for running Java with Maven
overseer.register_template({
	name = "java_run_maven",
	description = "Run Java main class using Maven",
	builder = function(params)
		local main_class = params.main_class or vim.fn.input("Enter main class (e.g., com.example.Main): ")
		local runtime_flags = params.runtime_flags or vim.fn.input("Enter runtime flags (optional): ")
		local project_root = vim.fn.getcwd() -- Or use your find_project_root function

		local cmd = { "mvn", "-X", "-q", "compile", "exec:java", "-Dexec.mainClass=" .. main_class }
		if runtime_flags ~= "" then
			table.insert(cmd, "-Dexec.args=" .. runtime_flags)
		end

		return {
			cmd = cmd,
			cwd = project_root,
			components = {
				"default",
				{
					"on_output_parse",
					parser = {
						diagnostics = {
							{ "extract", "^(.*):(\\d+): (.*)$", "filename", "lnum", "text" },
						},
					},
				},
				"on_result_diagnostics",
			},
		}
	end,
	params = {
		main_class = {
			type = "string",
			name = "Main Class",
			desc = "Fully qualified class name (e.g., com.example.Main)",
		},
		runtime_flags = {
			type = "string",
			name = "Runtime Flags",
			desc = "JVM runtime flags (optional)",
		},
	},
	tags = { "java", "maven" },
	priority = 60,
})

-- Template for running Java with Gradle
overseer.register_template({
	name = "java_run_gradle",
	description = "Run Java main class using Gradle",
	builder = function(params)
		local main_class = params.main_class or vim.fn.input("Enter main class (e.g., com.example.Main): ")
		local runtime_flags = params.runtime_flags or vim.fn.input("Enter runtime flags (optional): ")
		local project_root = vim.fn.getcwd()

		local cmd = { "gradle", "run", "--console=plain", "-PmainClass=" .. main_class }
		if runtime_flags ~= "" then
			table.insert(cmd, "-Dexec.args=" .. runtime_flags)
		end

		return {
			cmd = cmd,
			cwd = project_root,
			components = {
				"default",
				{
					"on_output_parse",
					parser = {
						diagnostics = {
							{ "extract", "^(.*):(\\d+): (.*)$", "filename", "lnum", "text" },
						},
					},
				},
				"on_result_diagnostics",
			},
		}
	end,
	params = {
		main_class = {
			type = "string",
			name = "Main Class",
			desc = "Fully qualified class name (e.g., com.example.Main)",
		},
		runtime_flags = {
			type = "string",
			name = "Runtime Flags",
			desc = "JVM runtime flags (optional)",
		},
	},
	tags = { "java", "gradle" },
	priority = 60,
})

-- Template for auto-detecting build system and running Java
overseer.register_template({
	name = "java_run_auto",
	description = "Auto-detect build system and run Java main class",
	builder = function(params)
		local main_class = params.main_class or vim.fn.input("Enter main class (e.g., com.example.Main): ")
		local runtime_flags = params.runtime_flags or vim.fn.input("Enter runtime flags (optional): ")
		local project_root = vim.fn.getcwd()

		local pom_exists = vim.fn.filereadable(project_root .. "/pom.xml") == 1
		local gradle_exists = vim.fn.filereadable(project_root .. "/build.gradle") == 1
		local gradle_kts_exists = vim.fn.filereadable(project_root .. "/build.gradle.kts") == 1

		local cmd
		if pom_exists then
			cmd = { "mvn", "-X", "-q", "compile", "exec:java", "-Dexec.mainClass=" .. main_class }
			if runtime_flags ~= "" then
				table.insert(cmd, "-Dexec.args=" .. runtime_flags)
			end
		elseif gradle_exists or gradle_kts_exists then
			cmd = { "gradle", "run", "--console=plain", "-PmainClass=" .. main_class }
			if runtime_flags ~= "" then
				table.insert(cmd, "-Dexec.args=" .. runtime_flags)
			end
		else
			error("No Maven or Gradle build file found in project root")
		end

		return {
			cmd = cmd,
			cwd = project_root,
			components = {
				"default",
				{
					"on_output_parse",
					parser = {
						diagnostics = {
							{ "extract", "^(.*):(\\d+): (.*)$", "filename", "lnum", "text" },
						},
					},
				},
				"on_result_diagnostics",
			},
		}
	end,
	params = {
		main_class = {
			type = "string",
			name = "Main Class",
			desc = "Fully qualified class name (e.g., com.example.Main)",
		},
		runtime_flags = {
			type = "string",
			name = "Runtime Flags",
			desc = "JVM runtime flags (optional)",
		},
	},
	tags = { "java", "auto" },
	priority = 70,
})

-- Template for running Java with custom command
overseer.register_template({
	name = "java_run_custom",
	description = "Run custom Java command",
	builder = function(params)
		local cmd_str = params.cmd or vim.fn.input("Enter Java command: ")
		local project_root = vim.fn.getcwd()

		return {
			cmd = vim.fn.split(cmd_str, " "),
			cwd = project_root,
			components = {
				"default",
				{
					"on_output_parse",
					parser = {
						diagnostics = {
							{ "extract", "^(.*):(\\d+): (.*)$", "filename", "lnum", "text" },
						},
					},
				},
				"on_result_diagnostics",
			},
		}
	end,
	params = {
		cmd = {
			type = "string",
			name = "Command",
			desc = "Full Java run command",
		},
	},
	tags = { "java", "custom" },
	priority = 50,
})

-- Template for running Vert.x verticles with Maven
overseer.register_template({
	name = "vertx_run_maven",
	description = "Run Vert.x verticle using Maven",
	builder = function(params)
		local verticle_class = params.verticle_class or vim.fn.input("Enter verticle class: ")
		local cluster = params.cluster or false
		local ha = params.ha or false
		local redeploy = params.redeploy or false
		local instances = params.instances or 1
		local project_root = vim.fn.getcwd()

		local launcher_args = "run " .. verticle_class
		if cluster then
			launcher_args = launcher_args .. " --cluster"
		end
		if ha then
			launcher_args = launcher_args .. " --ha"
		end
		if redeploy then
			launcher_args = launcher_args .. " --redeploy=**/*.java --on-redeploy=mvn compile"
		end
		if instances > 1 then
			launcher_args = launcher_args .. " --instances=" .. instances
		end

		local cmd = {
			"mvn",
			"compile",
			"exec:java",
			"-Dexec.mainClass=io.vertx.core.Launcher",
			"-Dexec.args=" .. launcher_args,
		}

		return {
			cmd = cmd,
			cwd = project_root,
			components = {
				"default",
				{
					"on_output_parse",
					parser = {
						diagnostics = {
							{ "extract", "^(.*):(\\d+): (.*)$", "filename", "lnum", "text" },
						},
					},
				},
				"on_result_diagnostics",
				"on_complete_notify",
			},
		}
	end,
	params = {
		verticle_class = {
			type = "string",
			name = "Verticle Class",
			desc = "Fully qualified verticle class name",
		},
		cluster = {
			type = "boolean",
			name = "Cluster Mode",
			desc = "Run in cluster mode",
			default = false,
		},
		ha = {
			type = "boolean",
			name = "High Availability",
			desc = "Enable HA mode",
			default = false,
		},
		redeploy = {
			type = "boolean",
			name = "Hot Reload",
			desc = "Enable hot reload for development",
			default = false,
		},
		instances = {
			type = "number",
			name = "Instances",
			desc = "Number of verticle instances",
			default = 1,
		},
	},
	tags = { "vertx", "maven" },
	priority = 80,
})

-- Template for running Vert.x verticles with Gradle
overseer.register_template({
	name = "vertx_run_gradle",
	description = "Run Vert.x verticle using Gradle",
	builder = function(params)
		local verticle_class = params.verticle_class or vim.fn.input("Enter verticle class: ")
		local cluster = params.cluster or false
		local ha = params.ha or false
		local instances = params.instances or 1
		local project_root = vim.fn.getcwd()

		local launcher_args = "run " .. verticle_class
		if cluster then
			launcher_args = launcher_args .. " --cluster"
		end
		if ha then
			launcher_args = launcher_args .. " --ha"
		end
		if instances > 1 then
			launcher_args = launcher_args .. " --instances=" .. instances
		end

		local cmd = {
			"gradle",
			"run",
			"--console=plain",
			"-PmainClass=io.vertx.core.Launcher",
			"-Pargs=" .. launcher_args,
		}

		return {
			cmd = cmd,
			cwd = project_root,
			components = {
				"default",
				{
					"on_output_parse",
					parser = {
						diagnostics = {
							{ "extract", "^(.*):(\\d+): (.*)$", "filename", "lnum", "text" },
						},
					},
				},
				"on_result_diagnostics",
				"on_complete_notify",
			},
		}
	end,
	params = {
		verticle_class = {
			type = "string",
			name = "Verticle Class",
			desc = "Fully qualified verticle class name",
		},
		cluster = {
			type = "boolean",
			name = "Cluster Mode",
			desc = "Run in cluster mode",
			default = false,
		},
		ha = {
			type = "boolean",
			name = "High Availability",
			desc = "Enable HA mode",
			default = false,
		},
		instances = {
			type = "number",
			name = "Instances",
			desc = "Number of verticle instances",
			default = 1,
		},
	},
	tags = { "vertx", "gradle" },
	priority = 80,
})

-- Template for building Vert.x fat JAR
overseer.register_template({
	name = "vertx_build_fatjar",
	description = "Build Vert.x fat JAR",
	builder = function(params)
		local project_root = vim.fn.getcwd()
		local pom_exists = vim.fn.filereadable(project_root .. "/pom.xml") == 1
		local gradle_exists = vim.fn.filereadable(project_root .. "/build.gradle") == 1
			or vim.fn.filereadable(project_root .. "/build.gradle.kts") == 1

		local cmd
		if pom_exists then
			cmd = { "mvn", "clean", "package" }
		elseif gradle_exists then
			cmd = { "gradle", "shadowJar" }
		else
			error("No Maven or Gradle build file found")
		end

		return {
			cmd = cmd,
			cwd = project_root,
			components = {
				"default",
				"on_output_parse",
				"on_result_diagnostics",
				"on_complete_notify",
			},
		}
	end,
	tags = { "vertx", "build" },
	priority = 75,
})

-- Template for running Vert.x tests
overseer.register_template({
	name = "vertx_test",
	description = "Run Vert.x tests",
	builder = function(params)
		local test_class = params.test_class or ""
		local project_root = vim.fn.getcwd()
		local pom_exists = vim.fn.filereadable(project_root .. "/pom.xml") == 1

		local cmd
		if pom_exists then
			if test_class ~= "" then
				cmd = { "mvn", "test", "-Dtest=" .. test_class }
			else
				cmd = { "mvn", "test" }
			end
		else
			if test_class ~= "" then
				cmd = { "gradle", "test", "--tests", test_class }
			else
				cmd = { "gradle", "test" }
			end
		end

		return {
			cmd = cmd,
			cwd = project_root,
			components = {
				"default",
				"on_output_parse",
				"on_result_diagnostics",
				"on_complete_notify",
			},
		}
	end,
	params = {
		test_class = {
			type = "string",
			name = "Test Class",
			desc = "Specific test class to run (optional)",
			optional = true,
		},
	},
	tags = { "vertx", "test" },
	priority = 70,
})
