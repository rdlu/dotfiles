#! /usr/bin/fish

echo 'Set Fractional Scaling in Wayland'

gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"

echo 'Remove Alt+` as shortcut (used by some terminal apps)'
gsettings get org.gnome.desktop.wm.keybindings switch-group
gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Super>Above_Tab']"

echo 'Set Custom Print Screen (MX Mechanical Mini)'
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['Print', '<Shift><Super>s']"

