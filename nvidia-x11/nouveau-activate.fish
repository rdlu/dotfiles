#! /usr/bin/fish

# modprobe
sudo rm /etc/modprobe.d/nouveau.conf
echo -n "blacklist nvidia_drm
blacklist nvidia_uvm
blacklist nvidia
" | sudo tee /etc/modprobe.d/nvidia.conf

# X11
sudo rm /etc/X11/xorg.conf.d/20-nvidia*

# Wayland