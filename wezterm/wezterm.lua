-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}
local mux = wezterm.mux

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- config.color_scheme = 'AdventureTime'
-- config.color_scheme = 'Dracula+'
config.color_scheme = "Tango (terminal.sexy)"
config.colors = {
	-- Make the selection text color fully transparent.
	-- When fully transparent, the current text color will be used.
	selection_fg = "none",
	-- Set the selection background color with alpha.
	-- When selection_bg is transparent, it will be alpha blended over
	-- the current cell background color, rather than replace it
	selection_bg = "rgba(50% 50% 50% 50%)",
}

config.font_size = 12
config.font = wezterm.font_with_fallback({
	"Mononoki Nerd Font",
	"FantasqueSansMono Nerd Font",
})

config.window_background_opacity = 0.9
config.hide_tab_bar_if_only_one_tab = true

config.default_cursor_style = "BlinkingBlock"
config.window_decorations = "RESIZE"
config.window_padding = {
	left = 4,
	right = 0,
	top = 4,
	bottom = 0,
}

config.mouse_bindings = {
	{
		event = { Down = { streak = 3, button = "Left" } },
		action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
		mods = "NONE",
	},
}

config.keys = {
	{ key = "/", mods = "CTRL | ALT", action = wezterm.action.ShowLauncher },
}

config.launch_menu = {
	{
		label = "Bash",
		args = { "bash", "-l" },
	},

	{
		label = "Only fish",
		args = { "fish", "-l" },
	},
}

wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

-- Spawn a fish shell in login mode
config.default_prog = { "/usr/bin/tmux", "new", "-A", "-s", "mux0", "fish" }

-- and finally, return the configuration to wezterm
return config
