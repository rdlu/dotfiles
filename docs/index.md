# rdlu's dotfiles

Personal dotfiles for two [CachyOS](https://cachyos.org/) (Arch) notebooks —
**daisy** (AMD Ryzen) and **xps** (Intel/Dell XPS) — managed with
**GNU Stow** + a **justfile**, running niri · waybar · fish · tmux.

Repo: [github.com/rdlu/dotfiles](https://github.com/rdlu/dotfiles)

## Contents

- **[Setup guide](setup.md)** — bootstrap a fresh machine, stow model, per-host overlays
- **[Justfile reference](justfile.md)** — every recipe, generated from the live justfile
- **[tmux shortcuts](shortcuts/tmux.md)** — custom binds (generated from `tmux.conf`) + plugin cheatsheets
- **[zellij shortcuts](shortcuts/zellij.md)** — generated from `config.kdl` (all modes)
- **[niri shortcuts](shortcuts/niri.md)** — generated from `binds.kdl`
- **[shell shortcuts](shortcuts/shell.md)** — fish binds (generated) + atuin/fzf.fish/built-ins
- **[wl-kbptr](wl-kbptr.md)** — keyboard-driven mouse pointer for niri

## PDF downloads

Built alongside the site (`just docs`):

- **Cheatsheets** (landscape A4, Catppuccin) —
  print (Latte): [tmux](pdf/tmux-cheatsheet.pdf) ·
  [zellij](pdf/zellij-cheatsheet.pdf) ·
  [niri](pdf/niri-cheatsheet.pdf) ·
  [shell](pdf/shell-cheatsheet.pdf) —
  dark (Mocha): [tmux](pdf/tmux-cheatsheet-mocha.pdf) ·
  [zellij](pdf/zellij-cheatsheet-mocha.pdf) ·
  [niri](pdf/niri-cheatsheet-mocha.pdf) ·
  [shell](pdf/shell-cheatsheet-mocha.pdf)
- [Dotfiles handbook (everything)](pdf/dotfiles-handbook.pdf)
- Reference PDFs: [tmux](pdf/tmux-shortcuts.pdf) ·
  [zellij](pdf/zellij-shortcuts.pdf) ·
  [niri](pdf/niri-shortcuts.pdf) ·
  [shell](pdf/shell-shortcuts.pdf) ·
  [justfile](pdf/justfile.pdf) ·
  [setup](pdf/setup.pdf) ·
  [wl-kbptr](pdf/wl-kbptr.pdf)

## How these docs work

The shortcut tables and the justfile reference are **generated from the real
configuration** by [`tools/gen-docs.py`](https://github.com/rdlu/dotfiles/blob/main/tools/gen-docs.py),
so they can't drift from what the machines actually do. Hand-written prose
lives around the generated blocks. See the [setup guide](setup.md#docs) for
the build pipeline.
