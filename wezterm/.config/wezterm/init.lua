local wezterm = require("wezterm")
--
-- disable tabs
local config = wezterm.config_builder()

config.enable_tab_bar = false
config.font = wezterm.font("JetBrainsMono NFM")

config.enable_wayland = false

return config
