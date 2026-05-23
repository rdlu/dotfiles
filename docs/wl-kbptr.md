# wl-kbptr

Keyboard-driven mouse pointer for Wayland. Replaces
[mouseless](https://mouseless.click), which is X11-shaped and breaks on niri.

Upstream: <https://github.com/moverest/wl-kbptr>

## Install

Bundled with the niri install target:

```sh
just niri-window-manager
```

Or standalone:

```sh
yay -S wl-kbptr jq
```

`jq` is required by the `wl-kbptr-other-output` helper (see Multi-monitor
notes). Config lives at `~/.config/wl-kbptr/config`, stowed from
`niri/dot-config/wl-kbptr/config` in this repo.

## Binds

|                              | Current monitor  | Other monitor    |
| ---------------------------- | ---------------- | ---------------- |
| **default** (tile,bisect)    | `Mod+G`          | `Mod+A`          |
| **+ click**                  | `Mod+Shift+G`    | `Mod+Shift+A`    |
| **coarse** (tile only)       | `Mod+Alt+G`      | `Mod+Alt+A`      |
| **tile + split**             | `Mod+Ctrl+G`     | `Mod+Ctrl+A`     |
| **bisect → tile**            | `Mod+N`          | `Mod+M`          |
| **bisect → tile + click**    | `Mod+Shift+N`    | `Mod+Shift+M`    |

The `Mod+N`/`Mod+M` families coarse-aim first, then refine on a grid:
press the chord, bisect into the rough quadrant with
`a`/`s`/`d`/`f`/`z`/`x`/`c`/`v` (positional left hand), recurse as deep
as you want, then press **Enter** to hand the current area off to tile.
Tile then shows labeled cells over that area — type the label, cursor
warps. Different mental model from `Mod+G` ("scan grid, type label"):
"point first, label second".

Other-monitor binds run `~/.local/bin/wl-kbptr-other-output` (stowed from
`niri/dot-local/bin/wl-kbptr-other-output`). The helper picks the
non-focused output, calls `niri msg action focus-monitor` to flip
keyboard focus there, then runs `wl-kbptr -O <name>`. Extra args are
forwarded so each variant passes its own `-o modes=...`.

## Mid-stream click keys

In any mode, pressing **`j`**/**`k`**/**`l`** commits the current cursor
position and clicks. No need to chain `click` mode for occasional clicks.

| Key | Click |
| --- | ----- |
| `j` | left  |
| `k` | right |
| `l` | middle |

## Modes

| Mode    | What it does                                                                            |
| ------- | --------------------------------------------------------------------------------------- |
| `tile`  | Grid of labeled cells. Type the label → cursor jumps to cell center.                    |
| `bisect`| Splits area into 2x4 (or 2x2 if square). One keypress per cell to refine.                |
| `split` | Crosshair-style refinement; arrow keys (or wasd/h) shrink the area toward that side.    |
| `click` | Commits position with a click. Default left; override with `-o mode_click.button=right`. |
| `floating` | Reads `WxH+X+Y` rectangles from stdin. Skip unless you script your targets.          |

Chains are left-to-right: each mode hands the chosen area to the next.

## Cell-pick keys (`home_row_keys`)

`home_row_keys` is exactly 11 characters: first 8 = bisect cells, last 3
= click buttons (left/right/middle).

Our config is `asdfzxcvjkl`:

```
  keyboard          screen cells
  a s d f             0 1 2 3   (top)
  z x c v             4 5 6 7   (bottom)

  j = left click
  k = right click
  l = middle click
```

Left hand drives bisect, right hand drives clicks. Symmetric, all stays
on the home row.

## Universal keys

| Key         | Action                                                |
| ----------- | ----------------------------------------------------- |
| `Enter`     | Commit current position; advance to next mode in chain |
| `Backspace` | Undo last keypress (works across mode boundaries)     |
| `Escape`    | Cancel — no warp, no click                            |

## Useful CLI flags

| Flag              | Use case                                                          |
| ----------------- | ----------------------------------------------------------------- |
| `-O <NAME>`       | Target a specific output (`DP-2`, `eDP-1`, ...).                  |
| `-r WxH+X+Y`      | Restrict overlay to a region (e.g. inside a single window).       |
| `-o KEY=VAL`      | Override config inline (`-o modes=tile,bisect,click`).            |
| `-p`              | Print result, don't warp or click. Test mode.                     |
| `-c FILE`         | Load alternate config file.                                       |

## Multi-monitor notes

- Default behavior (no `-O`): wl-kbptr passes NULL to layer-shell; niri
  assigns the overlay to the focused output. So `Mod+G` always uses the
  monitor your keyboard focus is on.
- `Mod+M` family targets the *other* monitor via the helper script. niri
  only routes keyboard input to a layer-surface on the focused output,
  so the helper calls `niri msg action focus-monitor <name>` before
  launching wl-kbptr. Without that, the overlay appears but typing keeps
  going to the previously-focused window.
- 3+ monitors: the helper picks an arbitrary non-focused one. For
  deterministic ordering, edit `wl-kbptr-other-output`.

## Gotchas

- **`~/.local/bin` is not in niri's PATH.** Bind helper scripts with the
  full `~/.local/bin/<name>` path. Bare command names silently no-op.
- **Split mode + our `home_row_keys`.** `j`/`k`/`l` are click buttons,
  so they don't navigate in split. Use arrow keys, or `w`/`a`/`s`/`h`
  for up/left/down/left fallback. See
  [issue #42](https://github.com/moverest/wl-kbptr/issues/42).
- **Maintainer comment in #42 misstates click order.** The thread says
  `i,j,k` = right/left/middle, but the v0.4.1 source has indices 8/9/10
  as LEFT/RIGHT/MIDDLE. Trust the source.

## Files

```
docs/wl-kbptr.md                          # this file
niri/dot-config/wl-kbptr/config           # home_row_keys + default mode chain
niri/dot-config/niri/binds.kdl            # Mod+G and Mod+M bind families
niri/dot-local/bin/wl-kbptr-other-output  # helper for the Mod+M family
```
