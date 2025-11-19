-- Dummy module to prevent CodeCompanion blink integration errors
-- Provides minimal blink.cmp provider interface
local M = {}

-- Blink provider interface
function M.new()
  return {
    -- Minimal provider methods
    get_completions = function() return {} end,
    resolve = function() return {} end,
    execute = function() return {} end,
  }
end

return M