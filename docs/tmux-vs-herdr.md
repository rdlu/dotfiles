# tmux vs herdr

**herdr** is an *agent multiplexer*: a terminal multiplexer built around AI
coding agents rather than bare shells. Where tmux thinks in sessions, windows,
and panes, herdr adds first-class **agents** (it knows which pane runs which
agent and what state it's in), **workspaces**, built-in **git worktrees**, and
**persistent sessions** that survive a restart — no resurrect/continuum plugins
required.

I'm migrating from tmux to herdr while keeping **both in parallel**. herdr keeps
its default prefix **`Ctrl-b`**; tmux is on `Ctrl-a`, so the two multiplexers
don't collide. That leaves `Ctrl-a` free for readline and for agents running
inside herdr panes (and as tmux's prefix when one is nested). Everything below
reads `prefix+X` as `Ctrl-b X`.

!!! note
    This page is the *narrative* comparison. The complete, current binding
    list lives on the [**herdr shortcuts page**](shortcuts/herdr.md) — treat
    that as the source of truth for keys.

## Key differences at a glance

| Concept            | tmux                                  | herdr                                            |
| ------------------ | ------------------------------------- | ------------------------------------------------ |
| Prefix             | default `Ctrl-b` (mine: `Ctrl-a`)     | `Ctrl-b` (herdr default)                         |
| Top-level grouping | Sessions → windows → panes            | Workspaces → tabs → panes                        |
| Splits             | `-h` side-by-side / `-v` stacked      | `split_vertical` = / `split_horizontal` stacked  |
| Agents             | None                                  | First-class: per-pane labels, state, sound       |
| Worktrees          | Manual / scripted                     | Built in (`Ctrl-b Shift+g`)                          |
| Persistence        | resurrect + continuum plugins         | Built in                                         |
| Theme              | catppuccin via TPM                    | Built in (`kanagawa`)                            |
| Extensibility      | TPM plugin ecosystem                  | Fixed feature set + native (manifest) plugins    |
| Copy / scrollback  | copy-mode + plugins                   | `edit_scrollback` + built-in mouse/copy UI       |

## What carries over

These habits survive the move unchanged — same physical key, same intent:

| Action                  | tmux        | herdr         |
| ----------------------- | ----------- | ------------- |
| Focus pane left/down/up/right | `h` `j` `k` `l` | `Ctrl-b h/j/k/l` |
| New tab/window          | `c`         | `Ctrl-b c`       |
| Jump to tab 1–9         | `1`…`9`     | `Ctrl-b 1`…`9`   |
| Next tab/window         | `n`         | `Ctrl-b n`       |
| Zoom / fullscreen pane  | `z`         | `Ctrl-b z`       |
| Split side-by-side      | `=`         | `Ctrl-b =`       |
| Split stacked           | `-`         | `Ctrl-b -`       |

The split *keys* (`=` / `-`) are preserved on purpose, even though I had to
override herdr's defaults to get `=` (see below).

## What's remapped

**Prefix: stays on herdr's default `Ctrl-b`.** herdr keeps `Ctrl-b`; my tmux is
on `Ctrl-a`, so the two don't fight over the same prefix even when both run. That
also leaves `Ctrl-a` free for shell line-editing and for agents inside panes.
(I trialed `F12` to keep `Ctrl-b` free too, but went back to the default.)

**Splits keep the keys but the action *names* invert.** tmux and herdr disagree
on what "horizontal" and "vertical" mean, so I bound by physical key + intent:

| Intent          | tmux key (action)        | herdr key (action)             |
| --------------- | ------------------------ | ------------------------------ |
| Side-by-side    | `=` (`split-window -h`)  | `Ctrl-b =` (`split_vertical`)     |
| Stacked         | `-` (`split-window -v`)  | `Ctrl-b -` (`split_horizontal`)   |

!!! tip
    `split_vertical` is bound to the list `["prefix+=", "prefix+v"]` — `=` is my
    added tmux-muscle key, and herdr's original `v` is kept as an alias.

A handful of management keys also moved layer:

| Action            | tmux        | herdr           |
| ----------------- | ----------- | --------------- |
| Rename tab        | `,`         | `Ctrl-b ,`         |
| Rename workspace  | `$`         | `Ctrl-b .`         |
| Close tab         | `&`         | `Ctrl-b Shift+x`   |
| Detach            | `d`         | `Ctrl-b q`         |
| Reload config     | `r`         | `Ctrl-b Shift+r`   |
| Scrollback / copy | `Esc` / `[` | `Ctrl-b e`         |
| Resize            | `H J K L`   | `Ctrl-b r` + arrows|
| Previous tab      | `Ctrl-a Ctrl-a` | `Ctrl-b p`     |

`Ctrl-b ,` (rename tab) keeps tmux's `,` exactly; `Ctrl-b .` (rename workspace) is the
adjacent key, a small mnemonic I added since tmux's `$` had no obvious herdr home.

Note `r` is deliberately herdr's **resize**, not reload — reload moved to
`Ctrl-b Shift+r`.

## herdr-only

Features tmux simply doesn't have:

- **Agent awareness** — herdr detects the agent in each pane, labels it on the
  border, tracks its state, and can notify/sort by state and resume agent
  sessions on restart. `previous_agent` / `next_agent` / `focus_agent` ship
  unbound; I put them on `Ctrl-b {` / `Ctrl-b }` / `Ctrl-b Alt+1–9` — the curly
  brackets step agents (plain `[` / `]` step workspaces), mirroring
  `Ctrl-b Shift+1–9` for workspace jumps.
- **Built-in git worktrees** — `Ctrl-b Shift+g` (`new_worktree`) spins up a
  worktree-backed workspace; no scripting.
- **Workspaces** — `Ctrl-b w` picker, `Ctrl-b Shift+n` new, `Ctrl-b .` rename, a layer
  above tabs.
- **Persistent sessions** — survive restart out of the box; no resurrect /
  continuum.
- **Built-in theming** — `kanagawa` ships in-app instead of a TPM theme plugin.
- Plus conveniences like `Ctrl-b b` sidebar, `Ctrl-b g` goto/jump, `Ctrl-b Shift+o` open
  the latest notification's target, and `Ctrl-b ?` keybinding overlay.

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

tmux-fzf (`F`), resurrect's save/restore keys, mouse-toggle keys, and pane-swap
(`< >`) likewise have no herdr binding (persistence, mouse, and copy are handled
internally instead).

tmux's **`F12` nested OFF-mode** (passthrough that sends all keys to a
remote/nested tmux) is unaffected by the move: herdr sits on `Ctrl-b`, so `F12`
stays free for tmux and the two don't collide.

## Rebuilt as herdr custom commands

A few tmux workflows I wasn't willing to lose were rebuilt as herdr **custom
commands** (helper scripts in `scripts/dot-local/bin/`). Each opens a temporary
pane that closes when the command exits, and drives herdr over its CLI / pane
API (`herdr pane read` / `send-text`, `herdr workspace …`):

| Key     | Command            | Replaces            | What it does                                            |
| ------- | ------------------ | ------------------- | ------------------------------------------------------- |
| `Ctrl-b u` | `herdr-extract`    | extrakto + urlview  | Fuzzy-grab URLs/paths/IDs from scrollback → copy / open / insert (`Ctrl-G` opens a GitHub ref in ghzinga) |
| `Ctrl-b f` | `pick-files-herdr` | pick-files          | Pick files (fd+fzf), inject paths into the triggering pane |
| `Ctrl-b y` | `pick-files-yazi`  | — (yazi UI variant) | Same, but with yazi's full file-manager UI              |
| `Ctrl-b t` | `exec $SHELL`      | `C-t` display-popup | Disposable scratch shell in a temp pane                 |
| `Ctrl-b o` | `herdr-sessionize` | sessionx (`prefix o`) | Fuzzy-pick a project/notes dir → open or switch a workspace for it; leads with the already-open workspaces |

!!! note
    herdr has **no floating popups**; these are real (disposable) panes that
    close on exit, not `display-popup` overlays.

## Native plugins

Unlike the TPM plugins above (which have no herdr equivalent), herdr *does* have
its own manifest-based plugin system — these have no tmux analogue and are
installed with `just herdr-plugins`:

| Plugin | Key | What it adds |
| ------ | --- | ------------ |
| [herdr-plus](https://github.com/cloudmanic/herdr-plus) | `Ctrl-b Up` / `Ctrl-b Down` | Project workspace templates + a fuzzy quick-action launcher |
| [ghzinga](https://github.com/dutifuldev/ghzinga) | Ctrl-click / `Ctrl-b u` → `Ctrl-G` | Open a GitHub issue/PR in a side viewer pane |
| [reviewr](https://github.com/persiyanov/herdr-reviewr) | `Ctrl-b Shift+v` | Code-review sidebar for the focused agent's changes |
| [vim-herdr-navigation](https://github.com/paulbkim-dev/vim-herdr-navigation) | `Alt-h/j/k/l` | Seamless pane ↔ Neovim-split nav (the vim-tmux-navigator pattern) |

## When to use which

- **herdr** for AI-agent-heavy work: anything where I want per-pane agent
  state, worktree workspaces, and persistent sessions doing the heavy lifting.
- **tmux** over plain SSH and anywhere the plugins still matter — thumbs,
  copycat, logging, or nested/passthrough sessions on remote hosts that don't
  have herdr installed.

Both stay configured; the prefix split (herdr `Ctrl-b` vs tmux `Ctrl-a`) lets them coexist
without stepping on each other.
