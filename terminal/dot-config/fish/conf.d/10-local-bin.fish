# ~/.local/bin on PATH for login shells too, not just interactive ones.
# greetd starts niri through `fish -l` (niri-session), and config.fish exits
# early when non-interactive -- but conf.d still runs. niri-session then
# imports this PATH into the systemd user manager, overriding environment.d,
# so without this, launchers (fuzzel, noctalia, keybinds) never see
# ~/.local/bin and its wrappers (e.g. claude-desktop) are silently bypassed.
if test -d $HOME/.local/bin
    fish_add_path -g $HOME/.local/bin
end
