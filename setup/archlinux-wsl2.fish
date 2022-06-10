#! /usr/bin/fish

yay -S --needed wget
set -lx windows_destination "/mnt/c/Users/Public/Downloads/wsl2-ssh-pageant.exe"
set -lx linux_destination "$HOME/.ssh/wsl2-ssh-pageant.exe"
wget -O "$windows_destination" "https://github.com/BlackReloaded/wsl2-ssh-pageant/releases/latest/download/wsl2-ssh-pageant.exe"
# Set the executable bit.
chmod +x "$windows_destination"
# Symlink to linux for ease of use later
ln -s $windows_destination $linux_destination
