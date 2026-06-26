# tmux vs herdr

**herdr** is an *agent multiplexer*: a terminal multiplexer built around AI
coding agents rather than bare shells. Where tmux thinks in sessions, windows,
and panes, herdr adds first-class **agents** (it knows which pane runs which
agent and what state it's in), **workspaces**, built-in **git worktrees**, and
**persistent sessions** that survive a restart — no resurrect/continuum plugins
required.

I'm migrating from tmux to herdr while keeping **both in parallel**. To avoid a
prefix collision, herdr's prefix moved off the default `Ctrl-b` to **`F12`**,
which also keeps `Ctrl-a` (my old tmux prefix) and `Ctrl-b` free for readline
and for agents running inside panes. Everything below reads `prefix+X` as
`F12 X`.

!!! note
    This page is the *narrative* comparison. The complete, current binding
    list lives on the [**herdr shortcuts page**](shortcuts/herdr.md) — treat
    that as the source of truth for keys.

## Key differences at a glance

| Concept            | tmux                                  | herdr                                            |
| ------------------ | ------------------------------------- | ------------------------------------------------ |
| Prefix             | `Ctrl-b` (mine: `Ctrl-a`)             | `F12`                                            |
| Top-level grouping | Sessions → windows → panes            | Workspaces → tabs → panes                        |
| Splits             | `-h` side-by-side / `-v` stacked      | `split_vertical` = / `split_horizontal` stacked  |
| Agents             | None                                  | First-class: per-pane labels, state, sound       |
| Worktrees          | Manual / scripted                     | Built in (`F12 Shift+g`)                          |
| Persistence        | resurrect + continuum plugins         | Built in                                         |
| Theme              | catppuccin via TPM                    | Built in (`kanagawa`)                            |
| Extensibility      | TPM plugin ecosystem                  | Fixed feature set + native (manifest) plugins    |
| Copy / scrollback  | copy-mode + plugins                   | `edit_scrollback` + built-in mouse/copy UI       |

## What carries over

These habits survive the move unchanged — same physical key, same intent:

| Action                  | tmux        | herdr         |
| ----------------------- | ----------- | ------------- |
| Focus pane left/down/up/right | `h` `j` `k` `l` | `F12 h/j/k/l` |
| New tab/window          | `c`         | `F12 c`       |
| Jump to tab 1–9         | `1`…`9`     | `F12 1`…`9`   |
| Next tab/window         | `n`         | `F12 n`       |
| Zoom / fullscreen pane  | `z`         | `F12 z`       |
| Split side-by-side      | `=`         | `F12 =`       |
| Split stacked           | `-`         | `F12 -`       |

The split *keys* (`=` / `-`) are preserved on purpose, even though I had to
override herdr's defaults to get `=` (see below).

## What's remapped

**Prefix: `Ctrl-b` → `F12`.** The headline change. herdr defaults to `Ctrl-b`;
I rebound it to `F12` so `Ctrl-a`/`Ctrl-b` stay available for shell line-editing
and for agents inside panes, and so herdr and a still-running tmux don't fight
over the same prefix.

**Splits keep the keys but the action *names* invert.** tmux and herdr disagree
on what "horizontal" and "vertical" mean, so I bound by physical key + intent:

| Intent          | tmux key (action)        | herdr key (action)             |
| --------------- | ------------------------ | ------------------------------ |
| Side-by-side    | `=` (`split-window -h`)  | `F12 =` (`split_vertical`)     |
| Stacked         | `-` (`split-window -v`)  | `F12 -` (`split_horizontal`)   |

!!! tip
    `split_vertical` is bound to the list `["prefix+=", "prefix+v"]` — `=` is my
    added tmux-muscle key, and herdr's original `v` is kept as an alias.

A handful of management keys also moved layer:

| Action            | tmux        | herdr           |
| ----------------- | ----------- | --------------- |
| Rename tab        | `,`         | `F12 Shift+t`   |
| Rename workspace  | `$`         | `F12 Shift+w`   |
| Close tab         | `&`         | `F12 Shift+x`   |
| Detach            | `d`         | `F12 q`         |
| Reload config     | `r`         | `F12 Shift+r`   |
| Scrollback / copy | `Esc` / `[` | `F12 e`         |
| Resize            | `H J K L`   | `F12 r` + arrows|
| Previous tab      | `Ctrl-a Ctrl-a` | `F12 p`     |

Note `r` is deliberately herdr's **resize**, not reload — reload moved to
`F12 Shift+r`.

## herdr-only

Features tmux simply doesn't have:

- **Agent awareness** — herdr detects the agent in each pane, labels it on the
  border, tracks its state, and can notify/sort by state and resume agent
  sessions on restart. (`previous_agent` / `next_agent` / `focus_agent` exist
  but are unbound by default.)
- **Built-in git worktrees** — `F12 Shift+g` (`new_worktree`) spins up a
  worktree-backed workspace; no scripting.
- **Workspaces** — `F12 w` picker, `F12 Shift+n` new, `F12 Shift+w` rename, a
  layer above tabs.
- **Persistent sessions** — survive restart out of the box; no resurrect /
  continuum.
- **Built-in theming** — `kanagawa` ships in-app instead of a TPM theme plugin.
- Plus conveniences like `F12 b` sidebar, `F12 g` goto/jump, `F12 o` open the
  latest notification's target, and `F12 ?` keybinding overlay.

## No herdr equivalent (dropped)

herdr has **no tmux/TPM-style plugins**, so the plugins I relied on have no
replacement and are gone:

| Dropped                       | What it did                          |
| ----------------------------- | ------------------------------------ |
| tmux-thumbs (`Space`)         | Hint-based on-screen copy            |
| tmux-copycat (`/` `n` `N`)    | Regex search in scrollback           |
| tmux-open (`o` `C-o` `S`)     | Open selection / editor / web-search |
| tmux-logging (`P` `Alt-p/P`)  | Pane logging / screen capture        |
| cpu (`#{cpu_percentage}`)     | CPU% in the status bar               |

Also gone: the **`F12` nested OFF-mode** (passthrough that sent all keys to a
remote/nested tmux) — a direct conflict now that `F12` *is* herdr's prefix.
tmux-fzf (`F`), resurrect's save/restore keys, mouse-toggle keys, and pane-swap
(`< >`) likewise have no herdr binding (persistence, mouse, and copy are handled
internally instead).

## Rebuilt as herdr custom commands

A few plugin workflows I wasn't willing to lose were rebuilt as herdr **custom
commands**. These open a temporary pane that closes when the command exits, and
they talk to the triggering pane through herdr's pane API
(`herdr pane read` / `herdr pane send-text`):

| Key     | Command            | Replaces            | What it does                                            |
| ------- | ------------------ | ------------------- | ------------------------------------------------------- |
| `F12 u` | `herdr-extract`    | extrakto + urlview  | Fuzzy-grab URLs/paths/IDs from scrollback → copy / open / insert |
| `F12 f` | `pick-files-herdr` | pick-files          | Pick files, inject paths into the triggering pane       |
| `F12 t` | `exec $SHELL`      | `C-t` display-popup | Disposable scratch shell in a temp pane                 |

!!! note
    herdr has **no floating popups**; these are real (disposable) panes that
    close on exit, not `display-popup` overlays.

## When to use which

- **herdr** for AI-agent-heavy work: anything where I want per-pane agent
  state, worktree workspaces, and persistent sessions doing the heavy lifting.
- **tmux** over plain SSH and anywhere the plugins still matter — thumbs,
  copycat, logging, or nested/passthrough sessions on remote hosts that don't
  have herdr installed.

Both stay configured; the prefix split (`F12` vs `Ctrl-a`) lets them coexist
without stepping on each other.
