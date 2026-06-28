# rdlu's dotfiles

Personal dotfiles for two [CachyOS](https://cachyos.org/) (Arch) notebooks —
**daisy** (AMD Ryzen) and **xps** (Intel/Dell XPS) — managed with
**GNU Stow** + a **justfile**, running niri · waybar · fish · tmux.

Repo: [github.com/rdlu/dotfiles](https://github.com/rdlu/dotfiles)

## Contents

- **[Setup guide](setup.md)** — bootstrap a fresh machine, stow model, per-host overlays
- **[Justfile reference](justfile.md)** — every recipe, generated from the live justfile
- **[File transfer](file-transfer.md)** — LocalSend + rsync-over-ssh, temporary firewall openings, install recipe
- **[Neovim plugins](neovim-plugins.md)** — the day-to-day LazyVim plugins and keymaps as wired on `nvim-light`
- **[tmux shortcuts](shortcuts/tmux.md)** — custom binds (generated from `tmux.conf`) + plugin cheatsheets
- **[herdr shortcuts](shortcuts/herdr.md)** — agent multiplexer (prefix Ctrl+b); binds + plugins, generated from `config.toml`
- **[tmux → herdr](tmux-vs-herdr.md)** — what carries over, what's remapped, what's rebuilt
- **[zellij shortcuts](shortcuts/zellij.md)** — generated from `config.kdl` (all modes)
- **[niri shortcuts](shortcuts/niri.md)** — generated from `binds.kdl`
- **[shell shortcuts](shortcuts/shell.md)** — fish binds (generated) + atuin/fzf/built-ins
- **[wl-kbptr](wl-kbptr.md)** — keyboard-driven mouse pointer for niri

## PDF downloads

Single-page landscape cheatsheets (A4, Catppuccin — **Latte** for print,
**Mocha** for screens), rebuilt from the live configs on every push:

<div class="pdf-grid">
  <div class="pdf-card tmux">
    <span class="pdf-title"><span class="pdf-icon">🖥️</span> tmux</span>
    <span class="pdf-sub">prefix Ctrl+a · plugins included</span>
    <span class="pdf-links">
      <a href="pdf/tmux-cheatsheet.pdf">Latte</a>
      <a href="pdf/tmux-cheatsheet-mocha.pdf">Mocha</a>
    </span>
  </div>
  <div class="pdf-card herdr">
    <span class="pdf-title"><span class="pdf-icon">🐃</span> herdr</span>
    <span class="pdf-sub">agent multiplexer · prefix Ctrl+b</span>
    <span class="pdf-links">
      <a href="pdf/herdr-cheatsheet.pdf">Latte</a>
      <a href="pdf/herdr-cheatsheet-mocha.pdf">Mocha</a>
    </span>
  </div>
  <div class="pdf-card zellij">
    <span class="pdf-title"><span class="pdf-icon">🧩</span> zellij</span>
    <span class="pdf-sub">every mode, complete map</span>
    <span class="pdf-links">
      <a href="pdf/zellij-cheatsheet.pdf">Latte</a>
      <a href="pdf/zellij-cheatsheet-mocha.pdf">Mocha</a>
    </span>
  </div>
  <div class="pdf-card niri">
    <span class="pdf-title"><span class="pdf-icon">🪟</span> niri</span>
    <span class="pdf-sub">all 145 compositor binds</span>
    <span class="pdf-links">
      <a href="pdf/niri-cheatsheet.pdf">Latte</a>
      <a href="pdf/niri-cheatsheet-mocha.pdf">Mocha</a>
    </span>
  </div>
  <div class="pdf-card shell">
    <span class="pdf-title"><span class="pdf-icon">🐟</span> shell</span>
    <span class="pdf-sub">fish · atuin · fzf</span>
    <span class="pdf-links">
      <a href="pdf/shell-cheatsheet.pdf">Latte</a>
      <a href="pdf/shell-cheatsheet-mocha.pdf">Mocha</a>
    </span>
  </div>
  <div class="pdf-card neovim">
    <span class="pdf-title"><span class="pdf-icon">💤</span> neovim</span>
    <span class="pdf-sub">LazyVim plugins · nvim-light</span>
    <span class="pdf-links">
      <a href="pdf/neovim-cheatsheet.pdf">Latte</a>
      <a href="pdf/neovim-cheatsheet-mocha.pdf">Mocha</a>
    </span>
  </div>
  <div class="pdf-card handbook wide">
    <span class="pdf-title"><span class="pdf-icon">📖</span> Dotfiles handbook</span>
    <span class="pdf-sub">everything in one PDF — setup guide, justfile reference, all shortcut pages</span>
    <span class="pdf-links">
      <a href="pdf/dotfiles-handbook.pdf">Download</a>
    </span>
  </div>
  <div class="pdf-card refs wide">
    <span class="pdf-title"><span class="pdf-icon">📄</span> Reference PDFs</span>
    <span class="pdf-sub">portrait per-page exports of the site content</span>
    <span class="pdf-links">
      <a href="pdf/tmux-shortcuts.pdf">tmux</a>
      <a href="pdf/herdr-shortcuts.pdf">herdr</a>
      <a href="pdf/zellij-shortcuts.pdf">zellij</a>
      <a href="pdf/niri-shortcuts.pdf">niri</a>
      <a href="pdf/shell-shortcuts.pdf">shell</a>
      <a href="pdf/neovim-plugins.pdf">neovim</a>
      <a href="pdf/justfile.pdf">justfile</a>
      <a href="pdf/setup.pdf">setup</a>
      <a href="pdf/file-transfer.pdf">file transfer</a>
      <a href="pdf/wl-kbptr.pdf">wl-kbptr</a>
    </span>
  </div>
</div>

## How these docs work

The shortcut tables and the justfile reference are **generated from the real
configuration** by [`tools/gen-docs.py`](https://github.com/rdlu/dotfiles/blob/main/tools/gen-docs.py),
so they can't drift from what the machines actually do. Hand-written prose
lives around the generated blocks. See the [setup guide](setup.md#docs) for
the build pipeline.
