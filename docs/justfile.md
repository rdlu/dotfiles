# Justfile reference

All automation in this repo is a `just` recipe. This page is generated from
the live justfile by `tools/gen-docs.py` — run `just docs-update` to refresh
it.

<!-- gen:just-recipes -->
Run from the repo root. `just` with no arguments lists everything.

### Top-level

| Recipe | Description | Runs |
| --- | --- | --- |
| `just full-auto` | Full auto installation | `packages`, `dev-setup`, `cli-tools`, `fish-shell`, `helix-editor`, `yazi-file-manager`, `fastfetch` |
| `just full-auto-gui` | Fuller auto (graphical) installation | `full-auto`, `kitty-terminal`, `niri-window-manager` |
| `just packages` | (Run first unless running full-auto) Setup Flatpak, pacman mirrors, Chaotic AUR, and paru AUR helper |  |
| `just systemd-niri-config` | Enables the systemd services for some essential niri helpers | `systemd-niri-config-install`, `wpaper-reload`, `mako-reload`, `waybar-reload`, `swayidle-reload` |
| `just systemd-niri-config-install` |  |  |

### Install: essentials

| Recipe | Description | Runs |
| --- | --- | --- |
| `just cli-tools` | Essential CLI tools from the pacman repos |  |
| `just dev-setup` | Programming languages, runtimes, toolchains, and git |  |
| `just fish-shell` | fish shell and plugins |  |
| `just helix-editor` |  |  |
| `just yazi-file-manager` | Yazi terminal file manager and plugins |  |

### Install: graphical stack

| Recipe | Description | Runs |
| --- | --- | --- |
| `just kitty-terminal` |  |  |
| `just niri-window-manager` | Install niri and tools used with it |  |

### Install: optional extras

| Recipe | Description | Runs |
| --- | --- | --- |
| `just fastfetch` |  |  |
| `just keybase-ssh` | Import the Keybase PGP key into GPG and expose it for SSH auth |  |
| `just pkg-categories` | List the manifest categories with their package counts |  |
| `just pkg-install` | Install the package manifest (all of setup/packages.yaml, or one category) |  |
| `just syncthing-file-sync` |  |  |

### Stow (symlink management)

| Recipe | Description | Runs |
| --- | --- | --- |
| `just stow` | Stow base packages + this host's overlay (hosts/$hostname/), auto-detected |  |
| `just stow-check` | Dry-run the stow above (shows what would change, touches nothing) |  |
| `just unstow` | Remove all symlinks created by `stow` (host overlay first, then base) |  |

### Services

| Recipe | Description | Runs |
| --- | --- | --- |
| `just services-enable` | Enable + start the user services this setup expects |  |

### niri: reload helpers

| Recipe | Description | Runs |
| --- | --- | --- |
| `just mako-reload` |  |  |
| `just swayidle-reload` |  |  |
| `just waybar-reload` |  |  |
| `just wpaper-reload` |  |  |

### Maintenance

| Recipe | Description | Runs |
| --- | --- | --- |
| `just doctor` | Health check: tools present, shell, host overlay, services, mise, key symlinks |  |
| `just pkg-drift` | Explicit installs (post day-0) not yet in the manifest or any recipe |  |
| `just update` | Bring an existing machine fully up to date (each step best-effort) |  |

### Docs (this site)

| Recipe | Description | Runs |
| --- | --- | --- |
| `just docs` | Full docs build: regenerate markdown, then PDFs + cheatsheets, then the HTML site | `docs-pdf`, `docs-cheatsheets`, `docs-html` |
| `just docs-cheatsheets` | Landscape cheatsheet PDFs, Catppuccin Latte (print) + Mocha (dark) variants | `docs-update` |
| `just docs-html` | Build the HTML site into site/ (zensical via uvx) | `docs-update` |
| `just docs-open` | Open a PDF (default: the combined handbook; e.g. `just docs-open tmux-shortcuts`) | `docs-pdf` |
| `just docs-pdf` | Build the PDFs (per-page references + combined handbook) into docs/pdf/ | `docs-update` |
| `just docs-serve` | Live-preview the docs site while editing (opens the browser once it's up) | `docs-update` |
| `just docs-setup` | One-time install of the docs toolchain (pandoc + typst; uv ships with CachyOS) |  |
| `just docs-update` | Regenerate the generated markdown blocks from tmux.conf, binds.kdl, and this justfile |  |
<!-- /gen:just-recipes -->
