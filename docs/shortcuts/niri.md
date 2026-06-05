# niri shortcuts

Key bindings for the [niri](https://github.com/YaLTeR/niri) scrollable-tiling
Wayland compositor.

Generated from [`niri/dot-config/niri/binds.kdl`](https://github.com/rdlu/dotfiles/blob/main/niri/dot-config/niri/binds.kdl)
by `tools/gen-docs.py` — run `just docs-update` to refresh. For the mouse-warp
binds see also the [wl-kbptr guide](../wl-kbptr.md).

<!-- gen:niri-binds -->
`Mod` is the **Super** key. Press `Mod+Shift+/` for the built-in hotkey overlay.

### Apps & launchers

| Keys | Action |
| --- | --- |
| `Mod+Shift+Slash` | Dotfiles Docs (local) |
| `Mod+T` | Open a Terminal: ghostty |
| `Mod+D` | Run an Application: fuzzel |
| `Mod+Slash` | Run an Application: fuzzel |
| `Super+Alt+L` | Lock the Screen: swaylock |
| `Mod+Escape` | Menu Power |
| `Mod+Shift+Escape` | Menu Just: dotfiles commands |
| `Mod+E` | Run `ghostty -e yazi` |
| `Mod+Period` | Emoji Finder |
| `Mod+V` | Manage clipboard |
| `Mod+B` | Hide Waybar |

### Mouse warp (wl-kbptr)

| Keys | Action |
| --- | --- |
| `Mod+G` | Mouse Warp: wl-kbptr |
| `Mod+Shift+G` | Mouse Warp + Click |
| `Mod+Alt+G` | Mouse Warp: coarse (tile only) |
| `Mod+Ctrl+G` | Mouse Warp: tile + split |
| `Mod+A` | Mouse Warp: other monitor |
| `Mod+Shift+A` | Mouse Warp + Click: other monitor |
| `Mod+Alt+A` | Mouse Warp: coarse, other monitor |
| `Mod+Ctrl+A` | Mouse Warp: tile + split, other monitor |
| `Mod+N` | Mouse Warp: bisect then tile |
| `Mod+Shift+N` | Mouse Warp + Click: bisect then tile |
| `Mod+M` | Mouse Warp: bisect then tile, other monitor |
| `Mod+Shift+M` | Mouse Warp + Click: bisect then tile, other monitor |
| `Mod+X` | Mouse Warp: detect + click (X-ray) |
| `Mod+Shift+X` | Mouse Warp: detect only |

### Media, volume & brightness

| Keys | Action |
| --- | --- |
| `XF86AudioRaiseVolume` | Run `swayosd-client --output-volume raise` *(works on lock screen)* |
| `XF86AudioLowerVolume` | Run `swayosd-client --output-volume lower` *(works on lock screen)* |
| `XF86AudioMute` | Run `swayosd-client --output-volume mute-toggle` *(works on lock screen)* |
| `XF86AudioMicMute` | Run `swayosd-client --input-volume mute-toggle` *(works on lock screen)* |
| `XF86MonBrightnessUp` | Run `swayosd-client --brightness +10` *(works on lock screen)* |
| `XF86MonBrightnessDown` | Run `swayosd-client --brightness -10` *(works on lock screen)* |
| `XF86AudioNext` | Run `playerctl next` *(works on lock screen)* |
| `XF86AudioPause` | Run `playerctl play-pause` *(works on lock screen)* |
| `XF86AudioPlay` | Run `playerctl play-pause` *(works on lock screen)* |
| `XF86AudioPrev` | Run `playerctl previous` *(works on lock screen)* |

### Focus

| Keys | Action |
| --- | --- |
| `Mod+Left` | Focus column left |
| `Mod+Down` | Focus window down |
| `Mod+Up` | Focus window up |
| `Mod+Right` | Focus column right |
| `Mod+H` | Focus column left |
| `Mod+L` | Focus column right |
| `Mod+Home` | Focus column first |
| `Mod+End` | Focus column last |
| `Mod+WheelScrollRight` | Focus column right |
| `Mod+WheelScrollLeft` | Focus column left |
| `Mod+Shift+WheelScrollDown` | Focus column right |
| `Mod+Shift+WheelScrollUp` | Focus column left |

### Moving windows & columns

| Keys | Action |
| --- | --- |
| `Mod+Ctrl+Left` | Move column left |
| `Mod+Ctrl+Down` | Move window down |
| `Mod+Ctrl+Up` | Move window up |
| `Mod+Ctrl+Right` | Move column right |
| `Mod+Ctrl+H` | Move column left |
| `Mod+Ctrl+L` | Move column right |
| `Mod+Ctrl+Home` | Move column to first |
| `Mod+Ctrl+End` | Move column to last |
| `Mod+Ctrl+WheelScrollRight` | Move column right |
| `Mod+Ctrl+WheelScrollLeft` | Move column left |
| `Mod+Ctrl+Shift+WheelScrollDown` | Move column right |
| `Mod+Ctrl+Shift+WheelScrollUp` | Move column left |
| `Mod+BracketLeft` | Consume or expel window left |
| `Mod+BracketRight` | Consume or expel window right |
| `Mod+Comma` | Consume window into column |
| `Mod+Shift+Comma` | Expel window from column |

### Workspaces

| Keys | Action |
| --- | --- |
| `Mod+J` | Focus window or workspace down |
| `Mod+K` | Focus window or workspace up |
| `Mod+Ctrl+J` | Move window down or to workspace down |
| `Mod+Ctrl+K` | Move window up or to workspace up |
| `Mod+Shift+Ctrl+J` | Move Workspace to Monitor Left |
| `Mod+Shift+Ctrl+K` | Move Workspace to Monitor Right |
| `Mod+Page_Down` | Focus workspace down |
| `Mod+Page_Up` | Focus workspace up |
| `Mod+U` | Focus workspace down |
| `Mod+I` | Focus workspace up |
| `Mod+Ctrl+Page_Down` | Move column to workspace down |
| `Mod+Ctrl+Page_Up` | Move column to workspace up |
| `Mod+Ctrl+U` | Move column to workspace down |
| `Mod+Ctrl+I` | Move column to workspace up |
| `Mod+Shift+Page_Down` | Move workspace down |
| `Mod+Shift+Page_Up` | Move workspace up |
| `Mod+Shift+U` | Move workspace down |
| `Mod+Shift+I` | Move workspace up |
| `Mod+WheelScrollDown` | Focus workspace down *(cooldown 150ms)* |
| `Mod+WheelScrollUp` | Focus workspace up *(cooldown 150ms)* |
| `Mod+Ctrl+WheelScrollDown` | Move column to workspace down *(cooldown 150ms)* |
| `Mod+Ctrl+WheelScrollUp` | Move column to workspace up *(cooldown 150ms)* |
| `Mod+1` | Focus workspace 1 |
| `Mod+2` | Focus workspace 2 |
| `Mod+3` | Focus workspace 3 |
| `Mod+4` | Focus workspace 4 |
| `Mod+5` | Focus workspace 5 |
| `Mod+6` | Focus workspace 6 |
| `Mod+7` | Focus workspace 7 |
| `Mod+8` | Focus workspace 8 |
| `Mod+9` | Focus workspace 9 |
| `Mod+Ctrl+1` | Move column to workspace 1 |
| `Mod+Ctrl+2` | Move column to workspace 2 |
| `Mod+Ctrl+3` | Move column to workspace 3 |
| `Mod+Ctrl+4` | Move column to workspace 4 |
| `Mod+Ctrl+5` | Move column to workspace 5 |
| `Mod+Ctrl+6` | Move column to workspace 6 |
| `Mod+Ctrl+7` | Move column to workspace 7 |
| `Mod+Ctrl+8` | Move column to workspace 8 |
| `Mod+Ctrl+9` | Move column to workspace 9 |

### Monitors

| Keys | Action |
| --- | --- |
| `Mod+Shift+Left` | Focus monitor left |
| `Mod+Shift+Down` | Focus monitor down |
| `Mod+Shift+Up` | Focus monitor up |
| `Mod+Shift+Right` | Focus monitor right |
| `Mod+Shift+H` | Focus monitor left |
| `Mod+Shift+J` | Focus monitor down |
| `Mod+Shift+K` | Focus monitor up |
| `Mod+Shift+L` | Focus monitor right |
| `Mod+Shift+Ctrl+Left` | Move column to monitor left |
| `Mod+Shift+Ctrl+Down` | Move column to monitor down |
| `Mod+Shift+Ctrl+Up` | Move column to monitor up |
| `Mod+Shift+Ctrl+Right` | Move column to monitor right |
| `Mod+Shift+Ctrl+H` | Move column to monitor left |
| `Mod+Shift+Ctrl+L` | Move column to monitor right |

### Layout & sizing

| Keys | Action |
| --- | --- |
| `Mod+R` | Switch preset column width |
| `Mod+Shift+R` | Switch preset window height |
| `Mod+Ctrl+R` | Reset window height |
| `Mod+Z` | Maximize column |
| `Mod+Shift+Z` | Fullscreen window |
| `Mod+Ctrl+Z` | Expand column to available width |
| `Mod+C` | Center column |
| `Mod+Ctrl+C` | Center visible columns |
| `Mod+Minus` | Set column width -10% |
| `Mod+Equal` | Set column width +10% |
| `Mod+Shift+Minus` | Set window height -10% |
| `Mod+Shift+Equal` | Set window height +10% |
| `Mod+F` | Toggle window floating |
| `Mod+Shift+F` | Switch focus between floating and tiling |
| `Mod+W` | Toggle column tabbed display |
| `Mod+Space` | Switch layout next |
| `Mod+Shift+Space` | Switch layout prev |

### Screenshots & screencasting

| Keys | Action |
| --- | --- |
| `Print` | Screenshot |
| `Ctrl+Print` | Screenshot screen |
| `Alt+Print` | Screenshot window |
| `Mod+P` | Set dynamic cast window |
| `Mod+Ctrl+P` | Set dynamic cast monitor |
| `Mod+Alt+P` | Clear dynamic cast target |

### Session & misc

| Keys | Action |
| --- | --- |
| `Mod+O` | Toggle overview *(no key-repeat)* |
| `Mod+Q` | Close window |
| `Mod+Alt+Escape` | Toggle keyboard shortcuts inhibit *(never inhibited)* |
| `Mod+Shift+E` | Quit |
| `Ctrl+Alt+Delete` | Quit |
| `Mod+Shift+P` | Power off monitors |
<!-- /gen:niri-binds -->
