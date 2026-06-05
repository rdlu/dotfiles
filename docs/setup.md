# Setup guide

How a fresh CachyOS/Arch machine becomes one of mine. Everything is driven by
[`just`](https://github.com/casey/just) — run `just` from the repo root to
list every recipe (full list in the [justfile reference](justfile.md)).

## Fresh machine

```sh
git clone git@github.com:rdlu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

just full-auto       # base packages, languages, CLI tools, fish, yazi, fastfetch
just full-auto-gui   # the above + kitty + the niri/waybar graphical stack
```

`full-auto` chains: `packages` → `dev-setup` → `cli-tools` → `fish-shell` →
`helix-editor` → `yazi-file-manager` → `fastfetch`. The `packages` step is
interactive — it pauses so you can review `/etc/xdg/reflector/reflector.conf`
and add the Chaotic AUR include to `/etc/pacman.conf`.

If you are not running `full-auto`, run `just packages` first: it sets up
Flatpak/Flathub, reflector mirrors, the Chaotic AUR repository, and the
`paru` AUR helper that every other recipe uses.

## The stow model

Configuration is deployed as symlinks with **GNU Stow** (`--dotfiles` mode:
`dot-foo` in the repo becomes `~/.foo`).

- **Base packages** (stowed on every machine):
  `home git idea scripts terminal lazyvim vim systemd niri`
- **Host overlays** in `hosts/<hostname>/` (stowed only on the matching
  machine): display layout, thermal sensors, machine-specific tools. The two
  hosts are `daisy` (AMD) and `xps` (Intel).

```sh
just stow         # symlink base + this host's overlay (auto-detected)
just stow-check   # dry-run: show what would change, touch nothing
just unstow       # remove all symlinks (host overlay first, then base)
```

`--no-folding` is used so base and host overlays can both populate shared
directories (`~/.config/mise`, `~/.local/share/applications`) without
tree-folding conflicts.

## Services

```sh
just services-enable
```

Enables the expected systemd **user** services (mpd, syncthing if installed,
solaar) and wires the niri session helpers (waybar, wpaperd, mako, swayidle)
to start with `niri.service` via `add-wants`. The swayosd backend is a
**system** unit and gets `sudo systemctl enable` instead.

## Tool versions: pacman + mise

Two deliberate layers:

- **pacman/paru** installs tools available in the repos (`just cli-tools`).
- **[mise](https://mise.jdx.dev/)** pins versions for languages and tools
  *not* in the repos: shared config in `terminal/dot-config/mise/config.toml`,
  per-host additions in `hosts/<hostname>/dot-config/mise/conf.d/<hostname>.toml`.

## Day to day

```sh
just update   # paru -Syu, mise upgrade, fisher, yazi plugins, nvim Lazy sync
just doctor   # health check: tools, login shell, host overlay, services, symlinks
```

## Docs

This site itself is part of the repo:

```sh
just docs-setup   # one-time: install typst (pandoc + uv come from the repos)
just docs         # regenerate markdown from configs, build HTML site + PDFs
just docs-serve   # live-preview the site while editing
```

`tools/gen-docs.py` (Python stdlib, no deps) re-reads `tmux.conf`,
`binds.kdl`, and the justfile and rewrites the generated blocks in the
markdown. [Zensical](https://zensical.org) (run via `uvx`, nothing to
install) builds the HTML site into `site/`; pandoc + Typst render the PDFs
into `docs/pdf/`, which the site links directly.
