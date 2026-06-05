# zellij shortcuts

Key bindings for [zellij](https://zellij.dev/) — configured with
`clear-defaults=true`, so everything below is the complete map.

Generated from [`terminal/dot-config/zellij/config.kdl`](https://github.com/rdlu/dotfiles/blob/main/terminal/dot-config/zellij/config.kdl)
by `tools/gen-docs.py` — run `just docs-update` to refresh.

<!-- gen:zellij-binds -->
The default mode is **locked** (keys pass through to the shell). `Ctrl a` enters **tmux mode** — a tmux-style prefix — and `Ctrl g` toggles the regular zellij modes. Most actions return to locked automatically.

### Tmux mode — Ctrl a

| Keys | Action |
| --- | --- |
| `[` | → scroll mode |
| `Ctrl a` | Toggle last tab |
| `z` `f` | Fullscreen pane |
| `c` `t` | New tab |
| `s` `$` `:` | Open session-manager |
| `\|` | New pane right |
| `-` | New pane down |
| `p` | Previous tab |
| `n` | Next tab |
| `1…6` | Go to tab 1…6 |
| `,` | Rename tab |
| `Left` `h` | Focus pane left |
| `Right` `l` | Focus pane right |
| `Down` `j` | Focus pane down |
| `Up` `k` | Focus pane up |
| `.` | Rename pane |
| `H` | Grow left |
| `L` | Grow right |
| `K` | Grow up |
| `J` | Grow down |
| `e` | Embed ⇄ float pane |
| `w` | Show/hide floating panes |
| `d` | Detach session |
| `Space` | Next layout |
| `x` | Close pane |
| `/` | Search |

### Always available (normal & locked)

| Keys | Action |
| --- | --- |
| `Alt left` `Alt h` | Focus pane/tab left |
| `Alt down` `Alt j` | Focus pane down |
| `Alt up` `Alt k` | Focus pane up |
| `Alt right` `Alt l` | Focus pane/tab right |
| `Alt +` `Alt =` | Grow |
| `Alt -` | Shrink |
| `Alt f` | Show/hide floating panes |
| `Alt i` | Move tab left |

### Pane mode — p

| Keys | Action |
| --- | --- |
| `left` `h` | Focus pane left |
| `down` `j` | Focus pane down |
| `up` `k` | Focus pane up |
| `right` `l` | Focus pane right |
| `c` | Rename pane |
| `d` | New pane down |
| `e` | Embed ⇄ float pane |
| `f` | Fullscreen pane |
| `n` | New pane |
| `p` | → normal mode |
| `r` | New pane right |
| `w` | Show/hide floating panes |
| `x` | Close pane |
| `z` | Toggle pane frames |
| `tab` | Next pane |

### Tab mode — t

| Keys | Action |
| --- | --- |
| `left` `up` `h` `k` | Previous tab |
| `down` `right` `j` `l` | Next tab |
| `1…9` | Go to tab 1…9 |
| `[` | Break pane to tab left |
| `]` | Break pane to tab right |
| `b` | Break pane into new tab |
| `n` | New tab |
| `r` | Rename tab |
| `s` | Sync input to all panes in tab |
| `t` | → normal mode |
| `x` | Close tab |
| `tab` | Toggle last tab |

### Resize mode — r

| Keys | Action |
| --- | --- |
| `left` `h` | Grow left |
| `down` `j` | Grow down |
| `up` `k` | Grow up |
| `right` `l` | Grow right |
| `+` `=` | Grow |
| `-` | Shrink |
| `H` | Shrink left |
| `J` | Shrink down |
| `K` | Shrink up |
| `L` | Shrink right |
| `r` | → normal mode |

### Move mode — m

| Keys | Action |
| --- | --- |
| `left` `h` | Move pane left |
| `down` `j` | Move pane down |
| `up` `k` | Move pane up |
| `right` `l` | Move pane right |
| `m` | → normal mode |
| `n` `tab` | Move pane (next) |
| `p` | Move pane backwards |

### Scroll mode — s

| Keys | Action |
| --- | --- |
| `Alt left` `Alt h` | Focus pane/tab left |
| `Alt down` `Alt j` | Focus pane down |
| `Alt up` `Alt k` | Focus pane up |
| `Alt right` `Alt l` | Focus pane/tab right |
| `e` | Edit scrollback in $EDITOR |
| `f` | Search |
| `s` | → normal mode |

### Scrolling keys (scroll & search)

| Keys | Action |
| --- | --- |
| `PageDown` `right` `Ctrl f` `l` | Page down |
| `PageUp` `left` `Ctrl b` `h` | Page up |
| `down` `j` | Line down |
| `up` `k` | Line up |
| `Ctrl c` | Jump to bottom |
| `d` | Half page down |
| `u` | Half page up |

### Search options

| Keys | Action |
| --- | --- |
| `c` | Toggle case-sensitivity |
| `n` | Next match |
| `o` | Toggle whole-word |
| `p` | Previous match |
| `w` | Toggle wrap |

### Session mode — o

| Keys | Action |
| --- | --- |
| `c` | Open configuration |
| `d` | Detach session |
| `o` | → normal mode |
| `p` | Open plugin-manager |
| `w` | Open session-manager |

### Locked mode (default)

| Keys | Action |
| --- | --- |
| `Ctrl g` | → normal mode |
| `Ctrl a` | → tmux mode |

### Mode switches & misc

| Keys | Action |
| --- | --- |
| `Ctrl g` `Ctrl a` `enter` `esc` `Ctrl c` | → locked mode |
| `Ctrl q` | Quit zellij |
| `m` | → move mode |
| `o` | → session mode |
| `t` | → tab mode |
| `s` `Ctrl c` `esc` | → scroll mode |
| `p` | → pane mode |
| `r` | → resize mode |
| `enter` | → search mode |
| `esc` | Cancel rename · → tab mode |
| `esc` | Cancel rename · → pane mode |
<!-- /gen:zellij-binds -->
