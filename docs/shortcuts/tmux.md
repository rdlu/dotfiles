# tmux shortcuts

Aliases `mux` / `mux1` open (or re-attach to) the first and second sessions.

## Custom bindings

Generated from [`terminal/dot-tmux.conf`](https://github.com/rdlu/dotfiles/blob/main/terminal/dot-tmux.conf)
by `tools/gen-docs.py` — run `just docs-update` to refresh.

<!-- gen:tmux-binds -->
The prefix is `C-a` (`Ctrl+a`).

### After the prefix

Press the prefix first, then the key.

| Key | Description | Command |
| --- | --- | --- |
| `C-a` | Jump to the last active window | `last-window` |
| `Escape` | Enter copy mode | `copy-mode` |
| `p` | Paste buffer | `paste-buffer` |
| `r` | Reload `~/.tmux.conf` | `source-file ${HOME}/.tmux.conf \; display-message "source-file reloaded"` |
| `C-l` | Send a literal `Ctrl+L` (clear screen) to the pane | `send-keys 'C-l'` |
| `=` | Split pane **horizontally** (keeps current path) | `split-window -h -c "#{pane_current_path}"` |
| `-` | Split pane **vertically** (keeps current path) | `split-window -v -c "#{pane_current_path}"` |
| `M` | Mouse mode **ON** | `set -g mouse on \; display 'Mouse: ON'` |
| `m` | Mouse mode **OFF** | `set -g mouse off \; display 'Mouse: OFF'` |
| `u` | Capture pane and pick a URL to open (urlview popup window) | `capture-pane \; save-buffer /tmp/tmux-buffer \; new-window -n "urlview"…` |
| `C-t` | Popup **terminal** in the current pane's path | `display-popup -E -h 70% -w 70% -d "#{pane_current_path}"` |

### No prefix (root table)

Active anywhere, no prefix needed.

| Key | Description | Command |
| --- | --- | --- |
| `F12` | Toggle **OFF mode** for nested/remote tmux — all keys (incl. the prefix) pass through to the pane; status bar turns red | `set prefix None \; set key-table off \; set status-style "fg=colour245,…` |
| `C-t` | Unified **file finder** — passed through in fish/editors, else a popup that injects paths into the pane's TUI (`pick-files`) | `if-shell "case '#{pane_current_command}' in fish\|nvim\|vim\|hx) exit 0 ;;…` |

### Copy mode (vi keys)

Active while in copy mode.

| Key | Description | Command |
| --- | --- | --- |
| `v` | Begin selection (vi-style) | `send-keys -X begin-selection` |
| `C-v` | Toggle rectangle (block) selection | `send-keys -X rectangle-toggle` |
| `y` | Copy selection and leave copy mode | `send-keys -X copy-selection-and-cancel` |

### OFF mode

Active only while OFF mode is toggled on.

| Key | Description | Command |
| --- | --- | --- |
| `F12` | Leave OFF mode (restore the local prefix) | `set -u prefix \; set -u key-table \; set -u status-style \; set -u wind…` |
<!-- /gen:tmux-binds -->

## tmux defaults worth remembering

| Key (after prefix) | Action                 |
| ------------------ | ---------------------- |
| `c`                | New tab (window)       |
| `1` `2` `3`…`9`    | Change to tab #1 to #9 |
| `!`                | Promote pane to tab    |
| `,`                | Rename tab             |
| `w`                | List windows           |
| `f`                | Find window            |
| `&`                | Kill window            |
| `.`                | Move window (prompt #) |
| `:movew` + `Enter` | Move window (unused #) |
| `$`                | Rename session         |

## Plugin bindings (TPM)

Plugin keymaps are defined by the plugins themselves, not in `tmux.conf`, so
these tables are maintained by hand. The plugin list lives in the
`@tpm_plugins` block of `tmux.conf`. Manage plugins with `Prefix` + `I`
(install) and `Prefix` + `U` (update all).

### copycat

| Key (after prefix) | Action                               |
| ------------------ | ------------------------------------ |
| `/`                | regex search + copy mode             |
| `n`                | jump to the next match in copy mode  |
| `N`                | jump to the previous match           |
| `y`                | copy entire line                     |
| `Enter`            | copy highlighted match               |

### yank

- `y` — copy selection to the system clipboard

*Tip with mouse support: press `y` before releasing the mouse.*

### extrakto (fuzzy search)

| Key (after prefix) | Action                         |
| ------------------ | ------------------------------ |
| `Tab`              | fuzzy search + fzf mode        |
| `Enter`            | copy selection inside fzf mode |

Requires `fzf` (`paru -S fzf`).

### resurrect + continuum

| Key (after prefix) | Action           |
| ------------------ | ---------------- |
| `Ctrl+s`           | save all tabs    |
| `Ctrl+r`           | restore all tabs |

Continuum is configured with `@continuum-restore on`, so sessions also
restore automatically when the tmux server starts.

### pain-control (panes)

Splitting:

| Key (after prefix) | Action                          |
| ------------------ | ------------------------------- |
| `\|`               | split current pane horizontally |
| `-`                | split current pane vertically   |

Navigation:

| Key (after prefix) | Action                            |
| ------------------ | --------------------------------- |
| `h` `C-h`          | select pane on the **left**       |
| `j` `C-j`          | select pane **below** the current |
| `k` `C-k`          | select pane **above** the current |
| `l` `C-l`          | select pane on the **right**      |

Resizing:

| Key (after prefix) | Action           |
| ------------------ | ---------------- |
| `H`                | resize **left**  |
| `J`                | resize **down**  |
| `K`                | resize **up**    |
| `L`                | resize **right** |

Swapping windows:

| Key (after prefix) | Action                         |
| ------------------ | ------------------------------ |
| `<`                | move one position to the left  |
| `>`                | move one position to the right |

### sessionist (sessions)

| Key (after prefix) | Action                                       |
| ------------------ | -------------------------------------------- |
| `g`                | prompt for session name and switch to it     |
| `C`                | prompt for creating a new session by name    |
| `X`                | kill current session without detaching tmux  |
| `S`                | switch to the last session                   |
| `@`                | promote current pane into a new session      |

### sessionx (session picker)

| Key (after prefix) | Action                                          |
| ------------------ | ----------------------------------------------- |
| `o`                | open the sessionx picker (zoxide mode, `~/Projects`) |

### open

| Key (in copy mode) | Action                                                       |
| ------------------ | ------------------------------------------------------------ |
| `o`                | open a highlighted selection with the system default program |
| `Ctrl+o`           | open a highlighted selection with `$EDITOR`                  |
| `S`                | web-search the selection (DuckDuckGo)                        |

### thumbs

Hint-based copy: trigger with `Prefix` + `Space`, then press the hint key to
copy that text (configured to use `wl-copy` via OSC52).

### logging

| Key (after prefix) | Action                |
| ------------------ | --------------------- |
| `P`                | start/stop logging    |
| `Alt+p`            | log current screen    |
| `Alt+P`            | save complete history |

### fzf

`Prefix` + `F` opens the tmux-fzf menu (sessions, windows, panes, commands).
