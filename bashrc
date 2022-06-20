#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

eval "$(starship init bash)"
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash
. "$HOME/.cargo/env"
