#! /usr/bin/bash
sudo dnf copr enable atim/lazygit -y
sudo dnf install -y ripgrep lazygit neovim fd-find yarn python3-neovim python3-pip gcc-c++ git-delta fzf imhex zoxide
sudo yum groupinstall 'Development Tools'

sudo dnf install -y rubygem-rails
sudo dnf install -y yubikey-manager-qt


sudo dnf copr enable atim/bottom -y
sudo dnf install bottom
