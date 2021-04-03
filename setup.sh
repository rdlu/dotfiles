#! /usr/bin/bash
cd
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf
mkdir -pv ~/.config/fish
ln -s ~/.dotfiles/fish/config.fish ~/.config/fish/config.fish
mkdir -pv ~/.config/chips
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
rm ~/.config/fish/fish_plugins
ln -s ~/.dotfiles/fish/fisher/fish_plugins ~/.config/fish/fish_plugins