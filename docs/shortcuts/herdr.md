# herdr shortcuts

[herdr](https://herdr.dev) is an *agent multiplexer* — a terminal multiplexer
built around AI coding agents, with workspaces, tabs, panes, git worktrees, and
persistent sessions. Launch it with `herdr`; it re-attaches to the running
session.

For how this maps onto my old tmux setup, see
[tmux vs herdr](../tmux-vs-herdr.md).

## Keybindings

Generated from
[`terminal/dot-config/herdr/config.toml`](https://github.com/rdlu/dotfiles/blob/main/terminal/dot-config/herdr/config.toml)
(prefix + custom & plugin commands) plus herdr's built-in defaults, by
`tools/gen-docs.py` — run `just docs-update` to refresh.

<!-- gen:herdr-binds -->
The prefix is `Ctrl+b` — press it, release, then the key; every `Ctrl+b X` below means *prefix then X*.

### Tabs

| Key | Action |
| --- | --- |
| `Ctrl+b c` | New tab |
| `Ctrl+b ,` | Rename tab |
| `Ctrl+b n` | Next tab |
| `Ctrl+b p` | Previous tab |
| `Ctrl+b 1-9` | Jump to tab 1–9 |
| `Ctrl+b Shift+x` | Close tab |

### Panes

| Key | Action |
| --- | --- |
| `Ctrl+b h j k l` | Focus pane ← ↓ ↑ → |
| `Ctrl+b =` | Split side-by-side |
| `Ctrl+b -` | Split stacked |
| `Ctrl+b v` | Split side-by-side (alias) |
| `Ctrl+b z` | Zoom / fullscreen pane |
| `Ctrl+b r` | Resize mode (then arrows / hjkl) |
| `Ctrl+b x` | Close pane |
| `Ctrl+b Tab` | Cycle to next pane |
| `Ctrl+b Shift+Tab` | Cycle to previous pane |
| `Ctrl+b Shift+p` | Rename pane |

### Workspaces & sessions

| Key | Action |
| --- | --- |
| `Ctrl+b w` | Workspace picker |
| `Ctrl+b Shift+n` | New workspace |
| `Ctrl+b .` | Rename workspace |
| `Ctrl+b Shift+d` | Close workspace (confirm) |
| `Ctrl+b Shift+g` | New git-worktree workspace |
| `Ctrl+b g` | Goto / jump prompt |
| `Ctrl+b Shift+1-9` | Jump to workspace 1–9 |
| `Ctrl+b [` | Previous workspace |
| `Ctrl+b ]` | Next workspace |
| `Ctrl+b q` | Detach session |

### Agents

| Key | Action |
| --- | --- |
| `Ctrl+b Alt+1-9` | Focus agent 1–9 |
| `Ctrl+b {` | Previous agent |
| `Ctrl+b }` | Next agent |

### Scrollback & misc

| Key | Action |
| --- | --- |
| `Ctrl+b e` | Edit / copy pane scrollback |
| `Ctrl+b b` | Toggle sidebar |
| `Ctrl+b Shift+o` | Open latest notification's target |
| `Ctrl+b s` | Settings |
| `Ctrl+b ?` | Help / keybinding overlay |
| `Ctrl+b Shift+r` | Reload config |

### Custom commands

| Key | Action |
| --- | --- |
| `Ctrl+b t` | Scratch shell (disposable pane) |
| `Ctrl+b f` | Pick files (fd+fzf) → inject paths |
| `Ctrl+b y` | Pick files (yazi UI) → inject paths |
| `Ctrl+b u` | Grab URLs / paths / IDs from scrollback |
| `Ctrl+b o` | Switch / open a project workspace |
| `Ctrl+b Up` | herdr-plus: projects |
| `Ctrl+b Down` | herdr-plus: quick actions |
| `Ctrl+b Shift+v` | reviewr: toggle review sidebar |

### Direct keys (no prefix)

| Key | Action |
| --- | --- |
| `Alt+h` | vim-nav: focus split / pane left |
| `Alt+j` | vim-nav: focus split / pane down |
| `Alt+k` | vim-nav: focus split / pane up |
| `Alt+l` | vim-nav: focus split / pane right |
<!-- /gen:herdr-binds -->
