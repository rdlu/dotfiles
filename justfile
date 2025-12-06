[private]
default:
  @just --list

_echoerror text:
  @echo -e "{{ style("error") }}{{ text }}{{ NORMAL }}"

_echowarning text:
  @echo -e "{{ style("warning") }}{{ text }}{{ NORMAL }}"

# Full auto installation
full-auto: packages dev-setup fish-shell helix-editor yazi-file-manager fastfetch

# Fuller auto (graphical) installation
full-auto-gui: full-auto kitty-terminal niri-window-manager

# (Run first unless running full-auto) Setup Flatpak, pacman mirrors, Chaotic AUR, and paru AUR helper
packages:
  @just _echowarning "1) Installing Flatpak and adding Flathub repository"
  sudo pacman -S flatpak flatpak-xdg-utils
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  @just _echowarning "\n2) Installing reflector (automatic mirror configuration)"
  sudo pacman -S reflector

  @just _echoerror "\n\n----- IMPORTANT -----\nPlease modify /etc/xdg/reflector/reflector.conf before continuing\n---------------------"
  @read -p "Press enter to continue"

  sudo systemctl enable --now reflector.timer

  @just _echowarning "\n3) Adding Chaotic AUR repository to pacman"
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  sudo pacman-key --lsign-key 3056513887B78AEB

  sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
  sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

  @just _echoerror "\n\n----- IMPORTANT -----\nPlease add the following 2 lines to the end of /etc/pacman.conf before continuing\n\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n---------------------"
  @read -p "Press enter to continue"

  @just _echowarning "\n4) Installing paru AUR helper"
  sudo pacman -Sy paru

# Programming languages, runtimes, toolchains, and git
[group("install-essentials")]
dev-setup:
  @just _echowarning "1) Installing languages, runtimes, and toolchains"
  yay -S --needed nodejs npm python3 rustup zig erlang elixir

  @just _echowarning "\n2) Installing Rust language"
  rustup toolchain add stable-x86_64-unknown-linux-gnu

  @just _echowarning "\n3) Setting git global config"
  git config --global init.defaultBranch "main"

[group("install-other")]
fastfetch:
  @just _echowarning "1) Installing fastfetch and dependencies"
  yay -S fastfetch imagemagick

  @just _echowarning "\n2) Stowing fastfetch config"
  stow --dotfiles -S fastfetch

# fish shell and plugins
[group("install-essentials")]
fish-shell:
  @just _echowarning "1) Installing fish, fish plugin manager, and Starship prompt"
  yay -S --needed fisher fish starship atuin mise eza lazygit jj tmux zellij stow
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

  @just _echowarning "\n2) Stowing fish config"
  stow --dotfiles -S terminal

  @just _echowarning "\n3) Setting user shell"
  chsh -s /usr/bin/fish

  @just _echowarning "\n4) Installing fish plugins"
  fish -c "fisher update"

[group("install-essentials")]
helix-editor:
  @just _echowarning "1) Installing Helix and dependencies"
  yay -S --needed bash-language-server clang fish-lsp helix just-lsp marksman python-lsp-server shfmt taplo-cli typescript-language-server vscode-css-languageserver vscode-html-languageserver vscode-json-languageserver yaml-language-server zls

  @just _echowarning "\n2) Stowing Helix config"
  stow --dotfiles -S helix

[group("install-graphical")]
kitty-terminal:
  @just _echowarning "1) Installing Kitty and dependencies"
  yay -S --needed imagemagick kitty python-pygments ttf-firacode-nerd

  @just _echowarning "\n2) Stowing Kitty config"
  stow --dotfiles -S terminal

# Install niri and tools used with it
[group("install-graphical")]
niri-window-manager:
  @just _echowarning "1) Installing niri and related tools"
  yay -S --needed bluetui brightnessctl udiskie cliphist fuzzel gdm gnome-keyring inter-font mako niri-git noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra mate-polkit swayidle swaylock ttf-firacode-nerd ttf-font-awesome waybar wl-clipboard wlsunset wpaperd xdg-desktop-portal-gnome xwayland-satellite ttf-iawriter-nerd

  @just _echowarning "\n2) Stowing niri config"
  stow --dotfiles -S niri

  # @just _echowarning "\n3) Enabling GNOME display manager service"
  # sudo systemctl enable gdm

[group("install-other")]
syncthing-file-sync:
  @just _echowarning "1) Installing Syncthing"
  yay -S syncthing

  @just _echowarning "\n2) Enabling and starting Syncthing user service"
  systemctl enable --now --user syncthing

# Yazi terminal file manager and plugins
[group("install-essentials")]
yazi-file-manager:
  @just _echowarning "1) Installing Yazi and dependencies"
  yay -S --needed 7zip fd ffmpeg fzf imagemagick jq poppler resvg ripgrep wl-clipboard yazi zoxide

  @just _echowarning "\n2) Stowing Yazi config"
  stow --dotfiles -S terminal

  @just _echowarning "\n3) Installing Yazi plugins"
  ya pkg install


[group("stow")]
stow:
  stow --dotfiles -S home idea git scripts terminal lazyvim vim systemd

[group("stow")]
stow-daisy:
  stow --dotfiles -S home terminal niri scripts lazyvim vim systemd

[group("stow")]
stow-check:
  stow -n -v --dotfiles -S terminal niri scripts lazyvim vim systemd home

# Enables the systemd services for some essential niri helpers
systemd-niri-config: systemd-niri-config-install wpaper-reload mako-reload waybar-reload swayidle-reload
systemd-niri-config-install:
  systemctl --user add-wants niri.service wpaperd.service
  systemctl --user add-wants niri.service mako.service
  systemctl --user add-wants niri.service swayidle.service
  systemctl --user add-wants niri.service waybar.service
  systemctl enable swayosd-libinput-backend.service

[group("niri-reload")]
wpaper-reload:
  @just _echowarning "Reloading WallpaperD"
  systemctl --user reload-or-restart wpaperd.service

[group("niri-reload")]
mako-reload:
  @just _echowarning "Reloading Maki Notifications"
  systemctl --user reload-or-restart mako.service
  
[group("niri-reload")]
waybar-reload:
  @just _echowarning "Reloading Waybar"
  # systemctl --user reload-or-restart waybar.service
  systemctl --user restart waybar.service
 
[group("niri-reload")]
swayidle-reload:
  @just _echowarning "Reloading Swayidle"
  systemctl --user reload-or-restart swayidle.service
