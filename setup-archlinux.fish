# /usr/bin/fish
cd
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf

sudo pacman -Sy tmux fpp fzf thefuck