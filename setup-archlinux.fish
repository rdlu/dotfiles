#! /usr/bin/fish
cd
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf
ln -s ~/.dotfiles/fish/config.fish ~/.config/fish/config.fish
ln -s ~/.dotfiles/fish/chips/plugin.yaml ~/.config/chips/plugin.yaml

# Defaulting colored output to pacman
sudo sed -i 's/#Color/Color/g' /etc/pacman.conf

sudo pacman -Suy
sudo pacman -Sy --needed tmux fpp fzf thefuck git shfmt

switch (lsb_release -is)
case ManjaroLinux
    sudo pacman -Sy --needed yay
case '*'
    if (which yay)
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