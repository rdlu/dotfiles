#! /usr/bin/bash

echo "Downloading my dotfiles"

git clone https://github.com/rdlu/dotfiles.git ~/.dotfiles
git config --global user.name "Rodrigo Dlugokenski"
git config --global user.email "git@dlu.one"

./setup/terminal-base.sh

echo "Creating dotfiles file links"

echo 'Installing TPM (TMUX Package Manager)'
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf

echo 'Linking Fish Shell Files'
mkdir -pv ~/.config/fish
rm ~/.config/fish/config.fish
ln -s ~/.dotfiles/fish/config.fish ~/.config/fish/config.fish

echo 'Updating startship conf'
ln -s ~/.dotfiles/config/starship.toml ~/.config/starship.toml

echo 'Updating Neovim conf'
ln -s ~/.dotfiles/nvim ~/.config/nvim

echo 'Updating bash_profile...'
if [ -f ~/.bash_profile ]; then
    echo ". ~/.dotfiles/bashrc" >> ~/.bash_profile
    echo "...bash_profile ok"
fi

fish setup/fish-extras.sh