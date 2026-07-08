# THIN TRANSITION SHIM: every recipe here just delegates to the mise task of
# the same name (tasks + repo docs tools live in ./mise.toml). Use
# `mise run <task>` / `mise tasks` directly — this justfile only remains so
# `just <recipe>` keeps working during the transition.
#
# Recipe dependencies are NOT declared here anymore — they live in mise
# (declaring them in both places would double-run them).

set shell := ["bash", "-uc"]

# Where the cheatsheet keycap font (JetBrainsMono Nerd Font) lives. Forwarded
# to the mise task as $CHEAT_FONT_PATH so the existing
# `just cheat_font_path=... docs-cheatsheets` override syntax still works.
cheat_font_path := "/usr/share/fonts/TTF"

[private]
default:
  @just --list

# Full auto installation
full-auto:
  @mise run full-auto

# Fuller auto (graphical) installation
full-auto-gui:
  @mise run full-auto-gui

# (Run first unless running full-auto) Setup Flatpak, pacman mirrors, Chaotic AUR, and paru AUR helper
packages:
  @mise run packages

# Programming languages, runtimes, toolchains, and git
[group("install-essentials")]
dev-setup:
  @mise run dev-setup

[group("install-other")]
fastfetch:
  @mise run fastfetch

# Essential CLI tools from the pacman repos
[group("install-essentials")]
cli-tools:
  @mise run cli-tools

# fish shell and plugins
[group("install-essentials")]
fish-shell:
  @mise run fish-shell

[group("install-essentials")]
helix-editor:
  @mise run helix-editor

# Install Emacs + Doom: clone the framework, stow config, sync packages
[group("install-essentials")]
doom-bootstrap:
  @mise run doom-bootstrap

[group("install-graphical")]
kitty-terminal:
  @mise run kitty-terminal

# Install niri and tools used with it
[group("install-graphical")]
niri-window-manager:
  @mise run niri-window-manager

# Import the Keybase PGP key into GPG and expose it for SSH auth
[group("install-other")]
keybase-ssh:
  @mise run keybase-ssh

[group("install-other")]
syncthing-file-sync:
  @mise run syncthing-file-sync

# Set up LocalSend + rsync-over-ssh receiving (packages, firewall, folder, docs)
[group("file-transfer")]
file-transfer:
  @mise run file-transfer

# Harden a receiving machine: inbound SSH key-only + LLMNR off (disables passwords!)
[group("file-transfer")]
file-transfer-harden:
  @mise run file-transfer-harden

# Install the package manifest (all of setup/packages.yaml, or one category)
[group("install-other")]
pkg-install category="":
  @mise run pkg-install "{{ category }}"

# List the manifest categories with their package counts
[group("install-other")]
pkg-categories:
  @mise run pkg-categories

# Explicit installs (post day-0) not yet in the manifest or any recipe
[group("maintenance")]
pkg-drift:
  @mise run pkg-drift

# Interactive manifest manager: browse categories, install/remove/audit (fzf TUI)
[group("maintenance")]
pkg-tui:
  @mise run pkg-tui

# ghzinga's viewer binary `gzg` comes from mise (cargo:ghzinga).
[group("install-other")]
herdr-plugins:
  @mise run herdr-plugins

# Yazi terminal file manager and plugins
[group("install-essentials")]
yazi-file-manager:
  @mise run yazi-file-manager

# Stow base packages + this host's overlay (hosts/$hostname/), auto-detected
[group("stow")]
stow:
  @mise run stow

# Dry-run the stow above (shows what would change, touches nothing)
[group("stow")]
stow-check:
  @mise run stow-check

# Remove all symlinks created by `stow` (host overlay first, then base)
[group("stow")]
unstow:
  @mise run unstow

# Enables the systemd services for some essential niri helpers
systemd-niri-config:
  @mise run systemd-niri-config

systemd-niri-config-install:
  @mise run systemd-niri-config-install

[group("niri-reload")]
wpaper-reload:
  @mise run wpaper-reload

[group("niri-reload")]
mako-reload:
  @mise run mako-reload

[group("niri-reload")]
waybar-reload:
  @mise run waybar-reload

[group("niri-reload")]
swayidle-reload:
  @mise run swayidle-reload

[group("niri-reload")]
polkit-agent-reload:
  @mise run polkit-agent-reload

# Keep the screen awake (pause auto-lock + blanking). Also on the power menu.
[group("niri-reload")]
caffeine action="toggle":
  @mise run caffeine "{{ action }}"

# Enable + start the user services this setup expects
[group("services")]
services-enable:
  @mise run services-enable

# One-time install of the docs toolchain (pandoc + typst; uv ships with CachyOS)
[group("docs")]
docs-setup:
  @mise run docs-setup

# Regenerate the generated markdown blocks from tmux.conf, binds.kdl, and the justfile
[group("docs")]
docs-update:
  @mise run docs-update

# Build the PDFs (per-page references + combined handbook) into docs/pdf/
[group("docs")]
docs-pdf:
  @CHEAT_FONT_PATH="{{ cheat_font_path }}" mise run docs-pdf

# Landscape cheatsheet PDFs, Catppuccin Latte (print) + Mocha (dark) variants
[group("docs")]
docs-cheatsheets:
  @CHEAT_FONT_PATH="{{ cheat_font_path }}" mise run docs-cheatsheets

# Build the HTML site into site/ (zensical from the repo's mise tools)
[group("docs")]
docs-html:
  @mise run docs-html

# Full docs build: regenerate markdown, then PDFs + cheatsheets, then the HTML site
[group("docs")]
docs:
  @CHEAT_FONT_PATH="{{ cheat_font_path }}" mise run docs

# Live-preview the docs site while editing (opens the browser once it's up)
[group("docs")]
docs-serve:
  @mise run docs-serve

# Open a PDF (default: the combined handbook; e.g. `just docs-open tmux-shortcuts`)
[group("docs")]
docs-open pdf="dotfiles-handbook":
  @mise run docs-open "{{ pdf }}"

# Bring an existing machine fully up to date (each step best-effort)
[group("maintenance")]
update:
  @mise run update

# Health check: tools present, shell, host overlay, services, mise, key symlinks
[group("maintenance")]
doctor:
  @mise run doctor
