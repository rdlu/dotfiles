#! /usr/bin/bash
echo 'Installing Fish Shell and TMUX'
sudo pacman -S --needed tmux fish starship

echo 'Installing TPM (TMUX Package Manager)'
cd
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf

echo 'Linking Fish Shell Files'
mkdir -pv ~/.config/fish
ln -s ~/.dotfiles/fish/config.fish ~/.config/fish/config.fish

echo 'Changing default shell'
chsh -s /usr/bin/fish

cp .bashrc .bashrc.bak
rm .bashrc
ln -s ~/.dotfiles/bashrc ~/.bashrc
source .bashrc

fish setup/archlinux-base.fish
