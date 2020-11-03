#! /usr/bin/fish

# modprobe
sudo rm /etc/modprobe.d/nvidia.conf
echo -n "blacklist nouveau
options nouveau modeset=0
" | sudo tee /etc/modprobe.d/nouveau.conf

# X11
sudo rm /etc/X11/xorg.conf.d/20-nvidia*
sudo cp ~/.dotfiles/nvidia-x11/20-nvidia-prime.conf /etc/X11/xorg.conf.d/20-nvidia-prime.conf
# Wayland
