# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'


eval "$(starship init bash)"
. "$HOME/.cargo/env"
eval "$(rtx activate bash)"