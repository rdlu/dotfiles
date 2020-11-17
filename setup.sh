#! /usr/bin/bash
cd
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf
mkdir -pv ~/.config/fish
ln -s ~/.dotfiles/fish/config.fish ~/.config/fish/config.fish
mkdir -pv ~/.config/chips
ln -s ~/.dotfiles/fish/chips/plugin.yaml ~/.config/chips/plugin.yaml