set shell := ["bash", "-uc"]

# Base stow packages deployed on every machine.
# Host-specific bits live in hosts/<hostname>/ (see the `stow` recipe).
base_packages := "home git idea scripts terminal lazyvim vim systemd niri"

[private]
default:
  @just --list

_echoerror text:
  @echo -e "{{ style("error") }}{{ text }}{{ NORMAL }}"

_echowarning text:
  @echo -e "{{ style("warning") }}{{ text }}{{ NORMAL }}"

# Full auto installation
full-auto: packages dev-setup cli-tools fish-shell helix-editor yazi-file-manager fastfetch

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
  paru -S --needed nodejs npm python3 rustup zig erlang elixir

  @just _echowarning "\n2) Installing Rust language"
  rustup default stable

  @just _echowarning "\n3) Setting git global config"
  git config --global init.defaultBranch "main"

  @just _echowarning "\n4) Bootstrapping mise-managed tool versions"
  mise install

[group("install-other")]
fastfetch:
  @just _echowarning "1) Installing fastfetch and dependencies"
  paru -S fastfetch imagemagick

  @just _echowarning "\n2) Stowing fastfetch config"
  stow --no-folding --dotfiles -S fastfetch

# These are NOT managed by mise — mise only handles version-pinned languages
# and tools that aren't in the pacman repos.

# Essential CLI tools from the pacman repos
[group("install-essentials")]
cli-tools:
  @just _echowarning "Installing CLI tools via pacman"
  paru -S --needed eza lazygit jujutsu zellij bottom jaq jnv ttyper monolith lazyjj lazydocker duckdb

# fish shell and plugins
[group("install-essentials")]
fish-shell:
  @just _echowarning "1) Installing fish, fish plugin manager, and Starship prompt"
  paru -S --needed fisher fish starship atuin mise tmux stow
  test -d ~/.tmux/plugins/tpm || git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

  @just _echowarning "\n2) Stowing fish config"
  stow --no-folding --dotfiles -S terminal

  @just _echowarning "\n3) Setting user shell"
  test "$SHELL" = /usr/bin/fish || chsh -s /usr/bin/fish

  @just _echowarning "\n4) Installing fish plugins"
  fish -c "fisher update"

[group("install-essentials")]
helix-editor:
  @just _echowarning "1) Installing Helix and dependencies"
  paru -S --needed bash-language-server clang fish-lsp helix just-lsp marksman python-lsp-server shfmt taplo-cli typescript-language-server vscode-css-languageserver vscode-html-languageserver vscode-json-languageserver yaml-language-server zls

  @just _echowarning "\n2) Stowing Helix config"
  stow --no-folding --dotfiles -S helix

[group("install-graphical")]
kitty-terminal:
  @just _echowarning "1) Installing Kitty and dependencies"
  paru -S --needed imagemagick kitty python-pygments ttf-firacode-nerd

  @just _echowarning "\n2) Stowing Kitty config"
  stow --no-folding --dotfiles -S terminal

# Install niri and tools used with it
[group("install-graphical")]
niri-window-manager:
  @just _echowarning "1) Installing niri and related tools"
  paru -S --needed bluetui brightnessctl udiskie cliphist fuzzel gdm gnome-keyring inter-font jq mako niri-git nerd-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra mate-polkit swayidle swaylock ttf-font-awesome ttf-jetbrains-mono waybar wl-clipboard wl-kbptr wlsunset wpaperd xdg-desktop-portal-gnome xwayland-satellite

  @just _echowarning "\n2) Stowing niri config"
  stow --no-folding --dotfiles -S niri

  # @just _echowarning "\n3) Enabling GNOME display manager service"
  # sudo systemctl enable gdm

[group("install-other")]
syncthing-file-sync:
  @just _echowarning "1) Installing Syncthing"
  paru -S syncthing

  @just _echowarning "\n2) Enabling and starting Syncthing user service"
  systemctl enable --now --user syncthing

# Yazi terminal file manager and plugins
[group("install-essentials")]
yazi-file-manager:
  @just _echowarning "1) Installing Yazi and dependencies"
  paru -S --needed 7zip fd ffmpeg fzf imagemagick jq poppler resvg ripgrep wl-clipboard yazi zoxide

  @just _echowarning "\n2) Stowing Yazi config"
  stow --no-folding --dotfiles -S terminal

  @just _echowarning "\n3) Installing Yazi plugins"
  ya pkg install


# --no-folding lets base + host overlay both populate shared dirs
# (~/.config/mise, ~/.local/share/applications) without tree-folding conflicts.
# The leading fold-aware `-D` clears any OLD folded symlinks first (e.g. a
# previously folded ~/.config/mise) so the `-S --no-folding` rebuild as real
# dirs never conflicts. `-` tolerates a first run where nothing is stowed yet.

# Stow base packages + this host's overlay (hosts/$hostname/), auto-detected
[group("stow")]
stow:
  -stow -D --dotfiles -t ~ {{base_packages}}
  stow -S --no-folding --dotfiles -t ~ {{base_packages}}
  @host="$(hostname)"; \
  if [ -d "hosts/$host" ]; then \
    just _echowarning "Stowing host overlay: hosts/$host"; \
    stow -D --dotfiles -d hosts -t ~ "$host" 2>/dev/null || true; \
    stow -S --no-folding --dotfiles -d hosts -t ~ "$host"; \
  else \
    just _echowarning "No host overlay for '$host' (hosts/$host absent) -- skipping"; \
  fi

# Dry-run the stow above (shows what would change, touches nothing)
[group("stow")]
stow-check:
  stow -n -v -R --no-folding --dotfiles -t ~ {{base_packages}}
  @host="$(hostname)"; \
  if [ -d "hosts/$host" ]; then \
    stow -n -v -R --no-folding --dotfiles -d hosts -t ~ "$host"; \
  fi

# Remove all symlinks created by `stow` (host overlay first, then base)
[group("stow")]
unstow:
  @host="$(hostname)"; \
  if [ -d "hosts/$host" ]; then \
    stow -D --dotfiles -d hosts -t ~ "$host"; \
  fi
  stow -D --dotfiles -t ~ {{base_packages}}

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

# Idempotent; replaces the old tracked *.target.wants/ symlinks. Lines that may
# be absent on a fresh machine are prefixed `-` so a missing unit doesn't abort.

# Enable + start the user services this setup expects
[group("services")]
services-enable:
  @just _echowarning "1) Globally-enabled user services"
  # Enable the service for boot + start it now (the bit that actually plays).
  # Enable the socket for boot-time socket-activation but DON'T --now it: if
  # mpd.service is already running, starting the socket fails ("already active").
  -systemctl --user enable --now mpd.service
  -systemctl --user enable mpd.socket
  -systemctl --user enable --now syncthing.service
  -systemctl --user enable solaar.service

  @just _echowarning "\n2) niri-session helpers (started with niri via add-wants)"
  systemctl --user add-wants niri.service waybar.service
  systemctl --user add-wants niri.service wpaperd.service
  systemctl --user add-wants niri.service mako.service
  systemctl --user add-wants niri.service swayidle.service
  -systemctl enable swayosd-libinput-backend.service

# Bring an existing machine fully up to date (each step best-effort)
[group("maintenance")]
update:
  -paru -Syu
  -mise upgrade
  -fish -c "fisher update"
  -ya pkg upgrade
  -nvim --headless "+Lazy! sync" +qa

# Health check: tools present, shell, host overlay, services, mise, key symlinks
[group("maintenance")]
doctor:
  @just _echowarning "Tools"
  @for t in fish tmux stow mise paru git nvim; do \
     command -v "$t" >/dev/null 2>&1 && echo "  ok    $t" || echo "  MISS  $t"; \
   done
  @just _echowarning "Shell"
  @sh=$(getent passwd "$USER" | cut -d: -f7); case "$sh" in */fish) echo "  ok    login shell is fish ($sh)";; *) echo "  warn  login shell=$sh (expected fish)";; esac
  @just _echowarning "Host overlay"
  @host="$(hostname)"; [ -d "hosts/$host" ] && echo "  ok    hosts/$host present" || echo "  warn  no hosts/$host overlay"
  @just _echowarning "User services enabled"
  @for s in mpd.service waybar.service wpaperd.service mako.service swayidle.service; do \
     echo "  $(systemctl --user is-enabled "$s" 2>/dev/null || echo missing)  $s"; \
   done
  @just _echowarning "mise resolves"
  @mise ls >/dev/null 2>&1 && echo "  ok    mise ls" || echo "  warn  mise ls failed"
  @just _echowarning "Key symlinks live"
  @for l in ~/.config/fish/config.fish ~/.config/mise/config.toml ~/.config/waybar/config.jsonc; do \
     [ -e "$l" ] && echo "  ok    $l" || echo "  MISS  $l"; \
   done
