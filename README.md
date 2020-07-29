# Rodrigo Dlu dotfiles

My dotfiles for ArchLinux + TMUX + FISH shell

# TMUX Basics

`CTRL + A` PREFIX to activate tmux commands, then:

- `$` rename session
- `c` new tab (window)
- `,` rename tab
- `w` list windows
- `f` find window
- `&` kill window
- `.` move window - prompted for a new number
- `:movew + <ENTER>`  move window to the next unused number

# TMUX Plugins

## TMUX copycat

Use PREFIX `CTRL + A`, then:

- `/` regex search +  copy mode
- `n` jumps to the next match in copy mode
- `N` jumps to the previous match

- `y` copy entire line

To copy a highlighted match:

Enter - if you're using Tmux vi mode
ctrl-w or alt-w - if you're using Tmux emacs mode


## TMUX Yank

- `y` copy selection to system clipboard

_Tip with Mouse Support: press y before releasing mouse._

## TMUX Resurrect

Use PREFIX `CTRL + A`, then:

- `Ctrl + s` save all tabs
- `Ctrl + r` restore all tabs

## TMUX open
o - "open" a highlighted selection with the system default program. open for OS X or xdg-open for Linux.
Ctrl-o - open a highlighted selection with the $EDITOR

## TMUX Logging
Logging: Key binding: prefix + shift + p (start/stop)
"Screen capture": Key binding: prefix + alt + p
Save complete history: Key binding: prefix + alt + shift + p

## TMUX Pain Control
### Navigation
prefix + h and prefix + C-h
select pane on the left
prefix + j and prefix + C-j
select pane below the current one
prefix + k and prefix + C-k
select pane above
prefix + l and prefix + C-l
select pane on the right
### Resizing panes
prefix + shift + h
resize current pane 5 cells to the left
prefix + shift + j
resize 5 cells in the up direction
prefix + shift + k
resize 5 cells in the down direction
prefix + shift + l
resize 5 cells to the right
### Splitting panes
prefix + |
split current pane horizontally
prefix + -
split current pane vertically
### Swapping windows
prefix + < - moves current window one position to the left
prefix + > - moves current window one position to the right
## Tmux sessionist
prefix + g - prompts for session name and switches to it. Performs 'kind-of' name completion.
Faster than the built-in prefix + s prompt for long session lists.
prefix + C (shift + c) - prompt for creating a new session by name.
prefix + X (shift + x) - kill current session without detaching tmux.
prefix + S (shift + s) - switches to the last session.
The same as built-in prefix + L that everyone seems to override with some other binding.
prefix + @ - promote current pane into a new session.
Analogous to how prefix + ! breaks current pane to a new window.
## Tmux urlview
Dep(Ubuntu): sudo apt-get install urlview
u - "urlview" for a side-panel listing all urls
## Tmux fpp
Dep(Ubuntu): https://github.com/facebook/PathPicker/releases/download/0.6.1/fpp.deb
f - "fpp" for a new window with a Facebook PathPicker selection of your tty.




#VIM

[count]\cc |NERDComComment|
Comment out the current line or text selected in visual mode.

[count]\cn |NERDComNestedComment|
Same as \cc but forces nesting.

[count]\c |NERDComToggleComment|
Toggles the comment state of the selected line(s). If the topmost selected line is commented, all selected lines are uncommented and vice versa.

##Navigator (vim-tmux-navigator)
<ctrl-h> => Left
<ctrl-j> => Down
<ctrl-k> => Up
<ctrl-l> => Right
<ctrl-\> => Previous split
