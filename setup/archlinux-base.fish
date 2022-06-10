#! /usr/bin/fish

echo 'Installing Fisher (Fish Package Manager)'
if type -q yay
    yay -S --needed fisher
else
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/HEAD/functions/fisher.fish | source && fisher install jorgebucaran/fisher
end

if type -q fisher
    echo "Fisher installed, linking config files"
    rm ~/.config/fish/fish_plugins
    ln -s ~/.dotfiles/fish/fisher/fish_plugins ~/.config/fish/fish_plugins
else
    echo ">>> Fisher install failed <<<<"
end