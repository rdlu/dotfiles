#! /usr/bin/bash

if hash pacman 2>/dev/null; then
    echo '(PACMAN) Installing Fish Shell and TMUX'
    sudo pacman -S --needed tmux fish starship jq tldr curl
    echo 'Changing default shell'
    chsh -s /usr/bin/fish
fi

if hash dnf 2>/dev/null;then
    echo '(DNF) Installing Fish Shell and TMUX'
    sudo dnf -y copr enable atim/starship
    sudo dnf -y upgrade
    sudo dnf -y install tmux fish starship jq tldr git curl
    echo 'Changing default shell [/usr/bin/fish]'
    sudo lchsh -i $(whoami)
fi

echo "Installing rustup"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y