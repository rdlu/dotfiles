Just X.org X11 server configurations files for NVIDIA proprietary drivers.

Tested on:

Hardware: Dell G5 5590 (2019)
Distro: Manjaro
Kernel at time (5.6 and 5.7)
nvidia driver: 440.x
X11 1.20.8
Gnome Desktop 3.36.2

The file `/etc/modprobe.d/mhwd-gpu.conf` contains:

```
#blacklist drm_kms_helper
#blacklist drm
options nvidia "NVreg_DynamicPowerManagement=0x02"
```

The file `/etc/modprobe.d/nvidia-drm.conf` contains:

```
options nvidia_drm modeset=1
```