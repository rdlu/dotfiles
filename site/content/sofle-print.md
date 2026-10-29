---
title: Sofle keymap printout
description: The Sofle keymap as it works on these machines, laid out for A4 portrait. Printed to /pdf/sofle-keymap.pdf.
url: /sofle/print/
# A standalone page (layouts/sofle-print.html): no navbar, sidebar or footer,
# always the light palette. `mise run docs-sofle-pdf` (and CI) prints it with
# headless Chromium (tools/print-page-pdf.sh), after sofleii's own printout.
layout: sofle-print
sidebar:
  exclude: true
excludeSearch: true
noindex: true
sitemap:
  disable: true
# Pages after the first: each list is one A4 page of layer grids (up to three
# fit a portrait page), by layer name.
sheets:
  - layers: ["BASE", "NAV", "CODE"]
  - layers: ["MEDIA", "SYS|NUM"]
captions:
  BASE: "Always on. Joystick and encoder are media keys; F12 toggles tmux's nested OFF mode; hold the F12 key for AltGr."
  NAV: "Hold the left thumb's NAV key. Left half: niri workspaces, monitors and column moves, screenshots on the inner column. Right half: arrows and paging."
  CODE: "Hold the right thumb's CODE key. Brackets, digraphs and snippets; ▏ is where the cursor ends up."
  MEDIA: "Hold the right thumb's outer key. Volume and playback via Noctalia and playerctl; F20 is mic mute (xkb XF86AudioMicMute)."
  "SYS|NUM": "Hold the left thumb's outer key. Firmware only: Bluetooth, underglow and the mouse on the left, a numpad on the right."
---

<div class="cols">

## Layers

| Layer | How to get there |
| --- | --- |
| BASE | always on |
| NAV | hold the left thumb's 4th key (next to Backspace) |
| CODE | hold the right thumb's 2nd key (next to Space) |
| MEDIA | hold the right thumb's outer key |
| SYS\|NUM | hold the left thumb's outer key |

Release the key and you're back on BASE. The game layers (from SYS\|NUM)
are plain keys; see the sofleii printout.

## Reading the grids

Each key shows what it **does here**, resolved from `binds.kdl` and
`dot-tmux.conf`; its small top legend is the chord the keyboard sends, the
bottom one what it does when held. ◆ is Super (niri's `Mod`), ⌃ Ctrl,
⌥ Alt, ⇧ Shift.

{{< sofle-legend >}}

## Home-row mods

<kbd>S</kbd> Alt · <kbd>D</kbd> Ctrl · <kbd>F</kbd> Shift and
<kbd>J</kbd> Shift · <kbd>K</kbd> Ctrl · <kbd>L</kbd> Alt: tap for the
letter, hold for the mod. On NAV, S and D hold Alt and Ctrl too.

## Commands

The keys that reach niri or tmux, by layer.

{{< sofle-commands >}}

</div>
