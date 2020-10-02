#! /usr/bin/bash

# change mkinit EARLY KMS
sudo sed -i 's/nvidia nvidia_modeset nvidia_drm nvidia_uvm/nouveau/' /etc/mkinitcpio.conf
# install
yay -R --noconfirm nvidia nvidia-utils nvidia-settings

# GRUB
# after: GRUB_CMDLINE_LINUX="i915.modeset=1 rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1"
# before: GRUB_CMDLINE_LINUX="i915.modeset=1 rd.driver.blacklist=nvidia,nvidia_drm,nvidia_modeset modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset nouveau.modeset=1"

sudo sed -i 's/rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1/rd.driver.blacklist=nvidia,nvidia_drm,nvidia_modeset modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset nouveau.modeset=1/' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# modprobe
sudo rm /etc/modprobe.d/nouveau.conf
cat << EOF
blacklist nvidia_drm
blacklist nvidia_uvm
blacklist nvidia
EOF > /etc/modprobe.d/nvidia.conf

# X11
sudo rm /etc/X11/xorg.conf.d/20-nvidia*

# Wayland
