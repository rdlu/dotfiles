#! /usr/bin/bash

# change mkinit EARLY KMS
sudo sed -i 's/nouveau/nvidia nvidia_modeset nvidia_drm nvidia_uvm/' /etc/mkinitcpio.conf
# install
yay -S --needed --no-confirm nvidia nvidia-utils nvidia-settings

# GRUB
# after: GRUB_CMDLINE_LINUX="i915.modeset=1 rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1"
# before: GRUB_CMDLINE_LINUX="i915.modeset=1 rd.driver.blacklist=nvidia,nvidia_drm,nvidia_modeset modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset nouveau.modeset=1"

sudo sed -i 's/rd.driver.blacklist=nvidia,nvidia_drm,nvidia_modeset modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset nouveau.modeset=1/rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1/' /etc/default/grub

# modprobe
sudo rm /etc/modprobe.d/nvidia.conf
cat << EOF
blacklist nouveau
options nouveau modeset=0
EOF > /etc/modprobe.d/nouveau.conf

# X11
sudo rm /etc/X11/xorg.conf.d/20-nvidia*
sudo cp ~/.dotfiles/nvidia-x11/20-nvidia-prime.conf /etc/X11/xorg.conf.d/20-nvidia-prime.conf
# Wayland