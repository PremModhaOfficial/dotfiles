-- Load Overseer Java templates
-- This file loads the custom Java templates for Overseer
-- Add this to your init.lua or require it in your Overseer config

local ok, overseer = pcall(require, "overseer")
if ok then
	require("custom.overseer_java_templates")
	vim.notify("Overseer Java templates loaded", vim.log.levels.INFO)
else
	vim.notify("Overseer not available, skipping Java templates", vim.log.levels.WARN)
end
