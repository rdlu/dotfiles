#! /usr/bin/bash
echo 'Installing Fish Shell and TMUX'
sudo pacman -S --needed tmux fish

echo 'Installing TPM (TMUX Package Manager)'
cd
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf

echo 'Linking Fish Shell Files'
mkdir -pv ~/.config/fish
ln -s ~/.dotfiles/fish/config.fish ~/.config/fish/config.fish

echo 'Installing Fisher (Fish Package Manager)'
if type -q yay
    yay -S --needed fisher
else
    curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
end
rm ~/.config/fish/fish_plugins
ln -s ~/.dotfiles/fish/fisher/fish_plugins ~/.config/fish/fish_plugins