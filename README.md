# Rodrigo Dlu dotfiles

My personal dotfiles, managed with **GNU Stow** + a **`justfile`**. Two machines:

- **daisy** — AMD Ryzen notebook
- **xps** — Intel i7 notebook (Dell XPS)

Both run [CachyOS](https://cachyos.org/) (Arch) with niri · waybar · fish · tmux.

Shared config lives in the top-level stow packages; per-host differences (display
layout, thermal sensor, machine-specific tools/apps) live under
`hosts/<hostname>/`, which is stowed only on the matching machine.

## Usage

Everything is driven by [`just`](https://github.com/casey/just) — run `just` to list recipes.

**Fresh machine:**

```sh
just full-auto       # base packages, languages, CLI tools, fish, yazi, fastfetch
just full-auto-gui   # the above + kitty + the niri/waybar graphical stack
```

**Day to day:**

| recipe | what it does |
| --- | --- |
| `just stow` | symlink base packages + this host's `hosts/<hostname>/` overlay (auto-detected) |
| `just stow-check` / `just unstow` | dry-run / remove all symlinks |
| `just services-enable` | enable the expected systemd user services (mpd, niri helpers, …) |
| `just cli-tools` | install the pacman CLI utilities (eza, zellij, bottom, jaq, …) |
| `just update` | update everything (paru, mise, fisher, yazi plugins, nvim) |
| `just doctor` | health check: tools, login shell, services, mise, key symlinks |

Language and tool versions are pinned with [mise](https://mise.jdx.dev/): shared tools
in `terminal/dot-config/mise/config.toml`, per-host tools in
`hosts/<hostname>/dot-config/mise/conf.d/<hostname>.toml`. Tools available in the
pacman repos are installed via `just cli-tools` instead (mise only manages
version-pinned languages and tools not in the repos).

## Docs

Full documentation lives under [`docs/`](./docs/) and is published as an
HTML site + PDFs ([rdlu.github.io/dotfiles](https://rdlu.github.io/dotfiles/)):

- [Setup guide](./docs/setup.md) — fresh machine, stow model, services
- [Justfile reference](./docs/justfile.md) — generated from the live justfile
- [tmux shortcuts](./docs/shortcuts/tmux.md) — generated from `tmux.conf` + plugin cheatsheets
- [niri shortcuts](./docs/shortcuts/niri.md) — generated from `binds.kdl`
- [wl-kbptr](./docs/wl-kbptr.md) — keyboard-driven mouse pointer for niri

The shortcut tables are **generated from the real configs** by
[`tools/gen-docs.py`](./tools/gen-docs.py); [Zensical](https://zensical.org)
(via `uvx`) builds the HTML, pandoc + Typst render the PDFs:

```sh
just docs-setup   # one-time: pandoc + typst
just docs         # regenerate markdown, build site/ + docs/pdf/
just docs-serve   # live preview
```
