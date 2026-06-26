set shell := ["bash", "-uc"]

# Base stow packages deployed on every machine.
# Host-specific bits live in hosts/<hostname>/ (see the `stow` recipe).
base_packages := "home git idea scripts terminal lazyvim vim systemd niri"

# Where the cheatsheet keycap font (JetBrainsMono Nerd Font) lives. typst's
# default scan misses /usr/share/fonts/TTF on CachyOS, so point it there
# explicitly. Harmless if the dir is absent (e.g. CI), where cheatsheet.typ
# falls back to plain "JetBrains Mono".
cheat_font_path := "/usr/share/fonts/TTF"

[private]
default:
  @just --list

_echoerror text:
  @echo -e "{{ style("error") }}{{ text }}{{ NORMAL }}"

_echowarning text:
  @echo -e "{{ style("warning") }}{{ text }}{{ NORMAL }}"

# ALL package names live in setup/packages.yaml — recipes resolve their list
# from a category here; never hardcode package names in this justfile.

# Print the packages of one manifest category (empty category = all)
[private]
_pkgs category="":
  @awk -v cat="{{ category }}" '/^[a-z0-9][a-z0-9-]*:/ { c = substr($1, 1, length($1) - 1) } /^  - / { if (cat == "" || c == cat) print $2 }' setup/packages.yaml

# Full auto installation
full-auto: packages dev-setup cli-tools fish-shell helix-editor yazi-file-manager fastfetch

# Fuller auto (graphical) installation
full-auto-gui: full-auto kitty-terminal niri-window-manager

# (Run first unless running full-auto) Setup Flatpak, pacman mirrors, Chaotic AUR, and paru AUR helper
packages:
  @just _echowarning "1) Installing Flatpak and adding Flathub repository"
  sudo pacman -S --needed $(just _pkgs bootstrap-flatpak)
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  @just _echowarning "\n2) Installing reflector (automatic mirror configuration)"
  sudo pacman -S --needed $(just _pkgs bootstrap-mirrors)

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
  sudo pacman -Sy --needed $(just _pkgs bootstrap-aur-helper)

# Programming languages, runtimes, toolchains, and git
[group("install-essentials")]
dev-setup:
  @just _echowarning "1) Installing languages, runtimes, and toolchains"
  paru -S --needed $(just _pkgs languages)

  @just _echowarning "\n2) Installing Rust language"
  rustup default stable

  @just _echowarning "\n3) Setting git global config"
  git config --global init.defaultBranch "main"

  @just _echowarning "\n4) Bootstrapping mise-managed tool versions"
  mise install

[group("install-other")]
fastfetch:
  @just _echowarning "1) Installing fastfetch and dependencies"
  paru -S --needed $(just _pkgs fastfetch)

  @just _echowarning "\n2) Stowing fastfetch config"
  stow --no-folding --dotfiles -S fastfetch

# These are NOT managed by mise — mise only handles version-pinned languages
# and tools that aren't in the pacman repos.

# Essential CLI tools from the pacman repos
[group("install-essentials")]
cli-tools:
  @just _echowarning "Installing CLI tools via pacman"
  paru -S --needed $(just _pkgs cli-essentials)

# fish shell and plugins
[group("install-essentials")]
fish-shell:
  @just _echowarning "1) Installing fish, fish plugin manager, and Starship prompt"
  paru -S --needed $(just _pkgs fish-shell)
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
  paru -S --needed $(just _pkgs helix-editor)

  @just _echowarning "\n2) Stowing Helix config"
  stow --no-folding --dotfiles -S helix

[group("install-graphical")]
kitty-terminal:
  @just _echowarning "1) Installing the terminal emulators (kitty, ghostty, wezterm) and dependencies"
  paru -S --needed $(just _pkgs terminals)

  @just _echowarning "\n2) Stowing Kitty config"
  stow --no-folding --dotfiles -S terminal

# Install niri and tools used with it
[group("install-graphical")]
niri-window-manager:
  @just _echowarning "1) Installing niri and related tools"
  paru -S --needed $(just _pkgs niri-wm)

  @just _echowarning "\n2) Stowing niri config"
  stow --no-folding --dotfiles -S niri

  # @just _echowarning "\n3) Enabling GNOME display manager service"
  # sudo systemctl enable gdm

# Import the Keybase PGP key into GPG and expose it for SSH auth
[group("install-other")]
keybase-ssh:
  paru -S --needed $(just _pkgs keybase)
  keybase pgp export --secret | gpg --allow-secret-key-import --import
  keybase pgp pull-private --all
  ls ~/.gnupg/private-keys-v1.d/ | sed s/.key// >> ~/.gnupg/sshcontrol
  @just _echowarning "Keys loaded for SSH:"
  ssh-add -L

[group("install-other")]
syncthing-file-sync:
  @just _echowarning "1) Installing Syncthing"
  paru -S --needed $(just _pkgs syncthing)

  @just _echowarning "\n2) Enabling and starting Syncthing user service"
  systemctl enable --now --user syncthing

# Set up LocalSend + rsync-over-ssh receiving (packages, firewall, folder, docs)
[group("file-transfer")]
file-transfer:
  @just _echowarning "1) Installing transfer tools (LocalSend, rsync, openssh)"
  paru -S --needed $(just _pkgs file-transfer)

  @just _echowarning "\n2) Stowing helper scripts + niri menu entries"
  stow --no-folding --dotfiles -S scripts niri

  @just _echowarning "\n3) Firewall + transfer folder + docs"
  scripts/dot-local/bin/setup-file-transfer

# Harden a receiving machine: inbound SSH key-only + LLMNR off (disables passwords!)
[group("file-transfer")]
file-transfer-harden:
  scripts/dot-local/bin/harden-file-transfer-ssh

# setup/packages.yaml is the categorized manifest of everything intentionally
# installed beyond the recipes above (built from pacman.log: explicit installs
# after the day-0 CachyOS run). pkg-drift reports new intentional installs
# that aren't captured yet — add them to the yaml to keep it current.

# Install the package manifest (all of setup/packages.yaml, or one category)
[group("install-other")]
pkg-install category="":
  just _pkgs "{{ category }}" | sort -u | paru -S --needed -

# List the manifest categories with their package counts
[group("install-other")]
pkg-categories:
  @awk '/^[a-z][a-z0-9-]*:/ { if (c) print c, n; c = substr($1, 1, length($1) - 1); n = 0 } /^  - / { n++ } END { print c, n }' setup/packages.yaml | column -t

# Explicit installs (post day-0) not yet in the manifest or any recipe
[group("maintenance")]
pkg-drift:
  scripts/dot-local/bin/pacman-drift

# Interactive manifest manager: browse categories, install/remove/audit (fzf TUI)
[group("maintenance")]
pkg-tui:
  scripts/dot-local/bin/pkg-tui

# Register the herdr native plugins (idempotent; needs herdr running + network).
# ghzinga's viewer binary `gzg` comes from mise (cargo:ghzinga).
[group("install-other")]
herdr-plugins:
  herdr plugin install cloudmanic/herdr-plus --yes
  herdr plugin install dutifuldev/ghzinga/plugins/herdr --yes
  herdr server reload-config

# Yazi terminal file manager and plugins
[group("install-essentials")]
yazi-file-manager:
  @just _echowarning "1) Installing Yazi and dependencies"
  paru -S --needed $(just _pkgs yazi)

  @just _echowarning "\n2) Stowing Yazi config"
  stow --no-folding --dotfiles -S terminal

  @just _echowarning "\n3) Installing Yazi plugins"
  ya pkg install


# --no-folding lets base + host overlay both populate shared dirs
# (~/.config/waybar, ~/.config/mise) without tree-folding conflicts.
# CRITICAL: the -D lines need --no-folding too — unstowing WITHOUT it re-folds
# a shared dir around the other stow root's remaining links (e.g. waybar around
# hosts/daisy's host.jsonc), and the next -S dies parsing that cross-root link.
# `-` tolerates a first run where nothing is stowed yet.

# Stow base packages + this host's overlay (hosts/$hostname/), auto-detected
[group("stow")]
stow:
  -stow -D --no-folding --dotfiles -t ~ {{base_packages}}
  stow -S --no-folding --dotfiles -t ~ {{base_packages}}
  @host="$(hostname)"; \
  if [ -d "hosts/$host" ]; then \
    just _echowarning "Stowing host overlay: hosts/$host"; \
    stow -D --no-folding --dotfiles -d hosts -t ~ "$host" 2>/dev/null || true; \
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
    stow -D --no-folding --dotfiles -d hosts -t ~ "$host"; \
  fi
  stow -D --no-folding --dotfiles -t ~ {{base_packages}}

# Enables the systemd services for some essential niri helpers
systemd-niri-config: systemd-niri-config-install wpaper-reload mako-reload waybar-reload swayidle-reload
systemd-niri-config-install:
  systemctl --user add-wants niri.service wpaperd.service
  systemctl --user add-wants niri.service mako.service
  systemctl --user add-wants niri.service swayidle.service
  systemctl --user add-wants niri.service waybar.service
  # swayosd-libinput-backend is a SYSTEM unit — sudo, not --user
  -sudo systemctl enable --now swayosd-libinput-backend.service

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
  # syncthing is install-optional (see syncthing-file-sync); `-` skips if absent.
  -systemctl --user enable --now syncthing.service
  -systemctl --user enable solaar.service

  @just _echowarning "\n2) niri-session helpers (started with niri via add-wants)"
  systemctl --user add-wants niri.service waybar.service
  systemctl --user add-wants niri.service wpaperd.service
  systemctl --user add-wants niri.service mako.service
  systemctl --user add-wants niri.service swayidle.service

  @just _echowarning "\n3) swayosd backend (SYSTEM unit — sudo, NOT --user)"
  -sudo systemctl enable --now swayosd-libinput-backend.service

# Docs pipeline: gen-docs.py rewrites the generated markdown blocks from the
# live configs; zensical (via uvx, nothing installed) builds the HTML site
# into site/; pandoc+typst render PDFs into docs/pdf/ (linked by the site,
# so build PDFs before HTML).

# One-time install of the docs toolchain (pandoc + typst; uv ships with CachyOS)
[group("docs")]
docs-setup:
  paru -S --needed $(just _pkgs docs-toolchain)

# Regenerate the generated markdown blocks from tmux.conf, binds.kdl, and this justfile
[group("docs")]
docs-update:
  python3 tools/gen-docs.py

# Build the PDFs (per-page references + combined handbook) into docs/pdf/
[group("docs")]
docs-pdf: docs-update
  mkdir -p docs/pdf
  for page in setup file-transfer neovim-plugins justfile shortcuts/tmux shortcuts/herdr shortcuts/zellij shortcuts/niri shortcuts/shell wl-kbptr; do \
    out="$(basename "$page")"; \
    case "$out" in tmux|herdr|zellij|niri|shell) out="$out-shortcuts";; esac; \
    pandoc "docs/$page.md" -o "docs/pdf/$out.pdf" \
      --pdf-engine=typst --toc -V papersize=a4 -V mainfont="Libertinus Serif" -M date="$(date -I)"; \
  done
  pandoc docs/setup.md docs/file-transfer.md docs/neovim-plugins.md docs/justfile.md \
    docs/shortcuts/tmux.md docs/shortcuts/herdr.md \
    docs/shortcuts/zellij.md docs/shortcuts/niri.md docs/shortcuts/shell.md \
    docs/wl-kbptr.md \
    -o docs/pdf/dotfiles-handbook.pdf \
    --pdf-engine=typst --toc -V papersize=a4 -V mainfont="Libertinus Serif" \
    -M title="rdlu's dotfiles handbook" -M date="$(date -I)"

# Landscape cheatsheet PDFs, Catppuccin Latte (print) + Mocha (dark) variants
[group("docs")]
docs-cheatsheets: docs-update
  mkdir -p docs/pdf
  for sheet in tmux herdr zellij niri shell neovim; do \
    typst compile --font-path "{{ cheat_font_path }}" --input sheet=$sheet --input theme=latte \
      tools/cheatsheets/cheatsheet.typ "docs/pdf/$sheet-cheatsheet.pdf"; \
    typst compile --font-path "{{ cheat_font_path }}" --input sheet=$sheet --input theme=mocha \
      tools/cheatsheets/cheatsheet.typ "docs/pdf/$sheet-cheatsheet-mocha.pdf"; \
  done

# Build the HTML site into site/ (zensical via uvx)
[group("docs")]
docs-html: docs-update
  uvx zensical build --clean

# Full docs build: regenerate markdown, then PDFs + cheatsheets, then the HTML site
[group("docs")]
docs: docs-pdf docs-cheatsheets docs-html

# Live-preview the docs site while editing (opens the browser once it's up)
[group("docs")]
docs-serve: docs-update
  (sleep 1 && xdg-open http://localhost:8000) &
  uvx zensical serve

# Open a PDF (default: the combined handbook; e.g. `just docs-open tmux-shortcuts`)
[group("docs")]
docs-open pdf="dotfiles-handbook": docs-pdf
  xdg-open "docs/pdf/{{ pdf }}.pdf"

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
