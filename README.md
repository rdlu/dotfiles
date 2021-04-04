# Rodrigo Dlu dotfiles

My dotfiles for ArchLinux + TMUX + FISH shell

## TMUX Basics

I have an alias to open or continue a new TMUX session: `mux` or `mux1` (for the second muxer)

`CTRL + A` PREFIX to activate tmux commands, then:

| Key (After Prefix) | Action                 |
|--------------------|------------------------|
| `c`                | New Tab (Window)       |
| `1``2``3`...`9`    | Change to tab #1 to #9 |
| `!`                | Promotes Pane to Tab   |
| `,`                | Rename Tab             |
| `w`                | List Windows           |
| `f`                | Find Window            |
| `&`                | Kill Window            |
| `.`                | Move Window (prompt #) |
| `:movew + <ENTER>` | Move Window (unused #) |
| `$`                | Rename Session         |

## TMUX Plugins (with TPM)

### TMUX copycat

Use PREFIX `CTRL + A`, then:

| Key (After Prefix) | Action                               |
|--------------------|--------------------------------------|
| `/`                | regex search +  copy mode            |
| `n`                | jumps to the next match in copy mode |
| `N`                | jumps to the previous match          |
| `y`                | copy entire line                     |
| `Enter`            | copy highlighted match               |

### TMUX Yank

- `y` copy selection to system clipboard

_Tip with Mouse Support: press y before releasing mouse._

### Fuzzy Search With Extrakto

| Key (After Prefix) | Action                               |
|--------------------|--------------------------------------|
| `tab`              | Fuzzy search + fzf mode              |
| `enter`            | copy selection inside fzf mode       |

```
# Arch
yay -S fzf
# MacOS Brew
brew install fzf
```



### TMUX Resurrect

Use PREFIX `CTRL + A`, then:

| Key (After Prefix) | Action                 |
|--------------------|------------------------|
| `Ctrl + s`         | save all tabs          |
| `Ctrl + r`         | restore all tabs       |

### Navigation with TMUX Pain Control

#### Splitting panes

| Key (After Prefix) | Action                               |
|--------------------|--------------------------------------|
| `\|`               | split current pane horizontally      |
| `-`                | split current pane vertically        |

#### Basic Navigation

| Key (After Prefix) | Action                               |
|--------------------|--------------------------------------|
| `h` `C-h`          | select pane on the **left**          |
| `j` `C-j`          | select pane **below** the current    |
| `k` `C-k`          | select pane **above** the current    |
| `l` `C-l`          | select pane on the **right**         |

#### Resizing panes

| Key (After Prefix) | Action                               |
|--------------------|--------------------------------------|
| `S-h`              | resize **left**                      |
| `S-j`              | resize **up**                        |
| `S-k`              | resize **down**                      |
| `S-l`              | resize **right**                     |

#### Swapping windows

| Key (After Prefix) | Action                               |
|--------------------|--------------------------------------|
| `<`                | moves one position to the left       |
| `>`                | moves one position to the right      |

### TMUX Sessionist

| Key (After Prefix) | Action                                      |
|--------------------|---------------------------------------------|
| `g`                | prompts for session name and switches to it |
| `S-c`              | prompt for creating a new session by name   |
| `S-x`              | kill current session without detaching tmux |
| `S-s`              | switches to the last session                |
| `@`                | promote current pane into a new session     |

### TMUX urlview

| Key (After Prefix) | Action                               |
|--------------------|--------------------------------------|
| `u`                | list all urls on a side-panel        |

#### Dependencies

```
# Arch
yay -S urlview
# Ubuntu
sudo apt-get install urlview
# MacOS Brew
brew install urlview
```

### TMUX open

| Key (After Prefix) | Action                                                         |
|--------------------|----------------------------------------------------------------|
| `o`                | "open" a highlighted selection with the system default program |
| `Ctrl + o`         | open a highlighted selection with the $EDITOR                  |

_Linux Pre-reqs_: `xdg-open`

### TMUX Logging

| Key (After Prefix) | Action                 |
|--------------------|------------------------|
| `Shift + p`        | start/stop logging     |
| `Alt + p`          | log current screen     |
| `Alt + Shift + p`  | Save complete history  |

### TPM Plugins

To manage plugins, open `tmux.conf` in your editor, and go to `set -g @tpm_plugin` section.

| Key (After Prefix) | Action                 |
|--------------------|------------------------|
| `S-i`              | install new plugin     |
| `S-u`              | updates all plugins    |
