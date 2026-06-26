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
The prefix is `F12` — press it, release, then the key; every `F12 X` below means *prefix then X*.

### Tabs

| Key | Action |
| --- | --- |
| `F12 c` | New tab |
| `F12 Shift+t` | Rename tab |
| `F12 n` | Next tab |
| `F12 p` | Previous tab |
| `F12 1-9` | Jump to tab 1–9 |
| `F12 Shift+x` | Close tab |

### Panes

| Key | Action |
| --- | --- |
| `F12 h j k l` | Focus pane ← ↓ ↑ → |
| `F12 =` | Split side-by-side |
| `F12 -` | Split stacked |
| `F12 v` | Split side-by-side (alias) |
| `F12 z` | Zoom / fullscreen pane |
| `F12 r` | Resize mode (then arrows / hjkl) |
| `F12 x` | Close pane |
| `F12 Tab` | Cycle to next pane |
| `F12 Shift+Tab` | Cycle to previous pane |
| `F12 Shift+p` | Rename pane |

### Workspaces & sessions

| Key | Action |
| --- | --- |
| `F12 w` | Workspace picker |
| `F12 Shift+n` | New workspace |
| `F12 Shift+w` | Rename workspace |
| `F12 Shift+d` | Close workspace (confirm) |
| `F12 Shift+g` | New git-worktree workspace |
| `F12 g` | Goto / jump prompt |
| `F12 q` | Detach session |

### Scrollback & misc

| Key | Action |
| --- | --- |
| `F12 e` | Edit / copy pane scrollback |
| `F12 b` | Toggle sidebar |
| `F12 o` | Open latest notification's target |
| `F12 s` | Settings |
| `F12 ?` | Help / keybinding overlay |
| `F12 Shift+r` | Reload config |

### Custom commands

| Key | Action |
| --- | --- |
| `F12 t` | Scratch shell (disposable temp pane) |
| `F12 f` | Pick files → inject paths into the pane |
| `F12 u` | Grab URLs / paths / IDs from scrollback (copy / open / insert) |
| `F12 Up` | herdr-plus: project workspace templates |
| `F12 Down` | herdr-plus: quick-action launcher |
<!-- /gen:herdr-binds -->
