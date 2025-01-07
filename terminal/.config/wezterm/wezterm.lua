-- Pull in the wezterm API
local wezterm = require("wezterm")

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

config.font_size = 11
-- config.font = wezterm.font_with_fallback({
-- 	-- "CommitMono",
-- 	-- "RecMonoLinear Nerd Font Mono",
-- 	"JetBrainsMono Nerd Font",
-- 	"Mononoki Nerd Font",
-- 	"FantasqueSansMono Nerd Font",
-- 	{
-- 		family = "JetBrains Mono",
-- 		harfbuzz_features = { "calt=0", "clig=0", "liga=0" },
-- 	},
-- })

config.window_background_opacity = 0.8
config.hide_tab_bar_if_only_one_tab = true

config.default_cursor_style = "BlinkingBlock"
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_padding = {
	left = 4,
	right = 0,
	top = 4,
	bottom = 0,
}

config.keys = { {
	key = "/",
	mods = "CTRL | ALT",
	action = wezterm.action.ShowLauncher,
} }

config.launch_menu = {
	{
		label = "ZelliJ plus fish-shell",
		args = { "zellij", "a", "-c", "mux0" },
	},
	{
		label = "TMUX plus fish-shell",
		args = { "/usr/bin/tmux", "new", "-A", "-s", "mux0", "fish" },
	},
	{
		label = "Bash",
		args = { "bash", "-l" },
	},
	{
		label = "Only fish",
		args = { "fish", "-l" },
	},
}

-- wezterm.on("gui-startup", function(cmd)
--	local tab, pane, window = mux.spawn_window(cmd or {})
--	window:gui_window():maximize()
-- end)

-- Spawn a fish shell in login mode
-- config.default_prog = { "zellij", "a", "-c", "mux0" }
config.default_prog = { "/usr/bin/tmux", "new", "-A", "-s", "mux0", "fish" }

config.disable_default_key_bindings = true
config.enable_kitty_keyboard = true
local act = wezterm.action

config.keys = {
	{ key = ")", mods = "CTRL", action = act.ResetFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "n", mods = "CTRL", action = act.SpawnWindow },
	{ key = "Copy", mods = "NONE", action = act.CopyTo("Clipboard") },
	{ key = "Paste", mods = "NONE", action = act.PasteFrom("Clipboard") },
	{ key = "F11", mods = "NONE", action = act.ToggleFullScreen },
	{ key = "c", mods = "SHIFT|CTRL", action = act.CopyTo("Clipboard") },
	{ key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
	{
		key = "u",
		mods = "SHIFT|CTRL",
		action = act.CharSelect({ copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" }),
	},
	{ key = "p", mods = "SHIFT|CTRL", action = act.ActivateCommandPalette },
	{ key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	{
		key = "v",
		mods = "SHIFT|CTRL",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(wezterm.action.SendKey({ key = "v", mods = "CTRL" }), pane)
		end),
	},
	-- { key = "Backspace", mods = "CTRL", action = act.SendKey({ key = "Backspace", mods = "ALT" }) },
}

config.set_environment_variables = {
	-- prepend the path to your utility and include the rest of the PATH
	PATH = wezterm.home_dir .. "/.cargo/bin:" .. wezterm.home_dir .. "/.local/share/mise/shims:" .. os.getenv("PATH"),
}

-- and finally, return the configuration to wezterm
return config
