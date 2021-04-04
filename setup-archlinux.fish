#! /usr/bin/fish

# Defaulting colored output to pacman
sudo sed -i 's/#Color/Color/g' /etc/pacman.conf

sudo pacman -Suy
sudo pacman -Sy --needed tmux fpp fzf thefuck git shfmt lsb-release

switch (lsb_release -is)
case ManjaroLinux
    sudo pacman -Sy --needed yay
case EndeavourOS
    sudo pacman -Sy --needed yay
case Arch
    if type -q yay
        echo "Yay already installed"
    else
        cd /tmp/
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si
    end
end

yay -S --needed tldr rbenv ruby-build elixir autoconf automake  \
    bison bind-tools fasd htop make patch ed fzf gcc mosh ruby tk yarn \
    php php-fpm python-pip \
    nfs-utils lsof strace python-pyusb mosh