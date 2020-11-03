#! /usr/bin/fish

# Linking nvidia control scripts
for script in (basename -a -s .fish ~/.dotfiles/nvidia-x11/*.fish)
    echo Linked $script to local bin
    ln -s  ~/.dotfiles/nvidia-x11/$script.fish ~/.local/bin/$script
end