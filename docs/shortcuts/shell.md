# Shell shortcuts (fish)

Interactive-shell bindings: custom `bind` lines from this repo, plus the
bindings injected by [atuin](https://atuin.sh) and fish itself.

## Custom bindings

Generated from the `bind` lines in `fish/` by `tools/gen-docs.py` — run
`just docs-update` to refresh.

<!-- gen:fish-binds -->
| Keys | Action | Defined in |
| --- | --- | --- |
| `Alt+f` | Open the yazi file manager | `fish/aliases.d/files.fish` |
| `Ctrl+t` | Insert file path(s) (fzf) | `fish/aliases.d/fzf-pickers.fish` |
| `Ctrl+Alt+d` | Insert a directory path (fzf) | `fish/aliases.d/fzf-pickers.fish` |
| `Ctrl+Alt+g` | Insert pacman package(s) (fzf) | `fish/aliases.d/fzf-pickers.fish` |
| `Ctrl+Alt+l` | Insert a commit SHA (fzf) | `fish/aliases.d/fzf-pickers.fish` |
| `Ctrl+Alt+s` | Insert changed file path(s) (fzf) | `fish/aliases.d/fzf-pickers.fish` |
| `Ctrl+Alt+p` | Insert a PID (fzf) | `fish/aliases.d/fzf-pickers.fish` |
| `Ctrl+v` | Insert a shell variable name (fzf) | `fish/aliases.d/fzf-pickers.fish` |
| `Ctrl+h` | Delete the word left of the cursor | `fish/aliases.d/keybinds.fish` |
| `Ctrl+e` | Neovim config picker (default / nvim-lazy / nvim-full) | `fish/conf.d/nvim-switcher.fish` |
<!-- /gen:fish-binds -->

## thefuck — fix the last command

Bound inside `fish_user_key_bindings` (`fish/conf.d/thefuck.fish`), so they
only appear in interactive shells.

| Keys | Action |
| --- | --- |
| `Esc Esc` or `Ctrl+f` | Correct the previous command (thefuck) |
| `fuck` (typed) | Same, as a function |

## History — atuin

`atuin init fish --disable-up-arrow` (in `config.fish`), so the up arrow
keeps plain fish history.

| Keys | Action |
| --- | --- |
| `Ctrl+r` | Fuzzy-search shell history (atuin) |
| `?` | Ask atuin AI (on an empty prompt) |

## fish built-ins worth remembering

| Keys | Action |
| --- | --- |
| `Alt+e` `Alt+v` | Edit the command line in `$EDITOR` |
| `Alt+s` | Prepend `sudo` (or `doas`) to the current (or last) command |
| `Alt+b` | Previous directory (`prevd`) on an empty line, else back one word |
| `Alt+↑` `Alt+↓` | Search history for the token under the cursor |
| `Alt+l` | List the directory of the token under the cursor |
| `Alt+p` | Append `&| less` (paginate output) |
| `Alt+h` `F1` | Man page for the command under the cursor |
| `Alt+w` | One-line description of the command under the cursor |
| `Ctrl+w` | Delete one path component to the left |
| `Ctrl+z` | Undo last edit |

**Inside herdr:** `Alt+h/j/k/l` are intercepted by
[vim-herdr-navigation](herdr.md) for pane/split movement, so fish's `Alt+h`
(man page) and `Alt+l` (list dir) only fire in a bare terminal — use `F1` for
the man page inside herdr. `Alt+f`'s fish default (`nextd`) is rebound to the
yazi launcher (see [Custom bindings](#custom-bindings) above).

## Handy abbreviations & functions

The [abbreviation-tips](https://github.com/gazorby/fish-abbreviation-tips)
plugin reminds you of these when you type the long form.

| Type | Expands to / does |
| --- | --- |
| `mux` / `mux1` | open or re-attach tmux session `mux0` / `mux1` |
| `nvims` | fzf picker for neovim configs (default / nvim-lazy / nvim-full) |
| `nv` / `lvi` | neovim with the light / lazy config |
| `z` / `zi` | zoxide: jump to dir / interactive picker |
| `b` | back to the previous directory and list it |
| `mcd` | `mkdir -p` + `cd` into it |
| `cpv` | copy with progress bar (`rsync`) |
