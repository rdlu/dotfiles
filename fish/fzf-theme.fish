# Single source of truth for the fzf look (tokyonight-night).
# Sourced by BOTH interactive fish (conf.d/fzf.fish) and the tmux popup
# injector (scripts/.../pick-files), so prompt pickers, popups and bare `fzf`
# all share one theme — no drift, set in one place.
#
# Deliberately NO --tmux here: the _pick prompt pickers add `--tmux` themselves
# (float over panes), while pick-files already runs *inside* a tmux popup and
# overrides --height to fill it.
set -gx FZF_DEFAULT_OPTS "--height=60% --layout=reverse --border --marker=* --cycle --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7 --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a --color=border:#565f89"
