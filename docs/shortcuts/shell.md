# Shell shortcuts (fish)

Interactive-shell bindings: custom `bind` lines from this repo, plus the
bindings injected by [atuin](https://atuin.sh),
[fzf.fish](https://github.com/PatrickF1/fzf.fish), and fish itself.

## Custom bindings

Generated from the `bind` lines in `fish/` by `tools/gen-docs.py` — run
`just docs-update` to refresh.

<!-- gen:fish-binds -->
| Keys | Action | Defined in |
| --- | --- | --- |
| `Alt+f` | Open the yazi file manager | `fish/aliases.d/files.fish` |
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

## fzf.fish pickers

| Keys | Action | Alias |
| --- | --- | --- |
| `Ctrl+Alt+f` | Search directory (files; `Ctrl+d`/`Ctrl+f` reload dirs/files) | `fsd` |
| `Ctrl+Alt+l` | Git log | `fsgl` |
| `Ctrl+Alt+s` | Git status (changed files) | |
| `Ctrl+Alt+p` | Processes | `fsp` |
| `Ctrl+v` | Shell variables | |

## fish built-ins worth remembering

| Keys | Action |
| --- | --- |
| `Alt+e` | Edit the command line in `$EDITOR` |
| `Alt+s` | Prepend `sudo` to the current (or last) command |
| `Alt+←` `Alt+→` | Previous / next working directory (`prevd` / `nextd`) |
| `Alt+↑` `Alt+↓` | Recall arguments from previous commands |
| `Alt+l` | List the directory of the token under the cursor |
| `Alt+p` | Append `&| less` (paginate output) |
| `Alt+h` | Man page for the current command |
| `Alt+w` | One-line description of the current command |
| `Ctrl+w` | Delete one path component to the left |
| `Ctrl+z` | Undo last edit |

## Handy abbreviations & functions

The [abbreviation-tips](https://github.com/gazorby/fish-abbreviation-tips)
plugin reminds you of these when you type the long form.

| Type | Expands to / does |
| --- | --- |
| `mux` / `mux1` | open or re-attach tmux session `mux0` / `mux1` |
| `nvims` | fzf picker for neovim configs (default / nvim-lazy / nvim-full) |
| `nv` / `lvi` | neovim with the light / lazy config |
| `fsd` / `fsgl` / `fsp` | fzf search: directory / git log / processes |
| `z` / `zi` | zoxide: jump to dir / interactive picker |
| `b` | back to the previous directory and list it |
| `mcd` | `mkdir -p` + `cd` into it |
| `cpv` | copy with progress bar (`rsync`) |
