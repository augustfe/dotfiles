-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 76
config.initial_rows = 17

-- or, changing the font size and color scheme.
config.font_size = 18
config.color_scheme = "Rosé Pine Moon (Gogh)"

config.window_background_opacity = 0.85
config.macos_window_background_blur = 20

-- Finally, return the configuration to wezterm:
return config
