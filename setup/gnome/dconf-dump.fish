#! /usr/bin/fish
# Groups to dump
set groups (echo "org.gnome.desktop.input-sources
org.gnome.desktop.wm.keybindings
org.gnome.desktop.peripherals.touchpad
org.gnome.shell.keybindings
org.gnome.settings-daemon.plugins.media-keys
org.gnome.calculator
org.gnome.shell.app-switcher
org.gnome.shell.extensions.pop-shell
com.github.amezin.ddterm
org.gnome.shell.extensions.space-bar")

echo "Dumping dconf settings to gnome-conf.ini"
set datetime (date +%Y-%m-%d-%H-%M-%S)
echo "# Dump from $datetime" > gnome-conf.ini
for group in $groups
    echo $group
    dconf dump / | sed -n "/\[$group/,/^\$/p" >> gnome-conf.ini
end
echo "Done"
