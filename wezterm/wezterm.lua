-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- config.color_scheme = 'AdventureTime'
-- config.color_scheme = 'Dracula+'
config.color_scheme = 'Tango (terminal.sexy)'
config.colors = {
  -- Make the selection text color fully transparent.
  -- When fully transparent, the current text color will be used.
  selection_fg = 'none',
  -- Set the selection background color with alpha.
  -- When selection_bg is transparent, it will be alpha blended over
  -- the current cell background color, rather than replace it
  selection_bg = 'rgba(50% 50% 50% 50%)',
}
config.window_background_opacity = 0.8
config.hide_tab_bar_if_only_one_tab = true


-- and finally, return the configuration to wezterm
return config
